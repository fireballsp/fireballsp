resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-ssh-via-gcp-console"
  network = google_compute_network.network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]

  target_tags = ["allowed-ssh-gcp-console"]
}