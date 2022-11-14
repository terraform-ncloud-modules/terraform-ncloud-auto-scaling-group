
data "ncloud_vpc" "vpc" {
  count = var.vpc_name != null ? 1 : 0

  filter {
    name   = "name"
    values = [var.vpc_name]
  }
}

data "ncloud_subnet" "subnet" {
  count = var.subnet_name != null ? 1 : 0

  vpc_no = one(data.ncloud_vpc.vpc.*.id)
  filter {
    name   = "name"
    values = [var.subnet_name]
  }
}

data "ncloud_launch_configuration" "lc" {
  count = var.launch_configuration_name != null ? 1 : 0

  filter {
    name   = "name"
    values = [var.launch_configuration_name]
  }
}

data "ncloud_access_control_group" "acgs" {
  for_each = toset(var.access_control_group_names)

  vpc_no     = one(data.ncloud_vpc.vpc.*.id)
  is_default = (each.key == "default" ? true : false)
  filter {
    name   = "name"
    values = [each.key == "default" ? "${var.vpc_name}-default-acg" : each.key]
  }
}

data "ncloud_lb_target_group" "tgs" {
  for_each = toset(var.target_group_names)

  filter {
    name   = "name"
    values = [each.key]
  }
}


resource "ncloud_auto_scaling_group" "auto_scaling_group" {
  name = var.name

  launch_configuration_no      = coalesce(var.launch_configuration_id, one(data.ncloud_launch_configuration.lc.*.id))
  subnet_no                    = coalesce(var.subnet_id, one(data.ncloud_subnet.subnet.*.id))
  access_control_group_no_list = sort(coalescelist(var.access_control_group_ids, values(data.ncloud_access_control_group.acgs).*.id))
  server_name_prefix           = var.server_name_prefix
  min_size                     = var.min_size
  max_size                     = var.max_size
  desired_capacity             = var.desired_capacity
  ignore_capacity_changes      = var.ignore_capacity_changes
  default_cooldown             = var.default_cooldown
  health_check_type_code       = var.health_check_type_code
  health_check_grace_period    = var.health_check_grace_period
  target_group_list            = var.health_check_type_code == "LOADB" ? coalescelist(var.target_group_ids, values(data.ncloud_lb_target_group.tgs).*.id) : null

}

locals {
  adjustment_type_code = {
    ChangeInCapacity        = "CHANG"
    PercentChangeInCapacity = "PRCNT"
    ExactCapacity           = "EXACT"
  }
}


resource "ncloud_auto_scaling_policy" "policies" {
  for_each = { for policy in var.policies : policy.name => policy }

  auto_scaling_group_no = ncloud_auto_scaling_group.auto_scaling_group.id

  name                 = each.value.name
  adjustment_type_code = try(local.adjustment_type_code[each.value.adjustment_type_code], each.value.adjustment_type_code)
  scaling_adjustment   = each.value.scaling_adjustment
  min_adjustment_step  = each.value.min_adjustment_step
  cooldown             = each.value.cooldown

}


resource "ncloud_auto_scaling_schedule" "schedules" {
  for_each = { for schedule in var.schedules : schedule.name => schedule }

  auto_scaling_group_no = ncloud_auto_scaling_group.auto_scaling_group.id

  name             = each.value.name
  min_size         = each.value.min_size
  max_size         = each.value.max_size
  desired_capacity = each.value.desired_capacity
  start_time       = each.value.start_time
  end_time         = each.value.end_time
  recurrence       = each.value.recurrence
  time_zone        = each.value.time_zone
}

