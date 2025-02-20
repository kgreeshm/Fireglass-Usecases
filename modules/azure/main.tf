################################################################################################################################
# Resource Group Creation
################################################################################################################################

resource "azurerm_resource_group" "ftdv" {
  count    = var.create_rg ? 1 : 0
  name     = var.rg_name
  location = var.location
}

#########################################################################################################################
# Virtual Network and Subnet Creation
#########################################################################################################################

resource "azurerm_virtual_network" "ftdv" {
  count               = var.vn_name == "" ? 1 : 0
  name                = "${var.prefix}-network"
  location            = var.location
  resource_group_name = local.rg_name
  address_space       = [var.vn_cidr]
}

resource "azurerm_subnet" "subnets" {
  for_each             = local.subnet_list
  name                 = "${var.prefix}-${each.key}"
  resource_group_name  = local.rg_name
  virtual_network_name = local.vn_name
  address_prefixes     = var.subnets == [] ? [cidrsubnet(local.vn_cidr, local.subnet_newbits, each.value + 2)] : [var.subnets[each.value]]
}
################################################################################################################################
# SSH Keypair
################################################################################################################################

resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content       = tls_private_key.key_pair.private_key_openssh
  filename      = "private-key"
  file_permission = 0700
}

################################################################################################################################
# Route Table Creation and Route Table Association
################################################################################################################################

resource "azurerm_route_table" "ftdv_rt" {
  for_each            = local.subnet_list
  name                = "${var.prefix}-rt-${each.key}"
  location            = var.location
  resource_group_name = local.rg_name
}

resource "azurerm_subnet_route_table_association" "ftdv_rta" {
  for_each       = local.subnet_list
  depends_on     = [azurerm_route_table.ftdv_rt, azurerm_subnet.subnets]
  subnet_id      = azurerm_subnet.subnets[each.key].id
  route_table_id = azurerm_route_table.ftdv_rt[each.key].id
}

################################################################################################################################
# Network Security Group Creation
################################################################################################################################

