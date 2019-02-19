resource "aws_db_instance" "main_mysql_db" {
  allocated_storage          = 20
  auto_minor_version_upgrade = true
  backup_retention_period    = 7
  db_subnet_group_name       = "${aws_db_subnet_group.main_db_subnet_group.id}"
  engine                     = "mysql"
  engine_version             = "5.7"
  instance_class             = "db.t2.micro"
  publicly_accessible        = false
  security_group_names       = ["${aws_security_group.db_sg.id}"]
  skip_final_snapshot        = true
  storage_type               = "gp2"

  name     = "mysqldb"
  username = "mysql"
  password = "secret"
  port     = "3306"

  tags = "${merge(map("Name" ,"main_mysql_db"),var.tags)}"
}

resource "aws_db_subnet_group" "main_db_subnet_group" {
  name        = "main_db_subnet_group"
  description = "private database subnet group"
  subnet_ids  = ["${aws_subnet.main_private_subnet}"]

  tags = "${merge(map("Name" ,"main_db_subnet_group"),var.tags)}"
}
