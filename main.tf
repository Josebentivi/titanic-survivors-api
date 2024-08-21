provider "aws" {
  region = "sa-east-1" # Escolha a região de são paulo
}

################ IAM Role e Policies para Lambda Function ################

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_execution_policy" {
  name   = "lambda_execution_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:*",
          "dynamodb:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach_policy" {
  role       = aws_iam_role.lambda_execution_role.id
  policy_arn = aws_iam_policy.lambda_execution_policy.arn
}

########## Configurações da Lambda Function ##########

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function" # Diretório da função lambda
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "predict_function" {
  function_name = "predict_survival"
  package_type  = "Image"
  image_uri     = "810002923125.dkr.ecr.sa-east-1.amazonaws.com/my-lambda-repo:latest"
  role          = aws_iam_role.lambda_execution_role.arn
}

resource "aws_dynamodb_table" "survival_predictions" {
  name           = "SurvivalPredictions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PassengerId"
  
  attribute {
    name = "PassengerId"
    type = "S"
  }
}

################ API Gateway Configurations ################

# Criação da API Gateway REST
resource "aws_api_gateway_rest_api" "titanic_api" {
  name        = "Titanic Survival Prediction API"
  description = "API for predicting Titanic survival using a machine learning model."
}

# Recurso principal /sobreviventes
resource "aws_api_gateway_resource" "survivors" {
  rest_api_id = aws_api_gateway_rest_api.titanic_api.id
  parent_id   = aws_api_gateway_rest_api.titanic_api.root_resource_id
  path_part   = "sobreviventes"
}

# Método POST em /sobreviventes
resource "aws_api_gateway_method" "post_survivor" {
  rest_api_id   = aws_api_gateway_rest_api.titanic_api.id
  resource_id   = aws_api_gateway_resource.survivors.id
  http_method   = "POST"
  authorization = "NONE"
}

# Integração com Lambda para o método POST
resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.titanic_api.id
  resource_id             = aws_api_gateway_resource.survivors.id
  http_method             = aws_api_gateway_method.post_survivor.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.predict_function.invoke_arn
}

# Método GET em /sobreviventes
resource "aws_api_gateway_method" "get_survivors" {
  rest_api_id = aws_api_gateway_rest_api.titanic_api.id
  resource_id   = aws_api_gateway_resource.survivors.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integração com Lambda para o método GET (listando todos)
resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.titanic_api.id
  resource_id             = aws_api_gateway_resource.survivors.id
  http_method             = aws_api_gateway_method.get_survivors.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.predict_function.invoke_arn
}

# Recurso /sobreviventes/{id}
resource "aws_api_gateway_resource" "survivor_by_id" {
  rest_api_id = aws_api_gateway_rest_api.titanic_api.id
  parent_id   = aws_api_gateway_resource.survivors.id
  path_part   = "{id}"
}

# Método GET em /sobreviventes/{id}
resource "aws_api_gateway_method" "get_survivor_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.titanic_api.id
  resource_id   = aws_api_gateway_resource.survivor_by_id.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.id" = true
  }
}

# Integração com Lambda para o método GET (específico)
resource "aws_api_gateway_integration" "get_by_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.titanic_api.id
  resource_id             = aws_api_gateway_resource.survivor_by_id.id
  http_method             = aws_api_gateway_method.get_survivor_by_id.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.predict_function.invoke_arn
  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# Método DELETE em /sobreviventes/{id}
resource "aws_api_gateway_method" "delete_survivor_by_id" {
  rest_api_id   = aws_api_gateway_rest_api.titanic_api.id
  resource_id   = aws_api_gateway_resource.survivor_by_id.id
  http_method   = "DELETE"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.id" = true
  }
}

# Integração com Lambda para o método DELETE
resource "aws_api_gateway_integration" "delete_by_id_integration" {
  rest_api_id             = aws_api_gateway_rest_api.titanic_api.id
  resource_id             = aws_api_gateway_resource.survivor_by_id.id
  http_method             = aws_api_gateway_method.delete_survivor_by_id.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.predict_function.invoke_arn
  request_parameters = {
    "integration.request.path.id" = "method.request.path.id"
  }
}

# Permitir que o API Gateway invoque a função Lambda
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.predict_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.titanic_api.execution_arn}/*/*"
}

########################################################


# Deploying the API Gateway
resource "aws_api_gateway_deployment" "apigw_deployment" {
  depends_on = [
    aws_api_gateway_method.post_survivor,
    aws_api_gateway_method.get_survivors,
    aws_api_gateway_method.get_survivor_by_id,
    aws_api_gateway_method.delete_survivor_by_id,
    aws_api_gateway_integration.post_integration,
    aws_api_gateway_integration.get_integration,
    aws_api_gateway_integration.get_by_id_integration,
    aws_api_gateway_integration.delete_by_id_integration
  ]
  
  rest_api_id = aws_api_gateway_rest_api.titanic_api.id
  stage_name  = ""

  lifecycle {
    create_before_destroy = true
  }
}

# Creating API Gateway Stage
resource "aws_api_gateway_stage" "apigw_stage" {
  deployment_id = aws_api_gateway_deployment.apigw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.titanic_api.id
  stage_name    = "prod"
}