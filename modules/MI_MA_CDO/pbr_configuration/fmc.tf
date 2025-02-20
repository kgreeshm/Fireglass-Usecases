################################################################################################
terraform {
  required_providers {
    fmc = {
      source = "CiscoDevnet/fmc"
    }
  }
}

provider "fmc" {
  is_cdfmc                 = true
  cdo_token                = var.cdo_token
  fmc_host                 = var.fmc_host
  cdfmc_domain_uuid        = "e276abec-e0f2-11e3-8169-6d9ed49b625f"
  fmc_insecure_skip_verify = true
}

# ################################################################################################
# # Data blocks
# ################################################################################################
data "fmc_devices" "device01" {
  name = "FTD1"
}
data "fmc_devices" "device02" {
  name = "FTD2"
}
data "fmc_network_objects" "any-ipv4" {
  name = "any-ipv4"
}
#1st device
data "fmc_device_physical_interfaces" "zero_physical_interface_device01" {
  device_id = data.fmc_devices.device01.id
  name      = "TenGigabitEthernet0/0"
}
data "fmc_device_physical_interfaces" "one_physical_interface_device01" {
  device_id = data.fmc_devices.device01.id
  name      = "TenGigabitEthernet0/1"
}
data "fmc_device_physical_interfaces" "two_physical_interface_device01" {
  device_id = data.fmc_devices.device01.id
  name      = "TenGigabitEthernet0/2"
}
#2nd device
data "fmc_device_physical_interfaces" "zero_physical_interface_device02" {
  device_id = data.fmc_devices.device02.id
  name      = "TenGigabitEthernet0/0"
}
data "fmc_device_physical_interfaces" "one_physical_interface_device02" {
  device_id = data.fmc_devices.device02.id
  name      = "TenGigabitEthernet0/1"
}
data "fmc_device_physical_interfaces" "two_physical_interface_device02" {
  device_id = data.fmc_devices.device02.id
  name      = "TenGigabitEthernet0/2"
}
################################################################################################
# Security Zones
################################################################################################
resource "fmc_security_zone" "inside" {
  name           = "InZone"
  interface_mode = "ROUTED"
}
resource "fmc_security_zone" "outside01" {
  name           = "OutZone01"
  interface_mode = "ROUTED"
}
resource "fmc_security_zone" "outside02" {
  name           = "OutZone02"
  interface_mode = "ROUTED"
}

################################################################################################
# Network & Host Object
################################################################################################
resource "fmc_network_objects" "corporate-lan01" {
  name  = "Inside-subnet-01"
  value = "172.16.3.0/24"
}

resource "fmc_network_objects" "corporate-lan02" {
  name  = "Inside-subnet-02"
  value = "172.16.13.0/24"
}

resource "fmc_network_objects" "outside-subnet-01" {
  name  = "Outside-subnet-01"
  value = "172.16.2.0/24"
}

resource "fmc_network_objects" "outside-subnet-02" {
  name  = "Outside-subnet-02"
  value = "172.16.12.0/24"
}

resource "fmc_network_objects" "Public-subnet-01" {
  name  = "Public-subnet-01"
  value = "172.16.5.0/24"
}

resource "fmc_network_objects" "Public-subnet-02" {
  name  = "Public-subnet-02"
  value = "172.16.15.0/24"
}

resource "fmc_host_objects" "outside01-gw" {
  name  = "Outside01-GW"
  value = "172.16.2.1"
}
resource "fmc_host_objects" "outside02-gw" {
  name  = "Outside02-GW"
  value = "172.16.5.1"
}
################################################################################################
# Access Policy
################################################################################################
data "fmc_access_policies" "access_policy" {
  name = "FireGlass-access-policy"
}

