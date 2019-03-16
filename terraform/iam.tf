resource "aws_iam_role" "web_server_role" {
  name               = "web-server-role"
  assume_role_policy = "${data.aws_iam_policy_document.web_server_trust_policy.json}"
}

resource "aws_iam_role_policy_attachment" "web_server_policy_attachment" {
  policy_arn = "${aws_iam_role_policy.web_server_role_policy.arn}"
  role       = "${aws_iam_role.web_server_role.id}"
}

resource "aws_iam_role_policy" "web_server_role_policy" {
  name   = "web-server-role-policy"
  policy = "${data.aws_iam_policy_document.web_server_policy.json}"
}

data "aws_iam_policy_document" "web_server_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "web_server_policy" {
  statement {
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
      "kms:decrypt",
      "kms:DescribeKey",
      "kms:encrypt",
      "rds:DescribeDBInstances",
      "rds:ListTagsForResource",
    ]

    effect = "Allow"

    resource = ["*"]
  }
}
