resource "aws_instance" "web_server" {
  ami                         = "${data.aws_ami.ubuntu_ami.id}"        # Ubuntu server v18.04 LTS
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.main_subnet.id}"
  associate_public_ip_address = true
  user_data                   = "${data.local_file.user_data.content}"

  key_name = "${aws_key_pair.main_ssh_key.key_name}"

  vpc_security_group_ids = [
    "${aws_security_group.web_cloudflare_sg.id}",
    "${aws_security_group.ssh_sg.id}",
  ]

  tags = "${merge(map("Name" , "web_server"),var.tags)}"
}

resource "aws_key_pair" "main_ssh_key" {
  key_name   = "${var.key_pair}"
  public_key = "${data.local_file.public_ssh_key.content}"
}
