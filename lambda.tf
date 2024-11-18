resource "aws_lambda_function" "sms_func" {
  filename      = data.archive_file.sms_lambda.output_path
  function_name = "sms-function"
  role          = aws_iam_role.role_for_alert_channels_lambda.arn
  runtime       = "python3.12"
  handler       = "sms_function.lambda_handler"
  layers        = [aws_lambda_layer_version.pytz.arn]
}

// allow api gateway access sms function
resource "aws_lambda_permission" "allow_apigateway_sms" {
  statement_id = "AllowExecutionFromApigatewayInSms"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sms_func.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.alert_api.execution_arn}/*/*"
}

resource "aws_lambda_function" "voice_func" {
  filename      = data.archive_file.voice_lambda.output_path
  function_name = "voice-function"
  role          = aws_iam_role.role_for_alert_channels_lambda.arn
  runtime       = "python3.12"
  handler       = "voice_function.lambda_handler"
  layers        = [aws_lambda_layer_version.pytz.arn]
}

// allow api gateway access voice function
resource "aws_lambda_permission" "allow_apigateway_voice" {
  statement_id = "AllowExecutionFromApigatewayInVoice"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.voice_func.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.alert_api.execution_arn}/*/*"
}

resource "aws_lambda_function" "feishu_func" {
  filename      = data.archive_file.feishu_lambda.output_path
  function_name = "feishu-function"
  role          = aws_iam_role.role_for_alert_channels_lambda.arn
  runtime       = "python3.12"
  handler       = "feishu_function.lambda_handler"
  layers        = [aws_lambda_layer_version.pytz.arn]
}

// allow api gateway access feishu function
resource "aws_lambda_permission" "allow_apigateway_feishu" {
  statement_id = "AllowExecutionFromApigatewayInFeishu"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.feishu_func.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.alert_api.execution_arn}/*/*"
}

# create lambda layer for pytz, a time zone library
resource "aws_lambda_layer_version" "pytz" {
  filename   = "./src/pytz.zip"
  layer_name = "pytz1"

  compatible_runtimes = ["python3.12"]
}