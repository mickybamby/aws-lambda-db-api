variable "name" {
  description = "The name of the dynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "The mode which our table uses for billing"
}

variable "hash_key" {
  description = "This represent the partition key of the table"
  type = string
}

variable "Name" {
  description = "This is the tag name of the DB"
  type = string
}

variable "Environment" {
  description = "This is the tag environment of the DB"
  type = string
}

variable "function_name" {
  description = "The name of the function"
  type = string
}

variable "name_role" {
  description = "The name of the execution role"
  type = string
}

variable "runtime" {
  description = "The type of the runtime being used to run our function"
  type = string
}
variable "name_policy_lamba" {
  description = "The name of the policy for the lambda that grants its full access to DynamoDB"
  type = string
}

variable "name_api" {
  description = "Ths is the name of the API"
  type = string
}

variable "description" {
  description = "Thhis is the api for my project"
  type = string
}

variable "stage_name" {
  description = "This is the name of the stage"
  type = string
}

variable "name_policy" {
  description = "The name of the iam policy"
  type = string
}