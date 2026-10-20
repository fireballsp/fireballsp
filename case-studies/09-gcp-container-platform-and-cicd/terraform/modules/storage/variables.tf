variable "buckets_map" {
  type = map(object({
    name     = string
    location = string
  }))
}