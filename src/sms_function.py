import json
import time
import urllib3
import pytz
from datetime import datetime

url = "<cloudsms_url>"
local_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
http = urllib3.PoolManager()

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
    if event is not None:
        print(event) 
        payload = event.get('payload')
        phone_nums = []  
        for num in event['phone_nums']:
            phone_nums.append(num['address'])         
        
        vmanage_time = payload['entry_time']

        # Get the desired info in the vmanage alert record
        host_name = payload['values'][0]['host-name']
        alert_msg = payload['message']
        severity = payload['severity']
        component = payload['component']
        alert_time = convert_time(vmanage_time)

        data = {
                "uip_head": {
                    "METHOD": "SMS_SEND_REQUEST",
                    "SERIAL": 1,
                    "TIME": local_time, # "2023-02-15 16:00:00",
                    "CHANNEL": "<cloudsms_channel>",
                    "AUTH_KEY": "<cloudsms_auth>"
                },
                "uip_body": {
                    "SMS_CONTENT": f"【SDW Alert】\nAlert Message: {alert_msg}\nAlert Time: {alert_time} HKT\nImpact Device: {host_name}",
                    "DESTINATION_ADDR": phone_nums,
                    "ORIGINAL_ADDR": "CMIsdwan",
                },
                "uip_version": 2
        }

        send_sms = http.request(
            "POST",
            url,
            body=json.dumps(data),
            headers={'Content-Type': 'application/json'}
        )

        return {
            'statusCode': 200,
            'body': json.dumps('Hello from Lambda!')
        }
    
    else:
        return {
            'statusCode': 200,
            'body': json.dumps('No records found')
        } 