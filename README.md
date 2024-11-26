## How Alert API work
1. The API gateway receive the alert message from cisco vManage or other system which can send standard cisco sdwan alerts, then the API gateway sends the message to backend
2. The backend integrate Lambda to resolve the alert message and send to different notification channels
3. The voice call notification rely on Amazon Connect to make outbound calls
4. All the received alert messages will be stored in DynamoDB