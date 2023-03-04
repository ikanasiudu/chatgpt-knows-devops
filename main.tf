provider "aws" {
  region = var.aws_region
}

# Create a new VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create two subnets in different availability zones
resource "aws_subnet" "my_subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "my_subnet_b" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
}

# Create two security groups
resource "aws_security_group" "my_security_group_a" {
  name_prefix = "my-security-group-a"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "my_security_group_b" {
  name_prefix = "my-security-group-b"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Step 1: Create an ECR repository
resource "aws_ecr_repository" "my_app" {
  name = "my-app"
}

// Create IAM for ECS task definition
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

// Create a new task execution role policy
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "ecs-task-execution-policy"
  description = "Policy for ECS task execution role"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
  role       = aws_iam_role.ecs_task_execution_role.name
}

// Step 2: Create an ECS task definition
resource "aws_ecs_task_definition" "my_app" {
  family = "my-app"
  container_definitions = jsonencode([{
    name  = "my-app"
    image = "${aws_ecr_repository.my_app.repository_url}:latest"
    port_mappings = [{
      container_port = 80
      host_port      = 80
    }]
  }])
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

// Create Cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "my-ecs-cluster"
}

// Step 3: Create an ECS service
resource "aws_ecs_service" "my_app" {
  name            = "my-app"
  task_definition = aws_ecs_task_definition.my_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.my_ecs_cluster.arn

  network_configuration {
    subnets          = [aws_subnet.my_subnet_a.id, aws_subnet.my_subnet_b.id]
    security_groups  = [aws_security_group.my_security_group_a.id, aws_security_group.my_security_group_b.id]
    assign_public_ip = true
  }
}

// Step 4: Create an IAM role for CodePipeline
resource "aws_iam_role" "codepipeline" {
  name = "codepipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline" {
  policy_arn = var.codepipeline_policy_arn
  role       = aws_iam_role.codepipeline.name
}

// Step 5: Create a CodeBuild project for building your code
resource "aws_codebuild_project" "my_app" {
  name         = "my-app-build"
  description  = "Build Docker image for my-app"
  service_role = var.codebuild_service_role_arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "ECR_REPOSITORY_URL"
      value = aws_ecr_repository.my_app.repository_url
    }

  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
    git_clone_depth = 1
  }
}

// Step 6: Create a CodePipeline pipeline
resource "aws_codepipeline" "my_app" {
  name     = "my-app"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    type         = "S3"
    location     = "chatgptknowsdevops"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        Owner = "ikanasiudu"
        Repo = "${var.github_repo_name}"
        Branch     = "master"
        OAuthToken     = var.github_oauth_token
      }
    }
  }
  // Step 7: Add a CodePipeline stage for testing your code
  stage {
    name = "Test"

    action {
      name             = "Test"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["test"]
      configuration = {
        ProjectName = "my-app-test"
      }
    }
  }
  // Step 8: Add a CodePipeline stage for building your code
  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]
      configuration = {
        ProjectName = "my-app-build"
      }
    }
  }

  // Step 9: Add a CodePipeline stage for staging your code
  stage {
    name = "Stage"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build"]
      configuration = {
        ClusterName = "my-ecs-cluster"
        ServiceName = "my-app"
        FileName    = "imagedefinitions.json"
      }
    }
  }
  // Step 10: Add a CodePipeline stage for deploying your code
  stage {
    name = "Deploy"

    action {
      name     = "Approve"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build"]
      configuration = {
        ClusterName = "my-ecs-cluster"
        ServiceName = "my-app"
        FileName    = "imagedefinitions.json"
      }
    }
  }

}





