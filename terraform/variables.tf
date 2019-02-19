variable "aws_access_key" {}

variable "aws_secret_key" {}

variable "region" {
  default = "ap-southeast-2"
}

variable "account_id" {}

variable "iam_role" {}

variable "key_pair" {
  default = "aws-ghost-cms-key"
}

variable "tags" {
  type = "map"

  default = {
    "service"    = "haomingyin.com"
    "created-by" = "terraform"
    "owner"      = "haoming.yin"
  }
}

variable "cloudflare_ips" {
  type = "list"

  default = [
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "104.16.0.0/12",
    "108.162.192.0/18",
    "131.0.72.0/22",
    "141.101.64.0/18",
    "162.158.0.0/15",
    "172.64.0.0/13",
    "173.245.48.0/20",
    "188.114.96.0/20",
    "190.93.240.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
  ]
}
