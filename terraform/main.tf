terraform {
  version = ">= 0.11.11"

  backend "s3" {
    region = "ap-southeast-2"
    bucket = "${var.account_id}-infra"
    key    = "haomingyin.com/terraform/aws-ghost-cms/${var.account_id}/${var.region}/terraform.tfstate"
  }
}
