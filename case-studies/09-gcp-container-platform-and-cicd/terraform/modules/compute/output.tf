output "instances_public_ips" {
  value = {
    for name, instance in google_compute_instance.instances :
    name => {
      Public_IP = instance.network_interface[0].access_config[0].nat_ip
    }
  }
}