provider "aws" {
    region = "ap-south-1"
    profile = "default"
}


resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    
}


resource "aws_security_group" "database_security_group" {


  name        = "database"
                  
  vpc_id      =  aws_vpc.vpc.id 


  ingress {
    
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  
}


resource "aws_db_instance" "database" {
  allocated_storage = 10
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t2.micro"
  name     = "my_database"
  username = "user"
  password = "password"
  port     = "3306"
  publicly_accessible = true
  iam_database_authentication_enabled = true
  vpc_security_group_ids = aws_security_group.database_security_group.id 
  
}

output "database_url"{

    value = aws_db_instance.database.address 
}


