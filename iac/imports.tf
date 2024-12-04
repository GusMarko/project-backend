data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    organization = "hashicorp"
    bucket = "mg-terraform-state-storage"
    key = "project-networking/terraform.tfstate"
    region = "${var.aws_region}"
  }
}