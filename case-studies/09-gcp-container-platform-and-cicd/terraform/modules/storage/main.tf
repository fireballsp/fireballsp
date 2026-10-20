resource "google_storage_bucket" "bucket" {
  for_each = var.buckets_map
  name     = each.value.name
  location = each.value.location

  storage_class            = "STANDARD"
  public_access_prevention = "enforced"

  uniform_bucket_level_access = true
}