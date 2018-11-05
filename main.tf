provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags {
    Name = "Hadoop-Spark-VPC"
  }
}

resource "aws_subnet" "default" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "10.1.1.0/24"
  availability_zone = "${var.aws_region_az}"
  map_public_ip_on_launch = true
  tags {
    Name = "Hadoop-Spark-Subnet"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "Hadoop-Spark-IGW"
  }
}

resource "aws_route_table" "default" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "Hadoop-Spark-RT"
  }
}

resource "aws_route_table_association" "default" {
  route_table_id = "${aws_route_table.default.id}"
  subnet_id = "${aws_subnet.default.id}"
}

resource "aws_security_group" "default" {
  name = "Hadoop-Spark-SG"
  description = "Allow inbound traffic to specific ports and free traffic between network"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    cidr_blocks = [
      "${var.my_ip}/32"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
    description = "SSH"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 9870
    to_port = 9870
    protocol = "tcp"
    description = "HDFS Dashboard"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8088
    to_port = 8088
    protocol = "tcp"
    description = "YARN Dashboard"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    description = "Spark Master Dashboard"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 8081
    to_port = 8081
    protocol = "tcp"
    description = "Spark Slave Dashboard"
  }

  ingress {
    cidr_blocks = [
      "10.1.0.0/16"
    ]
    from_port = 0
    to_port = 0
    protocol = "-1"
    description = "LAN"
  }

  egress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 0
    to_port = 0
    protocol = "-1"
    description = "Internet"
  }

  tags {
    Name = "Hadoop-Spark-SG"
  }
}

resource "aws_eip" "default" {
  vpc = true
  tags {
    Name = "Hadoop-Spark-Master-IP"
  }
}

resource "aws_key_pair" "default" {
  key_name = "hadoop-spark-cluster"
  public_key = "${file("keys/aws.pub")}"
}

resource "aws_instance" "master" {
  ami = "ami-013be31976ca2c322"
  instance_type = "t2.small"
  availability_zone = "${var.aws_region_az}"
  key_name = "${aws_key_pair.default.key_name}"
  subnet_id = "${aws_subnet.default.id}"
  vpc_security_group_ids = [
    "${aws_security_group.default.id}"
  ]
  private_ip = "10.1.1.100"
  user_data = "${file("scripts/user-data.sh")}"
  tags {
    Name = "Hadoop-Spark-Master"
  }
}

resource "aws_eip_association" "master" {
  allocation_id = "${aws_eip.default.id}"
  instance_id = "${aws_instance.master.id}"
}

resource "aws_instance" "slave" {
  ami = "ami-013be31976ca2c322"
  instance_type = "t2.small"
  availability_zone = "${var.aws_region_az}"
  key_name = "${aws_key_pair.default.key_name}"
  subnet_id = "${aws_subnet.default.id}"
  vpc_security_group_ids = [
    "${aws_security_group.default.id}"
  ]
  private_ip = "10.1.1.${count.index + 10}"
  user_data = "${file("scripts/user-data.sh")}"
  tags {
    Name = "Hadoop-Spark-Slave-${count.index}"
  }
  count = "${var.slave_count}"
}
