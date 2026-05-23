variable "instance_type" {
  description = "EC2 instance type for the Minecraft server"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of the SSH key pair (must already exist in AWS)"
  type        = string
}

variable "your_ip" {
  description = "Your public IP in CIDR notation for SSH access (e.g. 1.2.3.4/32)"
  type        = string
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}