module "network" {
  source = "../../modules/network"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
}

module "ec2" {
  source = "../../modules/ec2"

  name_prefix     = local.name_prefix
  vpc_id          = module.network.vpc_id
  vpc_cidr        = var.vpc_cidr
  subnet_id       = module.network.public_subnet_id
  instance_type   = var.instance_type
  data_bucket_arn = module.s3.bucket_arn
}

module "s3" {
  source = "../../modules/s3"

  name_prefix = local.name_prefix
}

module "audit" {
  source = "../../modules/audit"

  name_prefix = local.name_prefix
}

module "remediation" {
  source = "../../modules/remediation"

  name_prefix       = local.name_prefix
  security_group_id = module.ec2.security_group_id
}