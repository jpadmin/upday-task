terraform {
  backend "s3" {
    bucket  = "upday-infra-terraform-tfstate"
    key     = "s3.tfstate"
    region  = "us-east-1"
  }
}
