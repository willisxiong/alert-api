## fetch the AWS managed policy
data "aws_iam_policy" "basic_policy" {
  name = "AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "amazonconnect" {
  name = "AmazonConnectVoiceIDFullAccess"
}

data "aws_iam_policy" "dynamodb" {
  name = "AmazonDynamoDBFullAccess"
}

resource "aws_iam_policy" "connectOutboundVoiceContact" {
  name = "ConnectOutboundVoiceContact_custom_policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "OutboundVoiceContact",
        "Effect" : "Allow",
        "Action" : [
          "connect:StartOutboundVoiceContact"
        ],
        "Resource" : "arn:aws:connect:ap-southeast-1:920708896738:instance/*/contact/*"
      }
    ]
  })
}

// create iam role for voice and sms lambda function
// make lambda service as the principal to assume the role
resource "aws_iam_role" "role_for_alert_channels_lambda" {
  name = "role-for-voice-sms"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

// create iam role for dynamodb action lambda function
// make lambda service as the principal to assume the role
resource "aws_iam_role" "role_for_dynamodb_action_lambda" {
  name = "role-for-dynamodb-action"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })
}

# attach basic policy for logging
resource "aws_iam_role_policy_attachment" "basic_policy_attachment" {
  role       = aws_iam_role.role_for_alert_channels_lambda.name
  policy_arn = data.aws_iam_policy.basic_policy.arn
}

# attach AmazonConnectVoiceIDFullAccess policy
resource "aws_iam_role_policy_attachment" "amazonconnect_policy_attachment" {
  role       = aws_iam_role.role_for_alert_channels_lambda.name
  policy_arn = data.aws_iam_policy.amazonconnect.arn
}

# attach connectOutboundVoiceContact policy
resource "aws_iam_role_policy_attachment" "connectOutboundVoiceContact_policy_attachment" {
  role       = aws_iam_role.role_for_alert_channels_lambda.name
  policy_arn = aws_iam_policy.connectOutboundVoiceContact.arn
}

# attach AmazonDynamoDBFullAccess policy
resource "aws_iam_role_policy_attachment" "dynamodb_policy_attachment" {
  role       = aws_iam_role.role_for_dynamodb_action_lambda.name
  policy_arn = data.aws_iam_policy.dynamodb.arn
}

## create lambda function zip file from source code
data "archive_file" "sms_lambda" {
  type        = "zip"
  source_file = "./src/sms_function.py"
  output_path = "./src/sms_function.zip"
}

data "archive_file" "voice_lambda" {
  type        = "zip"
  source_file = "./src/voice_function.py"
  output_path = "./src/voice_function.zip"
}

data "archive_file" "feishu_lambda" {
  type        = "zip"
  source_file = "./src/feishu_function.py"
  output_path = "./src/feishu_function.zip"
}

data "archive_file" "dynamodb_lambda" {
  type        = "zip"
  source_file = "./src/dynamodb_function.py"
  output_path = "./src/dynamodb_function.zip"
}
