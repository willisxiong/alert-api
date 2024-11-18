import json
import urllib3
import hashlib
import base64
import hmac
import time
import pytz
from datetime import datetime

feishu_webhook_url = "<feishu_webhook_url>"
http = urllib3.PoolManager()
current_stamp = int(time.time())

# Calculate the signature for the request
def calculate_signature(timestamp, secret):
    string_to_sign = f"{timestamp}\n{secret}"
    hmac_code = hmac.new(string_to_sign.encode("utf-8"), digestmod=hashlib.sha256)
    sign = base64.b64encode(hmac_code.digest()).decode('utf-8')
    return sign

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
     # Construct the alert message
    sign = calculate_signature(str(current_stamp), "<feishu_url_sign>")
    print(sign)

    if event is not None:
        print(event) 
        customer_name = event['customer_name']
        payload = event['payload']
        vmanage_time = event['entry_time']

        # Get the desired info in the vmanage alert record
        host_name = payload['values'][0]['host-name']
        alert_msg = payload['message']
        severity = payload['severity']
        component = payload['component']
        alert_time = convert_time(vmanage_time)

        feishu_msg = {
            "timestamp": str(current_stamp),
            "sign": sign,
            "msg_type": "post",
            "content": {
                "post": {
                    "zh_cn": {
                        "title": "Cisco Alarm Notification",
                        "content": [
                            [
                                {
                                    "tag": "text",
                                    "text": customer_name+'\n'+'Alert: '+alert_msg+'\n'+'Device: '+host_name+'\n'+'Alert Time: '+alert_time + ' HKT'
                                },
                                {
                                    "tag": "at",
                                    "user_id": "all"
                                }
                            ]
                        ]
                    }
                }
            },
        }

        # Send the alert message to feishu webhook URL
        feishu_response = http.request(
            "POST", 
            feishu_webhook_url, 
            body=json.dumps(feishu_msg),
            headers={"Content-Type": "application/json"}
        )

        return {
            'statusCode': 200,
            'body': json.dumps('Messages sent!')
        }
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('No records found')
        } 
