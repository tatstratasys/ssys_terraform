# Configure Terragrunt to store tfstate files locally
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "${path_relative_to_include()}/terraform.tfstate"
  }
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
    region = "${local.region}"
}
EOF
}

locals {
  # Automatically load variables at different levels
  account_vars = try(read_terragrunt_config("account.hcl"), read_terragrunt_config(find_in_parent_folders("account.hcl")))
  region_vars = try(read_terragrunt_config("region.hcl"), read_terragrunt_config(find_in_parent_folders("region.hcl")))
  

   # Deployment specific variables/secrets and tags
  tf_vars = try(yamldecode(file("${get_terragrunt_dir()}/variables.yaml")), {})
  
  # Extract the variables we need for easy access
  account_name = local.account_vars.locals.account_name
  account_id   = local.account_vars.locals.aws_account_id
  region   = local.region_vars.locals.region
}

# Configure root level variables that all resources can inherit.
inputs = merge(
  local.account_vars.locals,
  local.region_vars.locals,
  local.tf_vars,
  {
    region         = local.region
  }
)


terraform{

    before_hook "before_hook1" {
    commands     = ["apply", "plan", "validate"]
    execute      = ["terraform", "fmt", "-recursive"]
  } 

    before_hook "before_hook2" {
    commands     = ["apply", "plan", "validate"]
    execute      = ["echo", "${get_terragrunt_dir()}"]
  }

    after_hook "after_hook1" {
    commands      = ["apply", "plan","validate"]
    execute       = ["echo", "completed terragrunt command successfully"]
    run_on_error  = false
  }

    error_hook "error_hook1" {
    commands      = ["apply", "plan","validate"]
    execute       = ["echo", "error running terragrunt command"]
    on_errors  = [
      ".*",
    ]
  }
  

}