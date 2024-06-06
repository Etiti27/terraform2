terraform {
  backend "s3" {
    bucket = "orneltchris"
    key    = "chris/terraform.tfstate"
    region = "us-east-1"
  }
}
