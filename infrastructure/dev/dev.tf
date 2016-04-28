provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "stinking-badges-aws"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_key_pair" "auth" {
  key_name   = ""
  public_key = ""
}

resource "aws_instance" "web" {
    ami = "${var.ami_id}"
    instance_type = "t2.micro"

    connection {
      # The default username for our AMI
      user = "ubuntu"
    }

    # The name of our SSH keypair we created above.
    key_name = "${aws_key_pair.auth.id}"

    # Our Security group to allow HTTP and SSH access
    vpc_security_group_ids = ["${aws_security_group.default.id}"]

    subnet_id = "${aws_subnet.default.id}"

    iam_instance_profile = "cd.screwdriver.badges"
}

output "public_dns" {
      value = "${aws_instance.web.public_dns}"
}
