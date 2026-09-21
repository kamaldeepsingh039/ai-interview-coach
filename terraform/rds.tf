resource "random_password" "db_password" {
  length  = 20
  special = false
}



resource "aws_db_subnet_group" "icoach_db_subnet_group" {
  name       = "icoach_db_subnet_group"
  subnet_ids = [aws_subnet.data_subnet_a.id, aws_subnet.data_subnet_b.id]

  tags = {
    Name = "icoach-db-subnet-group"

  }

}




resource "aws_db_instance" "icoach_db" {
  identifier        = "icoach-db"
  engine            = "postgres"
  engine_version    = "17.11"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "icoachdb"
  username          = "icoach_admin"
  password          = random_password.db_password.result

  db_subnet_group_name    = aws_db_subnet_group.icoach_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.data_sg.id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  storage_encrypted       = true
  deletion_protection     = false
  multi_az                = true

  tags = {
    Name = "icoach-db"
  }

}

