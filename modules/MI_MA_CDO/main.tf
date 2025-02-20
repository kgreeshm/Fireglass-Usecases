module "service_network" {
  source               = "./modules/network"
  vpc_cidr             = var.service_vpc_cidr
  vpc_name             = var.service_vpc_name
  create_igw           = var.service_create_igw
  mgmt_subnet_cidr     = var.mgmt_subnet_cidr
  ftd_mgmt_ip          = var.ftd_mgmt_ip
  outside_subnet_cidr  = var.outside_subnet_cidr
  ftd_outside_ip       = var.ftd_outside_ip
  diag_subnet_cidr     = var.diag_subnet_cidr
  ftd_diag_ip          = var.ftd_diag_ip
  inside_subnet_cidr   = var.inside_subnet_cidr
  ftd_inside_ip        = var.ftd_inside_ip
  mgmt_subnet_name     = var.mgmt_subnet_name
  outside_subnet_name  = var.outside_subnet_name
  diag_subnet_name     = var.diag_subnet_name
  inside_subnet_name   = var.inside_subnet_name
  outside_interface_sg = var.outside_interface_sg
  inside_interface_sg  = var.inside_interface_sg
  mgmt_interface_sg    = var.mgmt_interface_sg
  use_ftd_eip          = var.use_ftd_eip
  prefix               = var.prefix
}

resource "fmc_access_policies" "fmc_access_policy" {
  depends_on     = [module.service_network]
  name           = "FireGlass-access-policy"
  default_action = "PERMIT"
}

resource "cdo_ftd_device" "ftd" {
  count              = var.availability_zone_count
  name               = "FTD${count.index + 1}"
  licenses           = ["BASE"]
  virtual            = true
  performance_tier   = "FTDv50"
  access_policy_name = fmc_access_policies.fmc_access_policy.name
  depends_on         = [null_resource.clear_cdfmc]
}

resource "null_resource" "clear_cdfmc" {
  triggers = {
    cdo_token  = var.cdo_token
    cdfmc_host = var.cdfmc_host
  }

  provisioner "local-exec" {
    when    = destroy
    command = "python3 ${path.module}/clear_cdfmc.py --token ${self.triggers.cdo_token} --host https://${self.triggers.cdfmc_host}"
  }
}

module "instance" {
  source                  = "./modules/firewall_instance"
  keyname                 = "${var.prefix}-${var.keyname}"
  ftd_version             = var.ftd_version
  ftd_size                = var.ftd_size
  instances_per_az        = var.instances_per_az
  availability_zone_count = var.availability_zone_count
  ftd_mgmt_interface      = module.service_network.mgmt_interface
  ftd_inside_interface    = module.service_network.inside_interface
  ftd_outside_interface   = module.service_network.outside_interface
  ftd_outside2_interface  = aws_network_interface.ftd_public.*.id
  ftd_diag_interface      = module.service_network.diag_interface
  prefix                  = var.prefix
  reg_key                 = cdo_ftd_device.ftd.*.reg_key
  nat_id                  = cdo_ftd_device.ftd.*.nat_id
  fmc_host                = var.cdfmc_host
  ftd_eip                 = module.service_network.aws_ftd_eip
}
resource "cdo_ftd_device_onboarding" "ftd1" {
  ftd_uid    = cdo_ftd_device.ftd[0].id
  depends_on = [module.instance]
}
resource "time_sleep" "wait_10_secs" {
  depends_on      = [cdo_ftd_device_onboarding.ftd1]
  create_duration = "10s"
}
resource "cdo_ftd_device_onboarding" "ftd2" {
  ftd_uid    = cdo_ftd_device.ftd[1].id
  depends_on = [time_sleep.wait_10_secs]
}
#########################################################################################################
# Creation of Network Load Balancer
#########################################################################################################

resource "aws_lb" "external01_lb" {
  name                             = "${var.prefix}-External01-LB"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"
  subnets                          = module.service_network.outside_subnet
}

