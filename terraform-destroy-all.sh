#!/bin/bash

#####
# Destroy the infra and app pipelines
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

cd "envs/${env}"

# as configured in the env/dev/env.tf file
terraform init
terraform destroy -var my_suffix="${i}" -var my_prefix="notimportantfordestroy" -var owner_infra="notimportantfordestroy" -var repo_name_infra="notimportantfordestroy" -var repo_default_branch_infra="notimportantfordestroy" -var owner_app="notimportantfordestroy" -var repo_name_app="notimportantfordestroy" -var repo_default_branch_app="notimportantfordestroy"
