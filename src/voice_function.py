import json
import boto3

client = boto3.client('connect')

def lambda_handler(event, context):
    # TODO implement
    response = client.start_outbound_voice_contact(
        DestinationPhoneNumber = event['phone_num'],
        ContactFlowId = "<Amazonconnect_contactflowid>",
        InstanceId = "<Amazonconnect_instanceid>",
        QueueId = "<Amazonconnect_queueid>"
    )


    return {
        'statusCode': 200,
        'body': json.dumps(f'The call sent to {event['phone_num']}!')
    }