resource "fmc_access_rules" "access_rule" {
  acp                = data.fmc_access_policies.access_policy.id
  section            = "mandatory"
  name               = "allow-in-out"
  action             = "allow"
  enabled            = true
  send_events_to_fmc = true
  log_end            = true
  source_zones {
    source_zone {
      id   = fmc_security_zone.inside.id
      type = "SecurityZone"
    }
  }
  destination_zones {
    destination_zone {
      id   = fmc_security_zone.outside01.id
      type = "SecurityZone"
    }
    destination_zone {
      id   = fmc_security_zone.outside02.id
      type = "SecurityZone"
    }
  }
  new_comments = ["Applied via terraform"]
}
################################################################################################
# Nat Policy
################################################################################################
resource "fmc_ftd_nat_policies" "nat_policy01" {
  name        = "NAT_Policy01"
  description = "Nat policy by terraform"
}

resource "fmc_ftd_nat_policies" "nat_policy02" {
  name        = "NAT_Policy02"
  description = "Nat policy by terraform"
}

resource "fmc_ftd_manualnat_rules" "nat_rule01" {
  nat_policy  = fmc_ftd_nat_policies.nat_policy01.id
  description = "Created using terraform"
  nat_type    = "static"
  source_interface {
    id   = fmc_security_zone.inside.id
    type = "SecurityZone" //fmc_security_zone.inside.type
  }
  destination_interface {
    id   = fmc_security_zone.outside01.id
    type = "SecurityZone" //fmc_security_zone.outside01.type
  }
  original_source {
    id   = fmc_network_objects.corporate-lan01.id
    type = fmc_network_objects.corporate-lan01.type
  }
  # translated_network {
  #     id = data.fmc_network_objects.public.id
  #     type = data.fmc_network_objects.public.type
  # }
  interface_in_translated_source = true
  # original_port {
  #     port = 53
  #     protocol = "udp"
  # }
  # translated_port = 5353
  # ipv6 = true
}

resource "fmc_ftd_manualnat_rules" "nat_rule11" {
  nat_policy  = fmc_ftd_nat_policies.nat_policy01.id
  description = "Created using terraform"
  nat_type    = "static"
  source_interface {
    id   = fmc_security_zone.inside.id
    type = "SecurityZone" //fmc_security_zone.inside.type
  }
  destination_interface {
    id   = fmc_security_zone.outside02.id
    type = "SecurityZone" //fmc_security_zone.outside01.type
  }
  original_source {
    id   = fmc_network_objects.corporate-lan01.id
    type = fmc_network_objects.corporate-lan01.type
  }
  # translated_network {
  #     id = data.fmc_network_objects.public.id
  #     type = data.fmc_network_objects.public.type
  # }
  interface_in_translated_source = true
  # original_port {
  #     port = 53
  #     protocol = "udp"
  # }
  # translated_port = 5353
  # ipv6 = true
}

resource "fmc_ftd_manualnat_rules" "nat_rule02" {
  nat_policy  = fmc_ftd_nat_policies.nat_policy02.id
  description = "Created using terraform"
  nat_type    = "static"
  source_interface {
    id   = fmc_security_zone.inside.id
    type = "SecurityZone" //fmc_security_zone.inside.type
  }
  destination_interface {
    id   = fmc_security_zone.outside02.id
    type = "SecurityZone" //fmc_security_zone.outside02.type
  }
  original_source {
    id   = fmc_network_objects.corporate-lan02.id
    type = fmc_network_objects.corporate-lan02.type
  }
  # translated_network {
  #     id = data.fmc_network_objects.public.id
  #     type = data.fmc_network_objects.public.type
  # }
  interface_in_translated_source = true
  # original_port {
  #     port = 53
  #     protocol = "udp"
  # }
  # translated_port = 5353
  # ipv6 = true
}

