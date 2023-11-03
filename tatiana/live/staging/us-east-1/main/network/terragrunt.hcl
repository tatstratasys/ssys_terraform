
include "root" {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "${dirname(find_in_parent_folders())}/tats_modules/modules//network"
}
