provider "aws" {
    region = "ap-south-1"
    profile = "default"
}



resource "aws_instance" "wordpress" {
  ami           = "ami-0669a96e355eac82f"
  availability_zone = "ap-south-1b"
  instance_type = "t2.micro"
  key_name = "key"
  vpc_security_group_ids = ["${aws_security_group.wordpress_sg.id}"]
  subnet_id = "${aws_subnet.subnet-public.id}"
  associate_public_ip_address = true
  
  
}



resource "aws_instance" "database" {
    ami = "ami-00cb1de6eb870cec2"
    availability_zone = "sa-east-1a"
    instance_type = "t2.micro"
    key_name = "key"
    vpc_security_group_ids = ["${aws_security_group.database_sg.id}"]
    subnet_id = "${aws_subnet.subnet-private.id}"
    
}


resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    
}

resource "aws_internet_gateway" "gateway" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "gateway"
    }
}

resource "aws_subnet" "subnet-public" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = "true" 
    availability_zone = "ap-south-1a"
    tags {
        Name = "subnet-public"
    }
}



resource "aws_route_table" "route_table_public" {
    vpc_id = "${aws_vpc.main-vpc.id}"
    
    route {
        
        cidr_block = "0.0.0.0/0" 
        
        gateway_id = "${aws_internet_gateway.gateway.id}" 
    }
    
    tags {
        Name = "route_table_public" 
    }
}


resource "aws_route_table_association" "route_table_association_public"{
    subnet_id = "${aws_subnet.subnet-public.id}"
    route_table_id = "${aws_route_table.route_table_public.id}"
}


resource "aws_subnet" "subnet-private" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1a"
    tags {
        Name = "subnet-private"
    }
}

resource "aws_route_table" "route_table_private" {
    vpc_id = "${aws_vpc.main-vpc.id}"
    
    route {
        
        cidr_block = "0.0.0.0/0" 
        
        gateway_id = "${aws_internet_gateway.gateway.id}" 
    }
    
    tags {
        Name = "route_table_private" 
    }
}


resource "aws_route_table_association" "route_table_association_public"{
    subnet_id = "${aws_subnet.subnet-private.id}"
    route_table_id = "${aws_route_table.route_table_private.id}"
}


resource "aws_security_group" "wordpress_sg" {
    name = "wordpress_sg"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress { 
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = "10.0.1.0/24"
    }

    vpc_id = "${aws_vpc.vpc.id}"


}


resource "aws_security_group" "database_sg" {
    name = "vpc_db"

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = ["${aws_security_group.wordpress_sg.id}"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = "10.0.0.0/16"
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = "10.0.0.0/16"
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.vpc.id}"

    
}
