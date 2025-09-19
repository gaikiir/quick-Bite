#!/usr/bin/env python3
"""
Simple M-Pesa Proxy Server for handling CORS issues
This server acts as a proxy between your Flutter web app and M-Pesa Daraja API

Usage:
1. Install dependencies: pip install flask flask-cors requests
2. Run: python mpesa_proxy_server.py
3. Set proxyUrl in MpesaConfig to 'http://localhost:5000/api/mpesa'

For production, deploy this to a cloud service like Heroku, Railway, or Vercel
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import base64
import json

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# M-Pesa API endpoints
MPESA_BASE_URL = 'https://sandbox.safaricom.co.ke'
AUTH_URL = f'{MPESA_BASE_URL}/oauth/v1/generate?grant_type=client_credentials'
STK_PUSH_URL = f'{MPESA_BASE_URL}/mpesa/stkpush/v1/processrequest'

@app.route('/api/mpesa/token', methods=['POST'])
def get_mpesa_token():
    """Proxy endpoint to get M-Pesa access token"""
    try:
        data = request.get_json()
        consumer_key = data.get('consumerKey')
        consumer_secret = data.get('consumerSecret')
        
        if not consumer_key or not consumer_secret:
            return jsonify({'error': 'Missing credentials'}), 400
        
        # Create Basic Auth credentials
        credentials = base64.b64encode(f'{consumer_key}:{consumer_secret}'.encode()).decode()
        
        # Make request to M-Pesa API
        headers = {
            'Authorization': f'Basic {credentials}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(AUTH_URL, headers=headers, timeout=30)
        
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({'error': f'M-Pesa API error: {response.status_code}'}), response.status_code
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/mpesa/stkpush', methods=['POST'])
def initiate_stk_push():
    """Proxy endpoint to initiate STK push"""
    try:
        data = request.get_json()
        
        # Extract data from request
        phone_number = data.get('phoneNumber')
        amount = data.get('amount')
        account_reference = data.get('accountReference')
        transaction_desc = data.get('transactionDesc')
        access_token = data.get('accessToken')
        
        if not all([phone_number, amount, account_reference, transaction_desc, access_token]):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # M-Pesa configuration (you should move these to environment variables)
        business_short_code = '174379'
        passkey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'
        callback_url = 'https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query'
        
        # Generate timestamp and password
        from datetime import datetime
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        password = base64.b64encode(f'{business_short_code}{passkey}{timestamp}'.encode()).decode()
        
        # Prepare STK push request
        stk_request = {
            'BusinessShortCode': business_short_code,
            'Password': password,
            'Timestamp': timestamp,
            'TransactionType': 'CustomerPayBillOnline',
            'Amount': amount,
            'PartyA': phone_number,
            'PartyB': business_short_code,
            'PhoneNumber': phone_number,
            'CallBackURL': callback_url,
            'AccountReference': account_reference,
            'TransactionDesc': transaction_desc
        }
        
        # Make request to M-Pesa API
        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json'
        }
        
        response = requests.post(STK_PUSH_URL, headers=headers, json=stk_request, timeout=30)
        
        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({'error': f'M-Pesa API error: {response.status_code}', 'details': response.text}), response.status_code
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/mpesa/callback', methods=['POST'])
def mpesa_callback():
    """Handle M-Pesa callback notifications"""
    try:
        data = request.get_json()
        print(f"📞 M-Pesa Callback received: {json.dumps(data, indent=2)}")
        
        # Process the callback data here
        # You can save to database, send notifications, etc.
        
        return jsonify({'ResultCode': 0, 'ResultDesc': 'Success'})
        
    except Exception as e:
        print(f"❌ Callback error: {str(e)}")
        return jsonify({'ResultCode': 1, 'ResultDesc': 'Error processing callback'}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'service': 'M-Pesa Proxy Server'})

if __name__ == '__main__':
    print("🚀 Starting M-Pesa Proxy Server...")
    print("📱 This server handles CORS issues for M-Pesa integration")
    print("🌐 Server will be available at: http://localhost:5000")
    print("🔗 Set proxyUrl in MpesaConfig to: http://localhost:5000/api/mpesa")
    print("💡 For production, deploy this to a cloud service")
    
    app.run(host='0.0.0.0', port=5000, debug=True)