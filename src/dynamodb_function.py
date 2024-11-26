import json
import boto3
import pytz
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('cisco-alert-table')

operations = {
    'create': lambda kwargs: table.put_item(**kwargs),
    'delete': lambda kwargs: table.delete_item(**kwargs),
    'update': lambda kwargs: table.update_item(**kwargs),
    'list': lambda kwargs: table.scan(**kwargs)
}

# Convert vmanage timestamp to datetime and then to string in HK timezone
def convert_time(vmanage_time):

    vmanage_dt = datetime.fromtimestamp(float(vmanage_time/1000))
    local_tz = pytz.timezone("Asia/Hong_Kong")
    utc = pytz.utc
    time_format = "%Y-%m-%d %H:%M:%S"
    local_datetime = utc.localize(vmanage_dt).astimezone(local_tz)
    alert_time = local_datetime.strftime(time_format)
    
    return alert_time

def lambda_handler(event, context):
    # TODO implement

    if event['operation'] == "create":
        alert_data = {}

        payload = event.get('payload')
        alert_data['customer_name'] = event['customer_name']

        vmanage_time = payload["Item"]['entry_time']
        alert_data['alert_time'] = convert_time(vmanage_time)

        alert_data['alert_msg'] = payload["Item"]['message']
        alert_data['severity'] = payload["Item"]['severity']
        alert_data['device'] = payload["Item"]['values'][0]['host-name']

        operations[event['operation']](alert_data)

        return {
        'statusCode': 200,
        'body': json.dumps('table updated!')
        }

    else:
        raise Exception('Unsupported operation')

    
    
