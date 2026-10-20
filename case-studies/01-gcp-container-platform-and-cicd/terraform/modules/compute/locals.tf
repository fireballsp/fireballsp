locals {
  user_data_script = {
    "none"        = ""
    "cloudflared" = file("${path.module}/scripts/cloudflared.sh")
  }
}