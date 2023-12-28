terraform {
  backend "oci_objectstorage_bucket" {
    bucket         = "tfstate_bucket"
    key            = "terraform.tfstate"
    namespace      = "remote_tfstate_file"
    encrypt        = true
  }
}