####################################
#LOCALS AND CHECKS
####################################
locals {
  lambdas = {
    writer = {
      source     = "lambda/writer/index.py"
      policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
    }
    reader = {
      source     = "lambda/reader/index.py"
      policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
    }
  }
  tags = {
    Environment = "dev"
  }

}

# Package the Lambda function code
data "archive_file" "example" {
    for_each = local.lambdas
  type        = "zip"
  source_file = each.value.source
  output_path = "${path.module}/build/${each.key}.zip"
}

# Lambda function to test and deploy the python
resource "aws_lambda_function" "example" {
 for_each = local.lambdas
  function_name    = "${var.function_name}-${each.key}"
  filename         = data.archive_file.example[each.key].output_path
  role             = aws_iam_role.example[each.key].arn
  handler          = "index.lambda_handler"
  source_code_hash = data.archive_file.example[each.key].output_base64sha256
  runtime = var.runtime

}
resource "aws_lambda_permission" "api_gateway" {
  for_each      = local.lambdas
  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.example.execution_arn}/*/*"
}


#create dynamoDB to store user data
resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = var.name
  billing_mode   = var.billing_mode
  hash_key       = var.hash_key
  
  attribute {
    name = "${var.hash_key}"
    type = "S"
  }

  tags = {
    Name        = var.name
    Environment = var.Environment
  }
}

#create roles for lambda to access dynamoDB
resource "aws_iam_role" "example" {
  for_each = local.lambdas
  name = "${var.name_role}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
tags = {
    Name        = "${var.name_role}-${each.key}"
    Environment = var.Environment
  }
}


resource "aws_iam_role_policy_attachment" "example" {
  for_each = local.lambdas
   policy_arn = each.value.policy_arn
  role       = aws_iam_role.example[each.key].name
  
}

################################
#Create API Gateway
################################
resource "aws_api_gateway_rest_api" "example" {
  name = var.name_api
  description = var.description
}

resource "aws_api_gateway_resource" "example" {
  parent_id   = aws_api_gateway_rest_api.example.root_resource_id
  path_part   = "example"
  rest_api_id = aws_api_gateway_rest_api.example.id
}

resource "aws_api_gateway_method" "example" {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
}

resource "aws_api_gateway_integration" "example" {
  rest_api_id             = aws_api_gateway_rest_api.example.id
  resource_id             = aws_api_gateway_resource.example.id
  http_method             = aws_api_gateway_method.example.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example["reader"].invoke_arn
}


resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  triggers = {

    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.example.id,
      aws_api_gateway_method.example.id,
      aws_api_gateway_integration.example.id,
    ]))
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
  stage_name    = var.stage_name
}

