// create a rest api
resource "aws_api_gateway_rest_api" "alert_api" {
  name        = "cisco-sdw-alert-api"
  description = "api for calling sms, voice and feishu"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

// create resource /sms-alert and /voice-alert and /alert-store in api gateway
resource "aws_api_gateway_resource" "sms_alert" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  parent_id   = aws_api_gateway_rest_api.alert_api.root_resource_id
  path_part   = "sms-alert"
}

resource "aws_api_gateway_resource" "voice_alert" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  parent_id   = aws_api_gateway_rest_api.alert_api.root_resource_id
  path_part   = "voice-alert"
}

resource "aws_api_gateway_resource" "alert_store" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  parent_id   = aws_api_gateway_rest_api.alert_api.root_resource_id
  path_part   = "alert-store"
}

// create a method request for sms alert
resource "aws_api_gateway_method" "post_sms" {
  rest_api_id      = aws_api_gateway_rest_api.alert_api.id
  resource_id      = aws_api_gateway_resource.sms_alert.id
  http_method      = "POST"
  api_key_required = true
  authorization    = "NONE"

}

// create a method request for voice alert
resource "aws_api_gateway_method" "post_voice" {
  rest_api_id      = aws_api_gateway_rest_api.alert_api.id
  resource_id      = aws_api_gateway_resource.voice_alert.id
  http_method      = "POST"
  api_key_required = true
  authorization    = "NONE"

}

// create a method request for data store
resource "aws_api_gateway_method" "post_alert" {
  rest_api_id      = aws_api_gateway_rest_api.alert_api.id
  resource_id      = aws_api_gateway_resource.alert_store.id
  http_method      = "POST"
  api_key_required = true
  authorization    = "NONE"

}

// create a integration with sms alert lambda for sms-alert resource
resource "aws_api_gateway_integration" "sms_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.alert_api.id
  resource_id             = aws_api_gateway_resource.sms_alert.id
  http_method             = aws_api_gateway_method.post_sms.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.sms_func.invoke_arn
}

// create a integration with voice alert lambda for voice-alert resource
resource "aws_api_gateway_integration" "voice_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.alert_api.id
  resource_id             = aws_api_gateway_resource.voice_alert.id
  http_method             = aws_api_gateway_method.post_voice.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.voice_func.invoke_arn
}

// create a integration with data store lambda for data-store resource
resource "aws_api_gateway_integration" "dynamodb_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.alert_api.id
  resource_id             = aws_api_gateway_resource.alert_store.id
  http_method             = aws_api_gateway_method.post_alert.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.dynamodb_func.invoke_arn
}

// create a deployment for the api
// the deployment created after method and integration 
resource "aws_api_gateway_deployment" "alert_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id

  depends_on = [
    aws_api_gateway_integration.sms_lambda_integration,
    aws_api_gateway_integration.voice_lambda_integration,
    aws_api_gateway_integration.dynamodb_lambda_integration,
    aws_api_gateway_method.post_sms,
    aws_api_gateway_method.post_voice,
    aws_api_gateway_method.post_alert
  ]
}

// create a stage for the deployment and attach to it
resource "aws_api_gateway_stage" "alert_api_stage" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.alert_api.id
  deployment_id = aws_api_gateway_deployment.alert_api_deployment.id
}

// create a api key for the api
resource "aws_api_gateway_api_key" "alert_api_key" {
  name = "cisco-sdw-alert-api-key"
}

// create a usage plan key for the api key
resource "aws_api_gateway_usage_plan_key" "alert_api_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.alert_api_key.id
  usage_plan_id = aws_api_gateway_usage_plan.alert_api_usage_plan.id
  key_type      = "API_KEY"
}

// Add method responses for both SMS and Voice endpoints
resource "aws_api_gateway_method_response" "post_sms_response" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  resource_id = aws_api_gateway_resource.sms_alert.id
  http_method = aws_api_gateway_method.post_sms.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "post_voice_response" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  resource_id = aws_api_gateway_resource.voice_alert.id
  http_method = aws_api_gateway_method.post_voice.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "post_dynamodb_response" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  resource_id = aws_api_gateway_resource.alert_store.id
  http_method = aws_api_gateway_method.post_alert.http_method
  status_code = "200"
}

// create a integration response for sms alert
resource "aws_api_gateway_integration_response" "sms_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  resource_id = aws_api_gateway_resource.sms_alert.id
  http_method = aws_api_gateway_method.post_sms.http_method
  status_code = aws_api_gateway_method_response.post_sms_response.status_code
  depends_on  = [aws_api_gateway_integration.sms_lambda_integration]
}

// create a integration response for voice alert
resource "aws_api_gateway_integration_response" "voice_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  resource_id = aws_api_gateway_resource.voice_alert.id
  http_method = aws_api_gateway_method.post_voice.http_method
  status_code = aws_api_gateway_method_response.post_voice_response.status_code
  depends_on  = [aws_api_gateway_integration.voice_lambda_integration]
}

// create a integration response for alert store
resource "aws_api_gateway_integration_response" "dynamodb_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  resource_id = aws_api_gateway_resource.alert_store.id
  http_method = aws_api_gateway_method.post_alert.http_method
  status_code = aws_api_gateway_method_response.post_dynamodb_response.status_code
  depends_on  = [aws_api_gateway_integration.dynamodb_lambda_integration]
}

// create a usage plan for the api
resource "aws_api_gateway_usage_plan" "alert_api_usage_plan" {
  name = "cisco-sdw-alert-api-usage-plan"

  quota_settings {
    limit  = 1000
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 10
    rate_limit  = 5
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.alert_api.id
    stage  = aws_api_gateway_stage.alert_api_stage.stage_name
  }
}