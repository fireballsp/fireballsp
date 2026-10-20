output "postgres_instance_public_ip" {
  value = google_sql_database_instance.postgres_instance_name.public_ip_address
}