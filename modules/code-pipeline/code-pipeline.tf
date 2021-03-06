locals {
  my_name  = "${var.name_prefix}-${var.type}-${var.env}"
  my_deployment   = "${var.name_prefix}-${var.type}-${var.env}"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.name_prefix}-${var.type}-${var.name_suffix}-${var.env}-role"

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
  name          = "${var.name_prefix}-${var.type}-${var.name_suffix}-${var.env}-apply-project"
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
    privileged_mode             = "true"

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

#######################################
# the codepipeline for the "infra"#
#######################################
resource "aws_codepipeline" "codepipeline_infra" {
  count = var.type == "infra" ? 1 : 0
  name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-${var.env}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.bucket
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
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-terraform-plan"
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
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-Approval"
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
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-terraform-plan"
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
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-Approval"
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
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-post-steps"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
      }
    }
  }
}


#######################################
# the codepipeline for the "ecs-app"#
#######################################
resource "aws_codepipeline" "codepipeline_ecs_app" {
  count 	= var.type == "ecs-app" ? 1 : 0
  name     	= "${var.name_prefix}-${var.type}-${var.name_suffix}-${var.env}-pipeline"
  role_arn 	= aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.bucket
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
	  name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-terraform-plan"
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
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-post-steps"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

	  configuration = {
	  }
	}
  }
  
  stage {
    name = "DeployToECS"

    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["source"]
      version         = "1"

      configuration = {
        ClusterName   = "TOBECHANGEDMANUALLY"
        ServiceName   = "TOBECHANGEDMANUALLY"
      }
    }

    action {
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-post-steps"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
      }
    }
  }
}



#######################################
# the codepipeline for the "k8s-app"#
#######################################
resource "aws_codepipeline" "codepipeline_kubernetes_app" {
  count = var.type == "k8s-app" ? 1 : 0
  name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-${var.env}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = var.bucket
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
	  name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-terraform-plan"
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
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-post-steps"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

	  configuration = {
	  }
	}
  }
  
  stage {
    name = "TriggerTheKubernetesDeployment"

    action {
      name            = "TriggerTheKubernetesDeployment"
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
      name     = "${var.name_prefix}-${var.type}-${var.name_suffix}-post-steps"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
      }
    }
  }
}