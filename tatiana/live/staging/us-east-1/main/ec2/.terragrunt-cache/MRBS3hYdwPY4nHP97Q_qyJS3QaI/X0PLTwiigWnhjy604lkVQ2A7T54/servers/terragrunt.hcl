
include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${dirname(find_in_parent_folders())}/tats_modules/modules//servers"
}


dependency "network" {
  config_path = "../network"
  mock_outputs = {
    vpc_id             = "tmp-vpc-id"
    private_subnet_id  = "tmp-subnet-1"
    public_subnets_ids = ["tmp-subnet-1", "tmp-subnet-2"]
  }
}

 dependency "acm" {
  config_path = "../acm"
  mock_outputs = {
    acm_certificate_arn = "arn:aws:acm:us-east-1:392031064982:certificate/12345678-1234-1234-1234-392031064982"
  }  
 }


inputs = {
  vpc_id = dependency.network.outputs.vpc_id
  public_subnets_ids = dependency.network.outputs.public_subnets_ids
  private_subnet_id = [dependency.network.outputs.private_subnet_id]
  acm_certificate_arn = dependency.acm.outputs.acm_certificate_arn
}