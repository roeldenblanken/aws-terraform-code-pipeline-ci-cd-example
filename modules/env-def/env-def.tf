# NOTE: This is the environment definition that will be used by all environments.
# The actual environments (like dev) just inject their environment dependent values
# to this env-def module which defines the actual environment and creates that environment
# by injecting the environment related values to modules.


# NOTE: In demonstration you might want to follow this procedure since there is some dependency
# for the ECR.
# 1. Comment all other modules except ECR.
# 2. Run terraform init and apply. This creates only the ECR.
# 3. Use script 'tag-and-push-to-ecr.sh' to deploy the application Docker image to ECR.
# 3. Uncomment all modules.
# 4. Run terraform init and apply. This creates other resources and also deploys the ECS using the image in ECR.
# NOTE: In real world development we wouldn't need that procedure, of course, since the ECR registry would be created
# at the beginning of the project and the ECR registry would then persist for the development period for that
# environment.


locals {
  my_name  = "${var.prefix}-${var.env}"
  my_env   = "${var.prefix}-${var.env}"
}

data "aws_ssm_parameter" "github_oauth_token" {
  name = "github_oauth_token"
}

# ECS bucket policy needs aws account id.
data "aws_caller_identity" "current" {}


# You can use Resource groups to find resources. See AWS Console => Resource Groups => Saved.
module "resource-groups" {
  source           = "../resource-groups"
  prefix           = var.prefix
  suffix     	   = var.suffix
  env              = var.env
  region           = var.region
}

module "prereqs" {
  source        = "../s3"
  region        = var.region
  name_prefix   = var.prefix
  name_suffix   = var.suffix
  env           = var.env
}

module "code-pipeline" {
  source          = "../code-pipeline"
  region          = var.region
  name_prefix     = var.prefix
  name_suffix     = var.suffix
  env             = var.env
  owner			  = var.owner
  repo_name	      = var.repo_name
  repo_default_branch = var.repo_default_branch 
  github_oauth_token  = data.aws_ssm_parameter.github_oauth_token.value
  TF_VERSION      = var.TF_VERSION
}


