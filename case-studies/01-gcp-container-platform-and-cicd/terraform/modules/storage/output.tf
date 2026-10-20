output "buckets_details" {
  value = {
    for key, bucket in google_storage_bucket.bucket : key => {
      name = bucket.name
      url  = bucket.url
    }
  }
  description = "Map containing the details of all created buckets (key => attributes)."
}