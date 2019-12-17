/* Create Bucket for Terraform code pipeline Modules */

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.name_prefix}-${var.env}-bucket"
  acl    = "private"

  /* This bucket MUST have versioning enabled and encryption */
  versioning {
    enabled = true
  }

  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}