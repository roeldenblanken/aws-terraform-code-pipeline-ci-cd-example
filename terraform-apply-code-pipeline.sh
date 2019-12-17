#!/bin/bash

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

terraform plan