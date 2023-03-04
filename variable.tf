variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ecs_cluster_name" {
  type    = string
  default = "my-ecs-cluster"
}

variable "ecs_service_name" {
  type    = string
  default = "my-app"
}

variable "codecommit_repo_name" {
  type    = string
  default = "my-codecommit-repo"
}

variable "codepipeline_name" {
  type    = string
  default = "my-app"
}

variable "codebuild_project_name" {
  type    = string
  default = "my-app-build"
}

variable "codebuild_service_role_arn" {
  type    = string
  default = "arn:aws:iam::890963952437:role/codebuild"
}

variable "s3_artifact_bucket_name" {
  type    = string
  default = "my-artifact-bucket"
}

variable "ecr_repository_name" {
  type    = string
  default = "my-app"
}

variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-12345678901234567", "subnet-23456789012345678"]
}

variable "security_group_ids" {
  type    = list(string)
  default = ["sg-12345678901234567"]
}

variable "github_repo_name" {
  description = "The name of the GitHub repository"
  default     = "chatgpt-knows-devops"
}

variable "github_oauth_token" {
  description = "The OAuth token for github"
}

variable "account_id" {
  default = "123456789012"
}

variable "codepipeline_policy_arn" {
  description = "Policy arn for codepipeline"
  default = "arn:aws:iam::890963952437:policy/AWSCodePipelineFullAccess"
}
