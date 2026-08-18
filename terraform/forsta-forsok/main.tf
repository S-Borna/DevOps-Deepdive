terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

resource "local_file" "hej" {
  content  = "Hej, detta är min första Terraform-resurs."
  filename = "${path.module}/hello.txt"
}
