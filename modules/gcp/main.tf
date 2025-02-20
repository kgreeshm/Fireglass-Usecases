resource "google_service_account" "sa" {
  account_id   = var.sa_account_id
  display_name = var.sa_display_name
  description  = var.sa_description
}


module "vpc-module" {
  for_each = local.networks
  source   = "terraform-google-modules/network/google"
  version  = "~> 3.0"

  project_id   = var.project_id
  network_name = each.value.name
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "${each.value.name}-subnet-01"
      subnet_ip             = each.value.cidr
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
    },
  ]
}


resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

############################
## management VPC ##
############################
resource "google_compute_firewall" "allow-ssh-mgmt" {
  name    = "allow-ssh-mgmt-${random_string.suffix.result}"
  network = module.vpc-module[var.mgmt_network].network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.sa.email]
}

resource "google_compute_firewall" "allow-https-mgmt" {
  name    = "allow-https-mgmt-${random_string.suffix.result}"
  network = module.vpc-module[var.mgmt_network].network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.sa.email]
}

resource "google_compute_firewall" "allow-tunnel-mgmt" {
  name    = "allow-tunnel-mgmt-${random_string.suffix.result}"
  network = module.vpc-module[var.mgmt_network].network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8305"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.sa.email]
}


############################
## outside VPC ##
############################

resource "google_compute_firewall" "allow-ssh-outside" {
  name    = "allow-tcp-outside-${random_string.suffix.result}"
  network = module.vpc-module[var.outside_network].network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.sa.email]
}

resource "google_compute_firewall" "allow-http-outside" {
  name    = "allow-http-outside-${random_string.suffix.result}"
  network = module.vpc-module[var.outside_network].network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.sa.email]
}

############################
## inside VPC ##
############################

resource "google_compute_firewall" "allow-ssh-inside" {
  name    = "allow-tcp-inside-${random_string.suffix.result}"
  network = module.vpc-module[var.inside_network].network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.sa.email]
}

resource "google_compute_firewall" "allow-http-inside" {
  name    = "allow-http-inside-${random_string.suffix.result}"
  network = module.vpc-module[var.inside_network].network_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.sa.email]
}



#############################################
# Instances
#############################################

resource "google_compute_instance" "ftd" {
  provider                  = google
  count                     = var.num_instances
  project                   = var.project_id
  name                      = "${var.ftd_hostname}-${count.index + 1}-${random_string.suffix.result}"
  zone                      = var.vm_zones[count.index]
  machine_type              = var.vm_machine_type
  can_ip_forward            = true
  allow_stopping_for_update = true
  tags                      = try(var.vm_instance_tags, [])
  labels                    = try(var.vm_instance_labels, {})

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ftd.self_link
    }
  }

  metadata = {
    ssh-keys       = var.admin_ssh_pub_key
    startup-script = data.template_file.startup_script_ftd[count.index].rendered
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.sa.email
    scopes = ["cloud-platform"]
  }

  dynamic "network_interface" {
    for_each = local.networks_list
    content {
      subnetwork = network_interface.value.subnet_self_link
      network_ip = network_interface.value.appliance_ip[count.index]
      dynamic "access_config" { # Needed for getting public IP.
        for_each = network_interface.value.external_ip ? ["external_ip"] : []
        content {
          nat_ip = null
          # nat_ip       = access_config.value.address
          network_tier = "PREMIUM"
        }
      }
    }
  }
}

resource "google_compute_instance" "fmc" {
  count                     = 1
  provider                  = google
  project                   = var.project_id
  name                      = "${var.fmc_hostname}-${count.index + 1}-${random_string.suffix.result}"
  zone                      = var.vm_zones[count.index]
  machine_type              = var.vm_machine_type
  can_ip_forward            = true
  allow_stopping_for_update = true
  tags                      = try(var.vm_instance_tags, [])
  labels                    = try(var.vm_instance_labels, {})
  boot_disk {
    initialize_params {
      image = data.google_compute_image.fmc.self_link
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  metadata = {
    ssh-keys       = var.admin_ssh_pub_key
    startup-script = data.template_file.startup_script_fmc[count.index].rendered
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.sa.email
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork         = local.subnet_self_link_fmc
    subnetwork_project = local.network_project_id
    network_ip         = var.appliance_ips_fmc[count.index]
    access_config {
      nat_ip       = null
      network_tier = "PREMIUM"
    }
  }
}

