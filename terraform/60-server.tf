resource "aws_security_group" "inat-ssh" {
  name        = "inat-ssh"
  description = "inat-ssh"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.whitelisted_cidrs}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "inat-server" {
  name        = "inat-server"
  description = "inat-server"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    cidr_blocks     = "${var.whitelisted_cidrs}"
    security_groups = ["${aws_security_group.inat-alb.id}"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = "${var.whitelisted_cidrs}"
    security_groups = ["${aws_security_group.inat-alb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "inat-alb" {
  name        = "inat-alb"
  description = "inat-alb"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "inat-server" {
  template = "${file("${path.module}/inat-server.yml")}"

  vars {
    hostname             = "inat-server"
    db_username          = "${var.db_username}"
    db_name              = "${var.db_name}"
    db_password          = "${var.db_password}"
    db_address           = "${aws_db_instance.inat-database.address}"
    db_url               = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.inat-database.address}/${var.db_name}?sslmode=disable"
  }
}

data "template_file" "inat-server-compose" {
  template = "${file("${path.module}/inat-compose.yml")}"

  vars {
    hostname             = "inat-server"
    db_username          = "${var.db_username}"
    db_name              = "${var.db_name}"
    db_password          = "${var.db_password}"
    db_address           = "${aws_db_instance.inat-database.address}"
    db_url               = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.inat-database.address}/${var.db_name}?sslmode=disable"
  }
}

data "ct_config" "inat-server" {
  pretty_print = false
  platform     = "ec2"
  content      = "${data.template_file.inat-server.rendered}"
}

resource "aws_instance" "inat-server" {
  ami                         = "ami-a89d3ad2"
  instance_type               = "t2.small"
  subnet_id                   = "${element(var.subnet_ids, 0)}"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.inat-ssh.id}", "${aws_security_group.inat-server.id}"]
  user_data                   = "${data.ct_config.inat-server.rendered}"
  key_name                    = "cfy-dev-server"
  iam_instance_profile        = "${aws_iam_instance_profile.inat-server.id}"
  availability_zone           = "${element(var.azs, count.index)}"

  connection {
    user = "core"
    agent = false
    private_key = "${file("/home/jlewallen/.ssh/cfy.pem")}"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  tags {
    Name = "inat-server-${count.index}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/bin",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.20.0-rc1/docker-compose-Linux-x86_64\" -o /opt/bin/docker-compose",
      "sudo chmod +x /opt/bin/docker-compose",
      "sudo mkdir -p /etc/docker/compose",
      "sudo chown -R core. /etc/docker",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=2048",
      "sudo /sbin/mkswap /var/swap.1",
      "sudo chmod 600 /var/swap.1",
      "sudo /sbin/swapon /var/swap.1",
      "echo '/var/swap.1   swap    swap    defaults        0   0' | sudo tee -a /etc/fstab"
    ]
  }

  provisioner "file" {
    content      = "${data.template_file.inat-server-compose.rendered}"
    destination = "/etc/docker/compose/inat-compose.yml"
  }
}

resource "aws_alb" "inat-server" {
  name            = "inat-server"
  internal        = false
  security_groups = ["${aws_security_group.inat-alb.id}"]
  subnets         = ["${var.subnet_ids}"]

  tags {
    Name = "inat-server"
  }
}

resource "aws_alb_listener" "inat-server-80" {
  load_balancer_arn = "${aws_alb.inat-server.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.inat-server-80.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "inat-server-80" {
  name     = "inat-server-80"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    port                = 80
    path                = "/assets/favicon.ico"
    interval            = 5
  }
}

resource "aws_alb_target_group_attachment" "inat-server-80" {
  target_group_arn = "${aws_alb_target_group.inat-server-80.arn}"
  target_id        = "${aws_instance.inat-server.id}"
  port             = 80
}

resource "aws_alb_listener" "inat-server-4000" {
  load_balancer_arn = "${aws_alb.inat-server.arn}"
  port              = "4000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.inat-server-4000.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "inat-server-4000" {
  name     = "inat-server-4000"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    port                = 80
    path                = "/assets/favicon.ico"
    interval            = 5
  }
}

resource "aws_alb_target_group_attachment" "inat-server-4000" {
  target_group_arn = "${aws_alb_target_group.inat-server-4000.arn}"
  target_id        = "${aws_instance.inat-server.id}"
  port             = 4000
}

resource "aws_security_group" "inat-database" {
  name        = "inat-database"
  description = "inat-database"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${aws_security_group.inat-server.id}"]
  }
}

resource "aws_db_instance" "inat-database" {
  identifier = "inat-database"

  tags {
    Name = "inat-database"
  }

  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "9.6.6"
  instance_class         = "db.t2.micro"
  name                   = "${var.db_name}"
  username               = "${var.db_username}"
  password               = "${var.db_password}"
  publicly_accessible    = true
  db_subnet_group_name   = "fk"
  vpc_security_group_ids = ["${aws_security_group.inat-database.id}"]
}

resource "aws_route53_record" "inat" {
  zone_id = "${var.zone_id}"
  name    = "inat.aws.${var.zone_name}"
  type    = "A"
  ttl     = "60"
  records = ["${aws_instance.inat-server.public_ip}"]
}

output "db_address" {
  value = "${aws_db_instance.inat-database.address}"
}

output "db_url" {
  value = "postgres://${var.db_username}:${var.db_password}@${aws_db_instance.inat-database.address}/${var.db_name}?sslmode=disable"
}

output "db_password" {
  value     = "${var.db_password}"
  sensitive = true
}

output "app_server_public_dns" {
  value     = "${aws_instance.inat-server.public_dns}"
}

output "app_server_public_ip" {
  value     = "${aws_instance.inat-server.public_ip}"
}
