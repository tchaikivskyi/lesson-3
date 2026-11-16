terraform {
  backend "s3" {
    bucket         = "tchaikivskyi-terraform-state-lesson-5"
    key            = "lesson-5/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
