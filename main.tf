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

        ]
    }

}     


resource "aws_ebs_volume" "ebs_storage" {
  availability_zone = "ap-south-1b"
  size              = 1
  tags = {
    Name = "ebs_storage"
  }
}   

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/xvdh"
  volume_id   = "${aws_ebs_volume.ebs_storage.id}"
  instance_id = "${aws_instance.web.id}"
  force_detach = true
}

resource "null_resource" "dir_mount"  {

depends_on = [
    aws_volume_attachment.ebs_attach,
  ]


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Naveen/Downloads/key.pem")
    host     = aws_instance.web.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/vimallinuxworld13/multicloud.git /var/www/html/"
    ]
  }
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



