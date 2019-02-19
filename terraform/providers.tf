provider "aws" {
  version    = "~> 1.57"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"

  assume_role = {
    role_arn = "arn:aws:iam::${var.account_id}:role/${var.iam_role}"
  }
}
