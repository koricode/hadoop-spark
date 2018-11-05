output "master-address" {
  value = "${aws_eip.default.public_ip}"
}