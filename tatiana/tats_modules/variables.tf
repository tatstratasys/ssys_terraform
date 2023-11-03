variable "vpc_cidr" {
    description = "CIDR block of the VPC"
    type = string
}

 variable "subnet_count" {
    description = "Number of subnets to create" 
 }
 
variable "instance_type" {
  description = "type of ec2 instance in private subnet"
    default = "t2.micro"
}

variable "aws_route53_record" {
    description = "aws route53 record"
    type = string 
}

variable "aws_route53_zone_name" {
    description = "aws route53 zone name"
    type = string
}

variable "domain_name" {
  description = "domain name"
  type = string
}

variable "bucket_name" {
  description = "name of my s3 bucket"
  type = string
}
  
variable "path" {
    description = "path to the website code folder"
    type = string
}