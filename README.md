# Multiple Auto Scaling Group Module

## **This version of the module requires Terraform version 1.3.0 or later.**

This document describes the Terraform module that creates multiple Ncloud Auto Scaling Groups.

## Variable Declaration

### Structure : `variable.tf`

You need to create `variable.tf` and copy & paste the variable declaration below.

**You can change the variable name to whatever you want.**

``` hcl
variable "auto_scaling_groups" {
  type = list(object({
    name = string

    launch_configuration_name = optional(string, null)

    vpc_name                   = optional(string, null)
    subnet_name                = optional(string, null)
    access_control_group_names = optional(list(string), [])   // if set "default", then "default access control group" will be set.

    server_name_prefix      = string
    min_size                = optional(number, 0)
    max_size                = optional(number, 0)
    desired_capacity        = optional(number, null)
    ignore_capacity_changes = optional(bool, false)     // if set "true", any changes of "min_size", "max_size" and "desired_capacity" after first creation will be ignored .

    default_cooldown = optional(number, 300)

    health_check_type_code    = optional(string, "SVR")    // SVR | LOADB
    health_check_grace_period = optional(number, 300)      // required when health_check_type_code = "LOADB"
    target_group_names        = optional(list(string), []) // valid only for health_check_type_code = "LOADB"

    policies = optional(list(object({
      name                 = string
      adjustment_type_code = string                     // ChangeInCapacity | PercentChangeInCapacity | ExactCapacity.  or it can be one of CHANG | PRCNT | EXACT.
      scaling_adjustment   = number                     // positive(n) to increase | negative(-n) to decreate. negative value can be set only for "ChangeInCapacity (CHANG) | PercentChangeInCapacity (PRCNT)"
      min_adjustment_step  = optional(number, null)     // valid only for adjustment_type_code = "PercentChangeInCapacity | PRCNT"
      cooldown             = optional(number, 300)
    })), [])

    schedules = optional(list(object({
      name             = string
      min_size         = number
      max_size         = number
      desired_capacity = number
      start_time       = optional(string, null)         // format : yyyy-MM-ddTHH:mm:ssZ  (for example : 2022-11-04T15:00:00+0900).
      end_time         = optional(string, null)         // format : yyyy-MM-ddTHH:mm:ssZ  (for example : 2022-11-08T15:00:00+0900).
      recurrence       = optional(string, null)         // format : crontab  (for example : 0 0 * * *)
      time_zone        = optional(string, "KST")
    })), [])
  }))
  default = []
}


```

### Example : `terraform.tfvars`

You can create a `terraform.tfvars` and refer to the sample below to write the variable specification you want.
File name can be `terraform.tfvars` or anything ending in `.auto.tfvars`

**It must exactly match the variable name above.**

``` hcl
auto_scaling_groups = [
  {
    name                      = "asg-foo"
    launch_configuration_name = "lc-foo"

    vpc_name                   = "vpc-foo"
    subnet_name                = "sbn-foo-public-1"
    access_control_group_names = ["default", "acg-foo-public"]

    server_name_prefix      = "asg-foo"
    min_size                = 1
    max_size                = 3
    desired_capacity        = 1
    ignore_capacity_changes = true
    default_cooldown        = 300

    health_check_type_code    = "SVR"

    policies = [
      {
        name                 = "scale-up"
        adjustment_type_code = "ChangeInCapacity"
        scaling_adjustment   = 1
      }
    ]

    schedules = [
      {
        name             = "every-day"
        min_size         = 0
        max_size         = 0
        desired_capacity = 0
        recurrence       = "0 0 * * *"
      }
    ]
  }
]




```

## Module Declaration

### `main.tf`

Map your `Auto Scaling Group variable name` to a `local Auto Scaling Group variable`. `Auto Scaling Group module` are created using `local Auto Scaling Group variables`. This eliminates the need to change the variable name reference structure in the `Auto Scaling Group module`.

``` hcl
locals {
  auto_scaling_groups = var.auto_scaling_groups
}
```

Then just copy & paste the module declaration below.

``` hcl
module "auto_scaling_groups" {
  source = "terraform-ncloud-modules/auto-scaling-group/ncloud"

  for_each = { for asg in local.auto_scaling_groups : asg.name => asg }

  name = each.value.name

  // you can use "launch_configuration_name", then module will find "launch_configuration_id" from datasource.
  launch_configuration_name = each.value.launch_configuration_name
  // or use only "launch_configuration_id" instead for inter-module reference structure.
  # launch_configuration_id = module.launch_configurations[each.value.launch_configuration_name].launch_configuration.id

  // you can use "vpc_name" and "subnet_name", then module will find "subnet_id" from datasource.
  vpc_name    = each.value.vpc_name
  subnet_name = each.value.subnet_name
  // or use only "subnet_id" instead for inter-module reference structure.
  # subnet_id   = module.vpcs[each.value.vpc_name].subnets[each.value.subnet_name].id
  
  // you can use "access_control_group_names", then module will find "access_control_group_ids" from datasource.
  access_control_group_names = each.value.access_control_group_names
  // or use only "access_control_group_ids" instead for inter-module reference structure.
  # access_control_group_ids   = [ for acg_name in each.value.access_control_group_names : module.vpcs[each.value.vpc_name].access_control_groups[acg_name].id ]
  
  server_name_prefix = each.value.server_name_prefix

  min_size                = each.value.min_size
  max_size                = each.value.max_size
  desired_capacity        = each.value.desired_capacity
  ignore_capacity_changes = each.value.ignore_capacity_changes
  default_cooldown        = each.value.default_cooldown

  health_check_type_code    = each.value.health_check_type_code
  health_check_grace_period = each.value.health_check_grace_period

  // you can use "target_group_names", then module will find "target_group_ids" from datasource.
  target_group_names = each.value.target_group_names
  // or use only "target_group_ids" instead for inter-module reference structure.
  # target_group_ids   = [ for tg_name in each.value.target_group_names : module.target_groups[tg_name].target_group.id ]

  policies  = each.value.policies
  schedules = each.value.schedules

}

```