variable "name" {
  description = "Name of the Auto Scaling Group"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = null
}

variable "subnet_name" {
  description = "Name of the Subnet"
  type        = string
  default     = null
}

variable "subnet_id" {
  description = "ID of the Subnet"
  type        = string
  default     = null
}

variable "launch_configuration_id" {
  description = "ID of the Launch Configuration"
  type        = string
  default     = null
}

variable "launch_configuration_name" {
  description = "Name of the Launch Configuration"
  type        = string
  default     = null
}

variable "access_control_group_names" {
  description = "List of Access Control Group names"
  type        = list(string)
  default     = []
}

variable "access_control_group_ids" {
  description = "List of Access Control Group IDs"
  type        = list(string)
  default     = []
}

variable "target_group_ids" {
  description = "List of Target Group IDs"
  type        = list(string)
  default     = []
}

variable "target_group_names" {
  description = "List of Target Group names"
  type        = list(string)
  default     = []
}

variable "server_name_prefix" {
  description = "Prefix of the Server name"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 0
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = null
}

variable "ignore_capacity_changes" {
  description = "Ignore changes to min_size, max_size, and desired_capacity"
  type        = bool
  default     = false
}

variable "default_cooldown" {
  description = "Default cooldown time in seconds"
  type        = number
  default     = 300
}

variable "health_check_grace_period" {
  description = "Health check grace period in seconds"
  type        = number
  default     = 300
}

variable "health_check_type_code" {
  description = "Health check type code"
  type        = string
  default     = "SVR"
}

variable "policies" {
  description = "List of Auto Scaling Policies"
  type = list(object({
    name                 = string
    adjustment_type_code = string
    scaling_adjustment   = number
    min_adjustment_step  = optional(number, null)
    cooldown             = optional(number, 300)
  }))
  default = []
}

variable "schedules" {
  description = "List of Auto Scaling Schedules"
  type = list(object({
    name             = string
    min_size         = number
    max_size         = number
    desired_capacity = number
    start_time       = optional(string, null)
    end_time         = optional(string, null)
    recurrence       = optional(string, null)
    time_zone        = optional(string, "KST")
  }))
  default = []
}
