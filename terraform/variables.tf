variable "region" {}

variable "key_pair" {
  default = "aws-shared-key"
}

variable "tags" {
  type = "map"

  default = {
    "service"    = "haomingyin.com"
    "created-by" = "terraform"
    "owner"      = "haoming.yin"
    "repo"       = "terraform.aws-ghost-cms"
  }
}
