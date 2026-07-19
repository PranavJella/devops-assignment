variable "region" {
  description = "AWS Region"
  default     = "ap-south-1"
}

variable "key_name" {
  description = "AWS Key Pair Name"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance Type"
  default     = "t2.micro"
}