terraform {
  backend "s3" {
    bucket = "orneltchriswesdd"
    key    = "chris/terraform.tfstate"
    region = "us-east-1"
  }
}
