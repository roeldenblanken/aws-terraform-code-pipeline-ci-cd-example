locals {
  my_deployment   = "${var.prefix}-${var.env}"
}

# Create the following resource groups for finding resources.
# See AWS Console => Resource groups.

module "rg_environment" {
  source        = "./resource-group"
  prefix        = "${var.prefix}"
  env           = "${var.env}"
  tag_key       = "Environment"
  tag_value     = "${var.env}"
}

module "rg_deployment" {
  source        = "./resource-group"
  prefix        = "${var.prefix}"
  env           = "${var.env}"
  tag_key       = "Deployment"
  tag_value     = "${local.my_deployment}"
}

module "rg_prefix" {
  source        = "./resource-group"
  prefix        = "${var.prefix}"
  env           = "${var.env}"
  tag_key       = "Prefix"
  tag_value     = "${var.prefix}"
}


module "rg_terraform" {
  source        = "./resource-group"
  prefix        = "${var.prefix}"
  env           = "${var.env}"
  tag_key       = "Terraform"
  tag_value     = "true"
}

module "rg_region" {
  source        = "./resource-group"
  prefix        = "${var.prefix}"
  env           = "${var.env}"
  tag_key       = "Region"
  tag_value     = "${var.region}"
}