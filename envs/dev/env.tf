# Dev environment.
# NOTE: If environment copied, change environment related values (e.g. "dev" -> "perf").

##### Terraform configuration #####

# Usage:
# AWS_PROFILE=default terraform init
# AWS_PROFILE=default terraform get
# AWS_PROFILE=default terraform plan
# AWS_PROFILE=default terraform apply

# NOTE: If you want to create a separate version of this demo, use a unique prefix, e.g. "myname-ecs-demo".
# This way all entities have a different name and also you create a dedicate terraform state file
# (remember to call 'terraform destroy' once you are done with your experimentation).
# So, you have to change the prefix in both local below and terraform configuration section in key.

locals {
  # Ireland
  my_region                 = "eu-west-1"
  # Use unique environment names, e.g. dev, custqa, qa, test, perf, ci, prod...
  my_env                    = "dev"
  # Use consistent prefix, e.g. <cloud-provider>-<demo-target/purpose>-demo, e.g. aws-ecs-demo
  my_prefix                 = "code-pipeline-demo"
  my_suffix					= "my_suffix"
  all_demos_terraform_info  = "blankia-demo"
  # NOTE: Reserve 10.20.*.* address space for this demonstration.
  vpc_cidr_block            = "10.20.0.0/16"
  private_subnet_count      = "2"
  ecs_service_desired_count = 2
  ecr_crm_image_version     = "0.1"
  # See: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
  fargate_container_memory  = "4096"
  fargate_container_cpu     = "1024"
  app_port                  = "80"
  repo_name					= "ecs-fargate-example"
  repo_default_branch       = "master"
  TF_VERSION                = "0.12.18"
}

# NOTE: You cannot use locals in the terraform configuration since terraform
# configuration does not allow interpolation in the configuration section.
terraform {
  required_version = ">=0.12.18"
  backend "s3" {
    # NOTE: We use the same bucket for storing terraform statefiles for all PC demos (but different key).
    bucket     = "terraform-blankia"
    # NOTE: This must be unique for each demo!!!
    # Use the same prefix and dev as in local!
    # I.e. key = "<prefix>/<dev>/terraform.tfstate".
    key        = "aws-code-pipeline-demo/dev/terraform.tfstate"
    region     = "eu-west-1"
    # NOTE: We use the same DynamoDB table for locking all state files of all demos. Do not change name.
    dynamodb_table = "blankia-demos-terraform-backends"
    # NOTE: This is AWS account profile, not env! You probably have two accounts: one dev (or test) and one prod.
    profile    = "default"
  }
}

provider "aws" {
  region     = local.my_region
}

# Here we inject our values to the environment definition module which creates all actual resources.
module "env-def" {
  source                    = "../../modules/env-def"
  prefix                    = "${local.my_prefix}"
  suffix                    = "${local.my_suffix}"
  env                       = "${local.my_env}"
  region                    = "${local.my_region}"
  repo_name					= "${local.repo_name}"
  repo_default_branch       = "${local.repo_default_branch}"
  TF_VERSION                = "${local.TF_VERSION}"
}
