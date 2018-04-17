data "aws_iam_policy_document" "inat-server" {
  statement {
    actions = [
      "ses:SendEmail",
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ses:FromAddress"

      values = [
        "admin@fieldkit.org",
        "admin@fkdev.org",
      ]
    }
  }
}

resource "aws_iam_role" "inat-server" {
  name = "inat-server"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "inat-server" {
  name = "inat-server"
  role = "${aws_iam_role.inat-server.name}"
}

resource "aws_iam_role_policy" "inat-server" {
  name   = "inat-server"
  role   = "${aws_iam_role.inat-server.id}"
  policy = "${data.aws_iam_policy_document.inat-server.json}"
}