resource "aws_lb_target_group" "front_end1_1" {
  count       = length(var.listener_ports)
  name        = "${var.prefix}-target-group${count.index}"
  port        = lookup(var.listener_ports[count.index], "port", null)
  protocol    = lookup(var.listener_ports[count.index], "protocol", null)
  target_type = "ip"
  vpc_id      = module.service_network.vpc_id

  health_check {
    interval = 30
    protocol = "TCP"
    port     = 22
  }
}

resource "aws_lb_listener" "listener1_1" {
  load_balancer_arn = aws_lb.external01_lb.arn
  count             = length(var.listener_ports)
  port              = lookup(var.listener_ports[count.index], "port", null)
  protocol          = lookup(var.listener_ports[count.index], "protocol", null)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end1_1[count.index].arn
  }
}

resource "aws_lb_target_group_attachment" "target1_1a" {
  count            = length(var.ftd_outside_ip)
  depends_on       = [aws_lb_target_group.front_end1_1]
  target_group_arn = aws_lb_target_group.front_end1_1[0].arn
  target_id        = var.ftd_outside_ip[count.index]
}

resource "aws_lb_target_group_attachment" "target1_1b" {
  count            = length(var.ftd_outside_ip)
  depends_on       = [aws_lb_target_group.front_end1_1]
  target_group_arn = aws_lb_target_group.front_end1_1[1].arn
  target_id        = var.ftd_outside_ip[count.index]
}

#########################################################################################################
# Creation of Extra Subnet - Outside 2 subnet
#########################################################################################################

data "aws_availability_zones" "available" {}

data "aws_vpc" "fireglass-vpc" {
  depends_on = [module.service_network]
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-FireGlass-VPC"]
  }
}

data "aws_security_group" "sg" {
  depends_on = [module.service_network]
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-Outside-InterfaceSG"]
  }
}

# data "aws_route_table" "route-table"{
#   filter {
#     name   = "tag:Name"
#     values = ["outside network Routing table"]
#   }
# }

variable "public_subnet_cidr" {
  default = ["172.16.5.0/24", "172.16.15.0/24"]
}

variable "ftd_public_ip" {
  default = ["172.16.5.10", "172.16.15.10"]
}

resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = data.aws_vpc.fireglass-vpc.id
  cidr_block        = var.public_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.prefix}-Public-subnet-${count.index + 1}"
  }
}

resource "aws_network_interface" "ftd_public" {
  count             = 2 //length(var.outside_interface) == 0 ? length(var.ftd_outside_ip) : 0
  description       = "asa${count.index}-public"
  subnet_id         = aws_subnet.public_subnet[count.index].id
  source_dest_check = false
  private_ips       = [var.ftd_public_ip[count.index]]
  security_groups   = [data.aws_security_group.sg.id]
}

resource "aws_route_table" "ftd_public_route" {
  count  = 2                             //length(local.outside_subnet)
  vpc_id = data.aws_vpc.fireglass-vpc.id //local.con
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.int_gw.id
  }
  tags = {
    Name = "${var.prefix}-public network Routing table"
  }
}

resource "aws_route_table_association" "public_association" {
  count          = 2
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.ftd_public_route[count.index].id
}

resource "aws_eip" "ftd_public_eip" {
  count = 2 //var.use_ftd_eip ? length(var.mgmt_subnet_name) : 0
  tags = {
    "Name" = "${var.prefix}-fireglass-ftd-${count.index} public IP"
  }
}

resource "aws_eip_association" "ftd_public_ip_assocation" {
  depends_on           = [module.instance, module.service_network]
  count                = length(aws_eip.ftd_public_eip)
  network_interface_id = aws_network_interface.ftd_public[count.index].id
  allocation_id        = aws_eip.ftd_public_eip[count.index].id
}

#########################################################################################################
# Creation of Inside machine
#########################################################################################################

data "aws_subnet" "inside-subnet" {
  depends_on = [module.service_network]
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-inside_subnet-1"]
  }
}

