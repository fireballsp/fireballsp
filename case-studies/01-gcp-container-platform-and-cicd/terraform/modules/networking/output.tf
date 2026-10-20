output "vpc_network" {
  value = google_compute_network.network.name
}

output "subnets_info" {
  value = {
    for region, instance in google_compute_subnetwork.vpc_network_subnet :
    region => {
      name = instance.name
      id   = instance.id
      cidr = instance.ip_cidr_range
    }
  }
}