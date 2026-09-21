variable "gemini_api_key" {
  type      = string
  sensitive = true
}



variable "alert_email" {
  type = string

}


variable "web_ami_id" {
  type    = string
  default = "ami-084b839808145f146"
}

variable "app_ami_id" {
  type    = string
  default = "ami-0d4f0c30116ae9017"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}