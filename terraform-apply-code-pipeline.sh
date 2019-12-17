#!/bin/bash

#####
# Applies the configuration described in env/dev/env.tf
# Example usage:
# ./terraform-apply-code-pipeline.sh 
# INFRA -> env=dev prefix=code-pipeline-demo suffix=suffix type=infra repo_owner=roeldenblanken repo_name=ecs-fargate-example repo_default_branch=master ./terraform-apply-code-pipeline.sh 
# ECS_APP -> env=dev prefix=code-pipeline-demo suffix=suffix type=ecs-app repo_owner=roeldenblanken repo_name=docker-hello-world repo_default_branch=master ./terraform-apply-code-pipeline.sh 
# KUBERNETES_APP -> env=dev prefix=code-pipeline-demo suffix=suffix type=k8s-app repo_owner=roeldenblanken repo_name=docker-hello-world repo_default_branch=master ./terraform-apply-code-pipeline.sh 
# terraform apply -var my_prefix=code-pipeline-demo -var my_suffix="suffix" -var type=infra -var owner="roeldenblanken" -var repo_name="ecs-fargate-example" -var repo_default_branch="master"
#####

# Check if AWS_ACCESS_KEY_ID is set
if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
	echo -n AWS_ACCESS_KEY_ID: 
	read  AWS_ACCESS_KEY_ID
fi

# Check if AWS_SECRET_ACCESS_KEY is set
if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
	echo -n AWS_SECRET_ACCESS_KEY: 
	read AWS_SECRET_ACCESS_KEY
fi

# Check if env is set
if [ -z "${env}" ]; then
	echo -n environment: 
	read env
fi

# Check if Prefix is set
# Use consistent prefix, e.g. <cloud-provider>-<demo-target/purpose>-demo, e.g. aws-ecs-demo
if [ -z "${prefix}" ]; then
	echo -n prefix: 
	read prefix
fi

# Check if suffix is set
# Use consistent suffix
if [ -z "${suffix}" ]; then
	echo -n suffix: 
	read suffix
fi

# Do you want to deploy a INFRA, ECS_APP, KUBERNETES_APP CI/CD pipeline
if [ -z "${type}" ]; then
	echo -n 'type ("infra", "ecs-app", "k8s-app"):' 
	read type
fi

# Repo_owner of the repository
if [ -z "${repo_owner}" ]; then
	echo -n repo_owner: 
	read repo_owner
fi

# repo_name of the repository
if [ -z "${repo_name}" ]; then
	echo -n repo_name: 
	read repo_name
fi

# repo_default_branch of the repository
if [ -z "${repo_default_branch}" ]; then
	echo -n repo_default_branch: 
	read repo_default_branch
fi

cd "envs/${env}"

# replace the Terraform bucket state type so that the infra, ecs_app and kubernetes_app state are not shared
sed -i "s/.*key.*=.*/key        = \"aws-code-pipeline-demo\/dev\/$type\/terraform.tfstate\"/g" env.tf

# as configured in the env/dev/env.tf file
terraform init -reconfigure
terraform apply -var my_prefix="${prefix}" -var my_suffix="${suffix}" -var type="${type}" -var owner="${repo_owner}" -var repo_name="${repo_name}" -var repo_default_branch="${repo_default_branch}" 

