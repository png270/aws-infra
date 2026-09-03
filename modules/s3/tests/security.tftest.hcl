mock_provider "aws" {}

override_data {
  target          = data.aws_iam_policy_document.data_bucket
  override_during = plan

  values = {
    json = jsonencode({
      Version = "2012-10-17"

      Statement = [
        {
          Sid       = "DenyInsecureTransport"
          Effect    = "Deny"
          Action    = "s3:*"
          Principal = "*"

          Resource = [
            "arn:aws:s3:::security-test-data",
            "arn:aws:s3:::security-test-data/*"
          ]

          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
        }
      ]
    })
  }
}

run "hardened_bucket_configuration" {
  command = plan

  variables {
    name_prefix = "security-test"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.data.block_public_acls
    error_message = "Public S3 ACLs must be blocked."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.data.block_public_policy
    error_message = "Public S3 bucket policies must be blocked."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.data.ignore_public_acls
    error_message = "Existing public ACLs must be ignored."
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.data.restrict_public_buckets
    error_message = "Public buckets must be restricted."
  }

  assert {
    condition     = aws_s3_bucket_ownership_controls.data.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "S3 ACLs must be disabled with bucket-owner enforcement."
  }

  assert {
    condition = alltrue([
      for rule in aws_s3_bucket_server_side_encryption_configuration.data.rule :
      one(rule.apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    ])

    error_message = "Default S3 encryption must use AES256."
  }

  assert {
    condition     = aws_s3_bucket_versioning.data.versioning_configuration[0].status == "Enabled"
    error_message = "S3 versioning must be enabled."
  }

  #   assert {
  #     condition     = strcontains(data.aws_iam_policy_document.data_bucket.json, "aws:SecureTransport")
  #     error_message = "The bucket policy must enforce TLS."
  #   }
}