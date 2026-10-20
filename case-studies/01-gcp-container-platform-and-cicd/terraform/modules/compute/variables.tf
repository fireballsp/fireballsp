variable "location" { type = string }

variable "vpc_network" { type = string }

variable "subnet_id" { type = string }

variable "instance_map" {
  type = map(object({
    machine_type     = string
    image_family     = string
    image_project    = string
    user_data_script = string
    service_account  = string
  }))
}