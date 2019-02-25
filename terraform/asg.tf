module "networks" {
  source = "git::https://github.com/haoming-yin/terraform.aws-networks.git//module"

  region = "${var.region}"
}

resource "aws_launch_template" "web_server_launch_template" {
  description   = "Ghost CMS launch template"
  image_id      = "${data.aws_ami.ubuntu_ami.id}"         # Ubuntu server v18.04 LTS
  instance_type = "t2.micro"
  user_data     = "${base64encode(data.local_file.user_data.content)}"
  key_name      = "${aws_key_pair.main_ssh_key.key_name}"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      volume_size           = 10
      volume_type           = "gp2"
    }
  }

  vpc_security_group_ids = [
    "${module.networks.cloudflare_sg_id}",
    "${module.networks.ssh_sg_id}",
  ]

  tags = "${merge(map("Name" , "web_server_launch_template"),var.tags)}"
}

resource "aws_key_pair" "main_ssh_key" {
  key_name   = "${var.key_pair}"
  public_key = "${data.local_file.public_ssh_key.content}"
}

resource "aws_autoscaling_group" "main_asg" {
  desired_capacity  = 1
  max_size          = 1
  min_size          = 1
  health_check_type = "EC2"

  launch_template {
    id      = "${aws_launch_template.web_server_launch_template.id}"
    version = "$$Latest"
  }

  vpc_zone_identifier = [
    "${module.networks.main_public_subnet_id}"
    ]
}
