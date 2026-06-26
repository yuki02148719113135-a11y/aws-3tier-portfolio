variable "env" {
  description = "Environment name"
  type        = string
  default     = "portfolio"
}

variable "myip" {
  description = "Your IP address for SSH access (e.g. 1.2.3.4/32)"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "db_password" {
  description = "RDS MySQL password"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "RDS MySQL username"
  type        = string
  default     = "admin"
}
