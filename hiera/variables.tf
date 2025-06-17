variable "lookup_key" {
  description = "The key you wish Hiera to look up for you (eg: 'data', 'nework.s3', 'tags.Environment', 'maintenance_window.1'"
  type    = string
  default = ""
}

variable "default" {
  description = "The default value returned if Hiera does not find any data"
  type = string
  default = "{}"
}

variable "aws_account" {
  description = "AWS Account name, eg: 'dev', 'beta', 'prod'"
  type = string
  default = ""
}

variable "region" {
  description = "Part of Hiera's scope configuration, which controls lookups"
  type = string
  default = ""
}

variable "group" {
  description = "Group name, eg: 'ew1a', 'ew1b', 'ops-ew1a' etc"
  type = string
  default = ""
}

variable "stack" {
  description = "Stack being deployed, eg: 'vpc', 'eks'"
  type = string
  default = ""
}
