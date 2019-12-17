#!/bin/bash

#####
# Applies the configuration described in env/dev/dev.tf
# Example usage:
# ./terraform-apply-code-pipeline.sh 
# env=dev prefix=code-pipeline-demo source=infra repo_owner=roeldenblanken repo_name=ecs-fargate-example repo_default_branch=master ./terraform-apply-code-pipeline.sh 
# env=dev prefix=code-pipeline-demo source=app repo_owner=roeldenblanken repo_name=docker-hello-world repo_default_branch=master ./terraform-apply-code-pipeline.sh 
# terraform apply -var my_suffix="infra" -var owner="roeldenblanken" -var repo_name="ecs-fargate-example" -var repo_default_branch="master"
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

# Are you pointing to the infra or application source repository
if [ -z "${source}" ]; then
	echo -n source: 
	read source
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

# replace the Terraform bucket state source prefix so that the infra and app state are not shared
sed -i "s/.*key.*=.*/key        = \"aws-code-pipeline-demo\/dev\/$source\/terraform.tfstate\"/g" env.tf
# replace the Terraform suffix so that the infra and app resoures are not shared
sed -i "s/my_suffix.*=.*\".*\".*/my_suffix        = \"$source\"/g" env.tf

# as configured in the env/dev/env.tf file
terraform init -reconfigure
terraform apply -var my_prefix="${prefix}" -var my_suffix="${source}" -var owner="${repo_owner}" -var repo_name="${repo_name}" -var repo_default_branch="${repo_default_branch}" 

