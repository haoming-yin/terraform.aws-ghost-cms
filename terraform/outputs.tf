output "key_pair_name" {
  description = "The name of the key pair that can be used to access the EC2 instance."
  value       = "${aws_key_pair.main_ssh_key.key_name}"
}
