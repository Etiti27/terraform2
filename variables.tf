variable "AMI" {
    description = "this is the AMI of the device"
  
}
variable "instance_type" {
    description = "instance type"
    type = map(string)
    default = {
      "prod" = "t2.medium"
      "dev" = "t2.micro"
    }
  
}
variable "region" {
    description = "us-east-1 region"
  
}
variable "vpc_cidr" {
    default = "10.0.0.0/16"
  
}