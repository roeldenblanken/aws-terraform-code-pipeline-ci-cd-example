#!/bin/bash

#####
# Applies the configuration described in env/dev/dev.tf
# Example usage:
# ./terraform-apply-code-pipeline.sh 
# env=dev prefix=code-pipeline-demo my_suffix="suffix" repo_owner_infra=roeldenblanken repo_name_infra=ecs-fargate-example repo_default_branch_infra=master repo_owner_app=roeldenblanken repo_name_app=docker-hello-world repo_default_branch_app=master ./terraform-apply-code-pipeline.sh 
# terraform apply -var prefix=code-pipeline-demo -var my_suffix="suffix" -var owner_infra="roeldenblanken" -var repo_name_infra="ecs-fargate-example" -var repo_default_branch_infra="master" owner_app="roeldenblanken" -var repo_name_app="ecs-fargate-example" -var repo_default_branch_app="master"
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
if [ -z "${suffix}" ]; then
	echo -n suffix: 
	read suffix
fi

# Repo_owner_infra of the repository
if [ -z "${repo_owner_infra}" ]; then
	echo -n repo_owner_infra: 
	read repo_owner_infra
fi

# repo_name_infra of the repository
if [ -z "${repo_name_infra}" ]; then
	echo -n repo_name_infra: 
	read repo_name_infra
fi

# repo_default_branch_infra of the repository
if [ -z "${repo_default_branch_app}" ]; then
	echo -n repo_default_branch_infra: 
	read repo_default_branch_infra
fi

# Repo_owner_app of the repository
if [ -z "${repo_owner_app}" ]; then
	echo -n repo_owner_app: 
	read repo_owner_app
fi

# repo_name_app of the repository
if [ -z "${repo_name_app}" ]; then
	echo -n repo_name_app: 
	read repo_name_app
fi

# repo_default_branch_app of the repository
if [ -z "${repo_default_branch_app}" ]; then
	echo -n repo_default_branch_app: 
	read repo_default_branch_app
fi

cd "envs/${env}"

# as configured in the env/dev/env.tf file
terraform init
terraform apply -var my_prefix="${prefix}" -var my_suffix="${suffix}" -var owner_infra="${repo_owner_infra}" -var repo_name_infra="${repo_name_infra}" -var repo_default_branch_infra="${repo_default_branch_infra}" -var owner_app="${repo_owner_app}" -var repo_name_app="${repo_name_app}" -var repo_default_branch_app="${repo_default_branch_app}" 