################################################################################################
# Configuring physical interfaces
################################################################################################
#1st Device
resource "fmc_device_physical_interfaces" "physical_interfaces00" {
  enabled                = true
  device_id              = data.fmc_devices.device01.id
  physical_interface_id  = data.fmc_device_physical_interfaces.zero_physical_interface_device01.id
  name                   = data.fmc_device_physical_interfaces.zero_physical_interface_device01.name
  security_zone_id       = fmc_security_zone.outside01.id
  if_name                = "outside01"
  description            = "Applied by terraform"
  mtu                    = 1500
  mode                   = "NONE"
  ipv4_dhcp_enabled      = "true"
  ipv4_dhcp_route_metric = 1
}
resource "fmc_device_physical_interfaces" "physical_interfaces01" {
  device_id              = data.fmc_devices.device01.id
  physical_interface_id  = data.fmc_device_physical_interfaces.one_physical_interface_device01.id
  name                   = data.fmc_device_physical_interfaces.one_physical_interface_device01.name
  security_zone_id       = fmc_security_zone.outside02.id
  if_name                = "outside02"
  description            = "Applied by terraform"
  mtu                    = 1500
  mode                   = "NONE"
  ipv4_dhcp_enabled      = "true"
  ipv4_dhcp_route_metric = 1
}

resource "fmc_device_physical_interfaces" "physical_interfaces02" {
  device_id              = data.fmc_devices.device01.id
  physical_interface_id  = data.fmc_device_physical_interfaces.two_physical_interface_device01.id
  name                   = data.fmc_device_physical_interfaces.two_physical_interface_device01.name
  security_zone_id       = fmc_security_zone.inside.id
  if_name                = "inside"
  description            = "Applied by terraform"
  mtu                    = 1500
  mode                   = "NONE"
  ipv4_dhcp_enabled      = "true"
  ipv4_dhcp_route_metric = 1
}
#2nd Device
resource "fmc_device_physical_interfaces" "physical_interfaces10" {
  enabled                = true
  device_id              = data.fmc_devices.device02.id
  physical_interface_id  = data.fmc_device_physical_interfaces.zero_physical_interface_device02.id
  name                   = data.fmc_device_physical_interfaces.zero_physical_interface_device02.name
  security_zone_id       = fmc_security_zone.outside01.id
  if_name                = "outside01"
  description            = "Applied by terraform"
  mtu                    = 1500
  mode                   = "NONE"
  ipv4_dhcp_enabled      = "true"
  ipv4_dhcp_route_metric = 1
}

resource "fmc_device_physical_interfaces" "physical_interfaces11" {
  enabled                = true
  device_id              = data.fmc_devices.device02.id
  physical_interface_id  = data.fmc_device_physical_interfaces.one_physical_interface_device02.id
  name                   = data.fmc_device_physical_interfaces.one_physical_interface_device02.name
  security_zone_id       = fmc_security_zone.outside02.id
  if_name                = "outside02"
  description            = "Applied by terraform"
  mtu                    = 1500
  mode                   = "NONE"
  ipv4_dhcp_enabled      = "true"
  ipv4_dhcp_route_metric = 1
}

resource "fmc_device_physical_interfaces" "physical_interfaces12" {
  enabled                = true
  device_id              = data.fmc_devices.device02.id
  physical_interface_id  = data.fmc_device_physical_interfaces.two_physical_interface_device02.id
  name                   = data.fmc_device_physical_interfaces.two_physical_interface_device02.name
  security_zone_id       = fmc_security_zone.inside.id
  if_name                = "inside"
  description            = "Applied by terraform"
  mtu                    = 1500
  mode                   = "NONE"
  ipv4_dhcp_enabled      = "true"
  ipv4_dhcp_route_metric = 1
}
################################################################################################
# Adding static route
################################################################################################
resource "fmc_staticIPv4_route" "route01" {
  depends_on     = [data.fmc_devices.device01, fmc_device_physical_interfaces.physical_interfaces00, fmc_device_physical_interfaces.physical_interfaces01, fmc_device_physical_interfaces.physical_interfaces02]
  metric_value   = 25
  device_id      = data.fmc_devices.device01.id
  interface_name = "outside01"
  selected_networks {
    id   = data.fmc_network_objects.any-ipv4.id
    type = data.fmc_network_objects.any-ipv4.type
    name = data.fmc_network_objects.any-ipv4.name
  }
  gateway {
    object {
      id   = fmc_host_objects.outside01-gw.id
      type = fmc_host_objects.outside01-gw.type
      name = fmc_host_objects.outside01-gw.name
    }
  }
}