data "aws_security_group" "inside-sg" {
  depends_on = [module.service_network]
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-Inside-InterfaceSG"]
  }
}

resource "aws_network_interface" "ftd_app" {
  #count = length(var.dmz_subnet_cidr) != 0 ? length(var.dmz_subnet_cidr) : 0  ||  length(var.dmz_subnet_name) != 0 ? length(var.dmz_subnet_name) : 0
  # count             = length(var.app_interface) != 0 ? length(var.app_interface) : length(var.ftd_app_ip)
  description       = "app-nic"
  subnet_id         = data.aws_subnet.inside-subnet.id
  source_dest_check = false
  private_ips       = ["172.16.3.30"]
}

resource "aws_network_interface_sg_attachment" "ftd_app_attachment" {
  # count                = //length(var.app_interface) != 0 ? length(var.app_interface) : length(var.ftd_app_ip)
  depends_on           = [aws_network_interface.ftd_app]
  security_group_id    = data.aws_security_group.inside-sg.id
  network_interface_id = aws_network_interface.ftd_app.id
}

resource "aws_instance" "EC2-Ubuntu" {
  depends_on    = [module.service_network, module.instance]
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "${var.prefix}-${var.keyname}" //var.keyname

  # user_data = data.template_file.apache_install.rendered
  network_interface {
    network_interface_id = aws_network_interface.ftd_app.id
    device_index         = 0
  }

  tags = {
    Name = "${var.prefix}-Inside-Machine"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}


#########################################################################################################
# Creation of Bastion subnet and Bastion VM 
#########################################################################################################
data "aws_internet_gateway" "int_gw" {
  depends_on = [module.service_network, module.instance]
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-Internet Gateway"]
  }
}

resource "aws_subnet" "bastion_subnet" {
  vpc_id                  = data.aws_vpc.fireglass-vpc.id
  cidr_block              = "172.16.6.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge({
  Name = "${var.prefix}-bastion-Subnet" })
}

resource "aws_network_interface" "bastion_interface" {
  description = "bastion-interface"
  subnet_id   = aws_subnet.bastion_subnet.id
  private_ips = ["172.16.6.10"]
}

resource "aws_network_interface_sg_attachment" "bastion_attachment" {
  depends_on           = [aws_network_interface.bastion_interface]
  security_group_id    = data.aws_security_group.sg.id //aws_security_group.allow_all.id
  network_interface_id = aws_network_interface.bastion_interface.id
}

resource "aws_route_table" "bastion_route" {
  vpc_id = data.aws_vpc.fireglass-vpc.id
  tags = {
  Name = "${var.prefix}-bastion network Routing table" }
}

resource "aws_route_table_association" "bastion_association" {
  subnet_id      = aws_subnet.bastion_subnet.id
  route_table_id = aws_route_table.bastion_route.id
}

resource "aws_route" "bastion_default_route" {
  route_table_id         = aws_route_table.bastion_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.int_gw.id
}

resource "aws_instance" "testLinux" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = "${var.prefix}-${var.keyname}"
  network_interface {
    network_interface_id = aws_network_interface.bastion_interface.id
    device_index         = 0
  }

  tags = {
    Name = "${var.prefix}-bastion"
  }
}

#######################################################################

resource "time_sleep" "wait_10_sec" {
  depends_on      = [cdo_ftd_device_onboarding.ftd2]
  create_duration = "10s"
}
resource "null_resource" "pbr" {
  depends_on = [time_sleep.wait_10_sec]

  provisioner "local-exec" {
    command     = "terraform init && terraform apply -auto-approve -var='fmc_host=${var.cdfmc_host}' -var='cdo_token=${var.cdo_token}' -var='cdo_host=${local.www_cdo_host}' "
    working_dir = "${path.module}/pbr_configuration"
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "rm terraform.tfstate*"
    working_dir = "${path.module}/pbr_configuration"
  }
}
