resource "opslevel_check_code_issue" "this" {
  constraint      = var.constraint
  issue_name      = var.issue_name
  issue_type      = var.issue_type
  max_allowed     = var.max_allowed
  resolution_time = var.resolution_time
  severity        = var.severity

  # -- check base fields --
  category  = module.category.this
  enable_on = var.enable_on
  enabled   = var.enabled
  filter    = var.filter
  level     = module.level.this
  name      = var.name
  notes     = var.notes
  owner     = var.owner
}

module "category" {
  source          = "../../rubric_category/data"
  rubric_category = var.category
}

module "level" {
  source       = "../../rubric_level/data"
  rubric_level = var.level
}
