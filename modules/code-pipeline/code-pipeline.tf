locals {
  my_name  = "${var.name_prefix}-${var.name}-${var.name_suffix}-${var.env}"
  my_deployment   = "${var.name_prefix}-${var.name}-${var.name_suffix}-${var.env}"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "${var.name_prefix}-${var.name}-${var.name_suffix}-${var.env}-code-pipeline-bucket"
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

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.name_prefix}-${var.name}-${var.name_suffix}-${var.env}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codebuild.amazonaws.com",
          "codedeploy.amazonaws.com",
          "codepipeline.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline_attach" {
  role = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_codebuild_project" "codebuild_project" {
  name          = "${var.name_prefix}-${var.name}-${var.name_suffix}-${var.env}-apply-project"
  description   = "${var.env}_codebuild_project"
  build_timeout = "5"
  service_role  = aws_iam_role.codepipeline_role.arn

  artifacts {
    type           = "CODEPIPELINE"
    namespace_type = "BUILD_ID"
    packaging      = "ZIP"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
	# Needed when building docker images
	privileged_mode 			= "true"

    environment_variable {
      name  = "TF_VERSION"
      value = var.TF_VERSION
	  type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.env
	  type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "REGION"
      value = var.region
	  type  = "PLAINTEXT"
    }
	
	environment_variable {
      name  = "github_oauth_token"
      value = var.github_oauth_token
	  type  = "PLAINTEXT"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  tags = {
    Name        = "${local.my_name}-code-pipeline"
    Deployment  = "${local.my_deployment}"
    Prefix      = var.name_prefix
    Environment = var.env
    Region      = var.region
    Terraform   = "true"
  }
}

resource "aws_codepipeline" "codepipeline_infra" {
  count = var.name == "infra" ? 1 : 0
  name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-${var.env}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }
  
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        OAuthToken           = var.github_oauth_token
        Owner                = var.owner
        Repo                 = var.repo_name
        Branch               = var.repo_default_branch
      }
    }
  }
  
  /*
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName = var.repo_name
        BranchName     = var.repo_default_branch
      }
    } 
  }
  */
  
  stage {
    name = "DEV"

    action {
      name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-terraform-plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project.name
		
		EnvironmentVariables = jsonencode([
		{
			name  = "ENVIRONMENT"
			value = "dev"
			type  = "PLAINTEXT"
		  }
		])
      }
    }
	
    action {
      name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
      }
    }
  }
  
  stage {
    name = "TEST"

    action {
      name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-terraform-plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_project.name
		
		EnvironmentVariables = jsonencode([
		{
			name  = "ENVIRONMENT"
			value = "test"
			type  = "PLAINTEXT"
		  }
		])
      }
    }
	
    action {
      name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
      }
    }
  }
  
  stage {
    name = "Post-steps"

    action {
      name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-post-steps"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
      }
    }
  }
}

resource "aws_codepipeline" "codepipeline_app" {
  count = var.name == "app" ? 1 : 0
  name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-${var.env}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        OAuthToken           = var.github_oauth_token
        Owner                = var.owner
        Repo                 = var.repo_name
        Branch               = var.repo_default_branch
      }
    }
  }
  
  stage {
	name = "BuildDockerImage"

	action {
	  name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-terraform-plan"
	  category         = "Build"
	  owner            = "AWS"
	  provider         = "CodeBuild"
	  input_artifacts  = ["source"]
	  version          = "1"

	  configuration = {
		ProjectName = aws_codebuild_project.codebuild_project.name
		
		EnvironmentVariables = jsonencode([
		{
			name  = "ENVIRONMENT"
			value = "dev"
			type  = "PLAINTEXT"
		  }
		])
	  }
	}

	action {
      name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-post-steps"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

	  configuration = {
	  }
	}
  }
  
  stage {
    name = "TriggerTheINFRApipeline"

    action {
      name            = "DeployTheInfraCodepipeline"
      category        = "Invoke"
      owner           = "AWS"
      provider        = "Lambda"
      input_artifacts = ["source"]
      version         = "1"

      configuration = {
        FunctionName   = "notify_k8s_deploy"
        UserParameters = "x"
      }
    }

    action {
      name     = "${var.name_prefix}-${var.name}-${var.name_suffix}-post-steps"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
      }
    }
  }
}