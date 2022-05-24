terraform {
  backend "s3" {
    bucket = "test-terraform-state-bucket-lq"
    key    = "logiquad-stp-setp/appinfra.tfstate"
    region = "ap-south-1"
  }
}