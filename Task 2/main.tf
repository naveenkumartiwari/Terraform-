provider "aws" {
    region = "ap-south-1"
    profile = "default"
}




resource "aws_instance" "web" {
  ami           = "ami-0447a12f28fddb066"
  availability_zone = "ap-south-1b"
  instance_type = "t2.micro"
  key_name = "key"
  security_groups = [ "launch-wizard-1" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Naveen/Downloads/key.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec"{
     inline = [
              "sudo yum install httpd git -y" ,
              "sudo systemctl restart httpd",
              "sudo systemctl enable httpd",
               "sudo su - root"
                
                "yum install -y amazon-efs-utils"
                "mount -t efs ${efs_id}:/ /var/www/html "

                "sudo git clone https://github.com/vimallinuxworld13/multicloud.git /var/www/html/"
 
        ]
    }

}  


resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true" 
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    
}

resource "aws_subnet" "subnet-1" {
    vpc_id = "${aws_vpc.vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" 
    availability_zone = "ap-south-1a"
    tags {
        Name = "subnet-1"
    }
}

resource "aws_security_group" "my_security_group" {
  name        = "my_security_group"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-eks-demo"
  }
}


resource "aws_efs_file_system" "efs" {
   creation_token = "efs"
   performance_mode = "generalPurpose"
   throughput_mode = "bursting"
   encrypted = "true"
 tags = {
     Name = "efs"
   }
 }

 resource "aws_efs_mount_target" "efs-mount" {
   file_system_id  = "${aws_efs_file_system.efs.id}"
   subnet_id = "${aws_subnet.subnet-1.id}"
   security_groups = ["${aws_security_group.my_security_group.id}"]
 }

output "myos_ip" {
  value = aws_instance.web.public_ip
}

resource "aws_s3_bucket" "bucket" {
  bucket = "my-unique-terraform-bucket"
  acl = "public-read"
  versioning {
    enabled = true
  }

  tags = {
    Name = "my-terraform-bucket"
  }
}  

 resource "aws_s3_bucket_object" "object" {
  bucket = "my-unique-terraform-bucket"
  key    = "download.png"
  source = "download.png"
  
  acl = "public-read"
  depends_on = [
       aws_s3_bucket.bucket

   ]
}

resource "aws_cloudfront_distribution" "Cloudfront" {
    origin {
         domain_name = "${aws_s3_bucket.bucket.bucket_regional_domain_name}"
         origin_id   = "${aws_s3_bucket.bucket.id}"

        custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"] 
        }
    }
       
    enabled = true

    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "${aws_s3_bucket.bucket.id}"

        
        forwarded_values {
            query_string = false
        
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
    
    restrictions {
        geo_restriction {
            
            restriction_type = "none"
        }
    }

    
    viewer_certificate {
        cloudfront_default_certificate = true
    }
    depends_on = [
    aws_s3_bucket.bucket
  ]
 }



