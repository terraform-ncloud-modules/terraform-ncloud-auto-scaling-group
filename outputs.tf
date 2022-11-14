

output "auto_scaling_group" {
  value = ncloud_auto_scaling_group.auto_scaling_group
}

output "policies" {
  value = ncloud_auto_scaling_policy.policies
}

output "schedules" {
  value = ncloud_auto_scaling_schedule.schedules
}
