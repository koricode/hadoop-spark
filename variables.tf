variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_region" {
  default = "us-east-1"
}
variable "aws_region_az" {
  default = "us-east-1a"
}
variable "my_ip" {}
variable "slave_count" {
  default = "10"
}