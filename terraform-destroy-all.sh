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

declare -a arr=('infra' 'ecs-app' 'k8s-app')

for i in "${arr[@]}"
do
   echo "Destroying $i in environment ${env} with source=$i"
   # replace the Terraform bucket state source prefix so that the infra and app state are not shared
   sed -i "s/.*key.*=.*/key        = \"aws-code-pipeline-demo\/dev\/$i\/terraform.tfstate\"/g" env.tf
   # as configured in the env/dev/env.tf file
	terraform init -reconfigure
	export TF_COMMAND="terraform destroy -var my_prefix='notimportantfordestroy' -var my_suffix='notimportantfordestroy' -var type=${i} -var owner='notimportantfordestroy' -var repo_name='notimportantfordestroy' -var repo_default_branch='notimportantfordestroy'" 
	echo command=${TF_COMMAND}
	$TF_COMMAND
done