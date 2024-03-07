terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-unique-name-karim"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
