module "network" {
    source = "./modules/network"
    vpc_cidr = var.vpc_cidr
    env = "tats_test"
}

module "acm" {
  source = "./modules/acm" 
  domain_name = var.domain_name
  aws_route53_record = var.aws_route53_record
  aws_route53_zone_name = var.aws_route53_zone_name
}

module "servers" {
    source = "./modules/servers"
    vpc_id = module.network.vpc_id
    private_subnet_id = [module.network.private_subnet_id]
    acm_certificate_arn = module.acm.acm_certificate_arn
    instance_type = var.instance_type
    public_subnets_ids = module.network.public_subnets_ids
    aws_route53_zone_name = var.aws_route53_zone_name
    aws_route53_record = var.aws_route53_record
    path = var.path
    depends_on = [ module.network, module.acm]
}

