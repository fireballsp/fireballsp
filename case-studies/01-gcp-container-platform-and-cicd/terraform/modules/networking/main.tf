resource "google_compute_network" "network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false

  routing_mode = "GLOBAL"
}

resource "google_compute_subnetwork" "vpc_network_subnet" {
  for_each      = var.vpc_subnet_values
  name          = "${var.vpc_name}-subnet-${each.key}"
  ip_cidr_range = each.value
  region        = each.key
  network       = google_compute_network.network.id

  log_config {
    aggregation_interval = "INTERVAL_15_MIN"
    flow_sampling        = 0.1
    metadata             = "EXCLUDE_ALL_METADATA"
  }
}