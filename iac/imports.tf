resource "terraform_remote_state" "networking" {
  backend = "remote"

  config = {
    organization = "hashicorp"
    bucket = "mg-terraform-state-storage"
    key = "project-networking/terraform.tfstate"
    region = "${var.region}"
  }
}