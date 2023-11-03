variable "instance_type" {
  description = "type of ec2 instance"
  type        = string
}

variable "ami" {
  description = "ami ID"
  default     = "ami-03a6eaae9938c858c"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet"
  type        = list(string)
}

variable "public_subnets_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "acm_certificate_arn" {
  description = "arn of the acm certificate"
  type        = string
}

variable "aws_route53_zone_name" {
  description = "aws route53 zone name"
  type        = string
}

variable "aws_route53_record" {
  description = "aws route53 record"
  type        = string
}

variable "path" {
  description = "path to the website code folder"
  type        = string
}