resource "fmc_staticIPv4_route" "route11" {
  depends_on     = [data.fmc_devices.device01, fmc_device_physical_interfaces.physical_interfaces00, fmc_device_physical_interfaces.physical_interfaces01, fmc_device_physical_interfaces.physical_interfaces02]
  metric_value   = 30
  device_id      = data.fmc_devices.device01.id
  interface_name = "outside02"
  selected_networks {
    id   = data.fmc_network_objects.any-ipv4.id
    type = data.fmc_network_objects.any-ipv4.type
    name = data.fmc_network_objects.any-ipv4.name
  }
  gateway {
    object {
      id   = fmc_host_objects.outside02-gw.id
      type = fmc_host_objects.outside02-gw.type
      name = fmc_host_objects.outside02-gw.name
    }
  }
}

//2nd device route 
resource "fmc_staticIPv4_route" "route02" {
  depends_on     = [data.fmc_devices.device02, fmc_device_physical_interfaces.physical_interfaces10, fmc_device_physical_interfaces.physical_interfaces11, fmc_device_physical_interfaces.physical_interfaces12]
  metric_value   = 25
  device_id      = data.fmc_devices.device02.id
  interface_name = "outside01"
  selected_networks {
    id   = data.fmc_network_objects.any-ipv4.id
    type = data.fmc_network_objects.any-ipv4.type
    name = data.fmc_network_objects.any-ipv4.name
  }
  gateway {
    object {
      id   = fmc_host_objects.outside02-gw.id
      type = fmc_host_objects.outside02-gw.type
      name = fmc_host_objects.outside02-gw.name
    }
  }
}

################################################################################################
# Attaching NAT Policy to device
################################################################################################
resource "fmc_policy_devices_assignments" "policy_assignment01" {
  depends_on = [fmc_staticIPv4_route.route01]
  policy {
    id   = fmc_ftd_nat_policies.nat_policy01.id
    type = fmc_ftd_nat_policies.nat_policy01.type
  }
  target_devices {
    id   = data.fmc_devices.device01.id
    type = data.fmc_devices.device01.type
  }
}

resource "fmc_policy_devices_assignments" "policy_assignment02" {
  depends_on = [fmc_staticIPv4_route.route02]
  policy {
    id   = fmc_ftd_nat_policies.nat_policy02.id
    type = fmc_ftd_nat_policies.nat_policy02.type
  }
  target_devices {
    id   = data.fmc_devices.device02.id
    type = data.fmc_devices.device02.type
  }
}

resource "null_resource" "run_python_script" {
  provisioner "local-exec" {
    command = "python3 ${path.module}/fmc.py --host ${var.fmc_host} --token ${var.cdo_token}"
  }

  depends_on = [fmc_policy_devices_assignments.policy_assignment01, fmc_policy_devices_assignments.policy_assignment02]
}



################################################################################################
# Deploying the changes to the device
################################################################################################
resource "fmc_ftd_deploy" "ftd01" {
  depends_on     = [fmc_policy_devices_assignments.policy_assignment01, null_resource.run_python_script]
  device         = data.fmc_devices.device01.id
  ignore_warning = true
  force_deploy   = false
}

resource "fmc_ftd_deploy" "ftd02" {
  depends_on     = [fmc_policy_devices_assignments.policy_assignment02, null_resource.run_python_script]
  device         = data.fmc_devices.device02.id
  ignore_warning = true
  force_deploy   = false
}
