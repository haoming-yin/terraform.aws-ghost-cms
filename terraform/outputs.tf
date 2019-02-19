output "web_server_ip" {
  description = "The public IP of created EC2 instance"
  value       = "${aws_instance.web_server.public_ip}"
}

output "key_pair_name" {
  description = "The name of the key pair that can be used to access the EC2 instance."
  value       = "${aws_key_pair.main_ssh_key.key_name}"
}

output "db_endpoint" {
  description = "The endpoint of created RDS"
  value       = "${aws_db_instance.main_mysql_db.endpoint}"
}
