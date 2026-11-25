variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project_name" {
  type    = string
  default = "simulith-asg-min"
}

variable "ami_id" {
  type        = string
  description = "Any ami-* string works on Simulith; use a real id for AWS."
  default     = "ami-simulith-al2023"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "use_simulith_endpoint" {
  type    = bool
  default = true
}

variable "simulith_endpoint" {
  type    = string
  default = "http://127.0.0.1:4566"
}
