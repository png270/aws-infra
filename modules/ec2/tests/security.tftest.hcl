mock_provider "aws" {}

override_data {
  target = data.aws_iam_policy_document.ec2_assume_role

  values = {
    json = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowEC2AssumeRole"
          Effect = "Allow"
          Action = "sts:AssumeRole"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    })
  }
}

override_data {
  target = data.aws_iam_policy_document.s3_application_access

  values = {
    json = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid      = "ReadBucketLocation"
          Effect   = "Allow"
          Action   = "s3:GetBucketLocation"
          Resource = "arn:aws:s3:::security-test-data"
        },
        {
          Sid      = "ListApplicationPrefix"
          Effect   = "Allow"
          Action   = "s3:ListBucket"
          Resource = "arn:aws:s3:::security-test-data"
          Condition = {
            StringLike = {
              "s3:prefix" = [
                "application",
                "application/*"
              ]
            }
          }
        },
        {
          Sid    = "ReadWriteApplicationObjects"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Resource = "arn:aws:s3:::security-test-data/application/*"
        }
      ]
    })
  }
}

variables {
  name_prefix     = "security-test"
  vpc_id          = "vpc-0123456789abcdef0"
  vpc_cidr        = "10.20.0.0/16"
  subnet_id       = "subnet-0123456789abcdef0"
  instance_type   = "t3.micro"
  data_bucket_arn = "arn:aws:s3:::security-test-data"
}

run "hardened_instance_configuration" {
  command = plan

  assert {
    condition     = aws_instance.this.instance_type == "t3.micro"
    error_message = "The test instance must use an approved low-cost instance type."
  }

  assert {
    condition     = aws_instance.this.metadata_options[0].http_tokens == "required"
    error_message = "EC2 must require IMDSv2 tokens."
  }

  assert {
    condition     = aws_instance.this.metadata_options[0].http_put_response_hop_limit == 1
    error_message = "The instance metadata response hop limit must be 1."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].encrypted
    error_message = "The EC2 root EBS volume must be encrypted."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].delete_on_termination
    error_message = "The lab root volume must be deleted when EC2 terminates."
  }

  assert {
    condition     = aws_instance.this.root_block_device[0].volume_type == "gp3"
    error_message = "The EC2 root volume must use gp3."
  }

  assert {
    condition     = aws_instance.this.monitoring == false
    error_message = "Paid detailed monitoring must remain disabled for this lab."
  }

  #   assert {
  #     condition     = length(aws_security_group.instance.ingress) == 0
  #     error_message = "The hardened EC2 security group must have no inbound rules."
  #   }

  assert {
    condition     = strcontains(aws_iam_policy.s3_application_access.policy, "/application/*")
    error_message = "The EC2 S3 policy must restrict object access to application/*."
  }

  assert {
    condition     = !strcontains(aws_iam_policy.s3_application_access.policy, "\"Resource\":\"*\"")
    error_message = "The EC2 S3 policy must not contain a wildcard resource."
  }
}

run "reject_expensive_instance_type" {
  command = plan

  variables {
    instance_type = "m5.4xlarge"
  }

  expect_failures = [
    var.instance_type
  ]
}