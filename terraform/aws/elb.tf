variable "prefix" {
  type = "string"
}

variable "access_key" {
  type = "string"
}

variable "secret_key" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "elb_subnet_ids" {
  type = "list"
}

variable "logstash_tcp_port" {
  default = 5514
}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

resource "aws_elb" "logstash" {
  name            = "${var.prefix}-logstash"
  subnets         = "${var.elb_subnet_ids}"
  security_groups = ["${aws_security_group.logstash.id}"]

  listener {
    instance_port     = "${var.logstash_tcp_port}"
    instance_protocol = "tcp"
    lb_port           = "${var.logstash_tcp_port}"
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "TCP:${var.logstash_tcp_port}"
    interval            = 5
  }
}

resource "aws_security_group" "logstash" {
  name   = "${var.prefix}-logstash"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.logstash.id}"
}

resource "aws_security_group_rule" "logstash" {
  type        = "ingress"
  from_port   = "${var.logstash_tcp_port}"
  to_port     = "${var.logstash_tcp_port}"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.logstash.id}"
}

output "logstash_lb_name" {
  value = "${aws_elb.logstash.name}"
}

output "logstash_lb_dns_name" {
  value = "${aws_elb.logstash.dns_name}"
}

output "logstash_security_group" {
  value = "${aws_security_group.logstash.id}"
}