resource "azurerm_network_security_group" "allow-all" {
  name                = "${var.prefix}-allow-all"
  location            = var.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "TCP-Allow-All"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Outbound-Allow-All"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.source_address
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "ilb-allow-all" {
  name                = "${var.prefix}-ilb-allow-all"
  location            = var.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "TCP-Allow-All-Internal-Inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "TCP-Allow-All-Internal-Outbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "elb-allow-all" {
  name                = "${var.prefix}-elb-allow-all"
  location            = var.location
  resource_group_name = local.rg_name

  security_rule {
    name                       = "TCP-Allow-All-External-Inbound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "TCP-Allow-All-External-Outbound"
    priority                   = 1001
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


################################################################################################################################
# Network Interface Creation, Public IP Creation and Network Security Group Association
################################################################################################################################

resource "azurerm_public_ip" "ftdv-mgmt-interface" {
  name                = "${var.prefix}-instance-mgmt-public-ip%{if var.instances > 1}-${count.index}%{endif}"
  count               = var.instances
  location            = var.location
  sku                 = var.instances > 1 ? "Standard" : "Basic"
  resource_group_name = local.rg_name
  allocation_method   = var.instances > 1 ? "Static" : "Dynamic"
}

resource "azurerm_public_ip" "ftdv-outside-interface" {
  name                = "${var.prefix}-instance-outside-public-ip%{if var.instances > 1}-${count.index}%{endif}"
  count               = var.instances
  location            = var.location
  sku                 = var.instances > 1 ? "Standard" : "Basic"
  resource_group_name = local.rg_name
  allocation_method   = var.instances > 1 ? "Static" : "Dynamic"
}

resource "azurerm_public_ip" "fmc-mgmt-interface" {
  name                = "fmc-public-ip"
  count               = var.create_fmc == true ? 1 : 0
  location            = var.location
  sku                 = var.instances > 1 ? "Standard" : "Basic"
  resource_group_name = local.rg_name
  allocation_method   = var.instances > 1 ? "Static" : "Dynamic"
}

resource "azurerm_network_interface" "ftdv-mgmt" {
  depends_on          = [azurerm_subnet.subnets]
  name                = "${var.prefix}-management%{if var.instances > 1}-${count.index}%{endif}"
  count               = var.instances
  location            = var.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "management%{if var.instances > 1}-${count.index}%{endif}"
    subnet_id                     = azurerm_subnet.subnets["management"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.ftd_mgmt_ip[count.index]
    public_ip_address_id          = azurerm_public_ip.ftdv-mgmt-interface[count.index].id
  }
}


resource "azurerm_network_interface_security_group_association" "FTDv_MGMT_NSG" {
  count                     = var.instances
  network_interface_id      = azurerm_network_interface.ftdv-mgmt[count.index].id
  network_security_group_id = azurerm_network_security_group.allow-all.id
}

resource "azurerm_network_interface" "ftdv-diagnostic" {
  depends_on          = [azurerm_subnet.subnets]
  name                = "${var.prefix}-diagnostic%{if var.instances > 1}-${count.index}%{endif}"
  count               = var.instances
  location            = var.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "Diagnostic%{if var.instances > 1}-${count.index}%{endif}"
    subnet_id                     = azurerm_subnet.subnets["diagnostic"].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "FTDv_DIAG_NSG" {
  count                     = var.instances
  network_interface_id      = azurerm_network_interface.ftdv-diagnostic[count.index].id
  network_security_group_id = azurerm_network_security_group.allow-all.id
}

resource "azurerm_network_interface" "ftdv-outside" {
  depends_on          = [azurerm_subnet.subnets]
  name                = "${var.prefix}-outside%{if var.instances > 1}-${count.index}%{endif}"
  count               = var.instances
  location            = var.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "Outside%{if var.instances > 1}-${count.index}%{endif}"
    subnet_id                     = azurerm_subnet.subnets["outside"].id
    private_ip_address_allocation = "Dynamic"
    # private_ip_address_allocation = "Static"
    # private_ip_address            = var.ftd_mgmt_ip[count.index]
    public_ip_address_id          = azurerm_public_ip.ftdv-outside-interface[count.index].id
  }
}

resource "azurerm_network_interface_security_group_association" "FTDv_Outside_NSG" {
  count                     = var.instances
  network_interface_id      = azurerm_network_interface.ftdv-outside[count.index].id
  network_security_group_id = azurerm_network_security_group.elb-allow-all.id
}

#fmc
resource "azurerm_network_interface" "fmc-mgmt" {
  depends_on          = [azurerm_subnet.subnets]
  name                = "fmc-mgmt-nic"
  count               = var.create_fmc == true ? 1 : 0
  location            = var.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "fmc-mgmt-nic"
    subnet_id                     = azurerm_subnet.subnets["management"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.18"
    public_ip_address_id          = azurerm_public_ip.fmc-mgmt-interface[count.index].id
  }
}
resource "azurerm_network_interface_security_group_association" "fmc-mgmt-association" {
  count               = var.create_fmc == true ? 1 : 0
  network_interface_id      = azurerm_network_interface.fmc-mgmt[count.index].id
  network_security_group_id = azurerm_network_security_group.elb-allow-all.id
}


resource "azurerm_network_interface" "ftdv-inside" {
  depends_on          = [azurerm_subnet.subnets]
  name                = "${var.prefix}-inside%{if var.instances > 1}-${count.index}%{endif}"
  count               = var.instances
  location            = var.location
  resource_group_name = local.rg_name

  ip_configuration {
    name                          = "Inside%{if var.instances > 1}-${count.index}%{endif}"
    subnet_id                     = azurerm_subnet.subnets["inside"].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "FTDv_Inside_NSG" {
  count                     = var.instances
  network_interface_id      = azurerm_network_interface.ftdv-inside[count.index].id
  network_security_group_id = azurerm_network_security_group.ilb-allow-all.id
}
/////////////////////////



resource "azurerm_virtual_machine" "ftdv-instance" {
  name                = "${var.prefix}-vm%{if var.instances > 1}-${count.index}%{endif}"
  count               = var.instances
  location            = var.location
  resource_group_name = var.rg_name

  primary_network_interface_id = element(azurerm_network_interface.ftdv-mgmt.*.id,count.index)
  network_interface_ids = [
    element(azurerm_network_interface.ftdv-mgmt.*.id,count.index),
    element(azurerm_network_interface.ftdv-diagnostic.*.id,count.index),
    element(azurerm_network_interface.ftdv-outside.*.id,count.index),
    element(azurerm_network_interface.ftdv-inside.*.id,count.index)
  ]
  vm_size = var.vm_size

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  plan {
    name      = "ftdv-azure-byol"
    publisher = "cisco"
    product   = "cisco-ftdv"
  }

  storage_image_reference {
    publisher = "cisco"
    offer     = "cisco-ftdv"
    sku       = "ftdv-azure-byol"
    version   = var.ftd_image_version
  }
  storage_os_disk {
    name              = "${var.prefix}-myosdisk%{if var.instances > 1}-${count.index}%{endif}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.instancename}%{if var.instances > 1}${count.index}%{endif}"
    admin_username = var.username
    admin_password = var.ftd_password
    custom_data = templatefile(
      "${path.module}/templates/ftd_startup_file.txt", {
        ftd_password = var.ftd_password,
        fmc_ip = var.fmc_ip,
        reg_key = var.reg_key,
        fmc_nat_id = var.fmc_nat_id
      }
    )
  }
  os_profile_linux_config {
    disable_password_authentication = false    
    ssh_keys {
      key_data = tls_private_key.key_pair.public_key_openssh
      path = "/home/cisco/.ssh/authorized_keys"
    }
  }
  zones = var.instances == 1 ? [] : [local.az_distribution[count.index]]
}

resource "azurerm_linux_virtual_machine" "fmcv" {
  name                  = "FMC-01"
  count                 = var.create_fmc == true ? 1:0
  location              = var.location
  resource_group_name   = var.rg_name
  network_interface_ids = [element(azurerm_network_interface.fmc-mgmt[*].id,count.index)]
  size                  = "Standard_D4_v2"
  disable_password_authentication = false

  os_disk {
    name                 = "FMC-Disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  plan {
    name      = "fmcv-azure-byol"
    product   = "cisco-fmcv"
    publisher = "cisco"
  }

  source_image_reference {
    publisher = "cisco"
    offer     = "cisco-fmcv"
    sku       = "fmcv-azure-byol"
    version   = var.fmc_image_version
  }

  computer_name  = "FMC"
  admin_username = var.username
  admin_password = var.fmc_password
  custom_data = base64encode(templatefile(
    "${path.module}/templates/fmc_startup_file.txt", {
      fmc_password = var.fmc_password,
      fmc_hostname = "FMC01"
    }
  )) 
}