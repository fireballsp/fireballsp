resource "google_compute_instance" "instances" {
  for_each = var.instance_map

  name         = each.key
  machine_type = each.value.machine_type
  zone         = "${var.location}-b"

  # Network Tags
  tags = ["cf-tunnel", "allowed-ssh-gcp-console"]

  boot_disk {
    initialize_params {
      architecture = "X86_64"
      image        = "${each.value.image_project}/${each.value.image_family}"
      type         = "pd-balanced"
    }
  }

  network_interface {
    network    = var.vpc_network
    subnetwork = var.subnet_id
    access_config {
      network_tier = "STANDARD"
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  service_account {
    email  = each.value.service_account
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin         = "true"
    block-project-ssh-keys = "true"
    user-data              = lookup(local.user_data_script, each.value.user_data_script, "")
  }
}