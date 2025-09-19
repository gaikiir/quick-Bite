# M-Pesa STK Push Configuration Fix

## Current Issue
User is not receiving STK push notifications on their mobile phone when attempting M-Pesa payments.

## Root Cause Analysis
1. **Invalid Callback URL**: The callback URL was set to Safaricom's sandbox query endpoint instead of a proper callback handler.
2. **Missing Proxy Server**: No proxy server configured for handling callbacks and CORS issues.
3. **Callback URL Not Publicly Accessible**: For M-Pesa to send callbacks, the URL must be publicly accessible.

## Completed Steps
- [x] Updated `lib/config/mpesa_config.dart` to use proxy server for callbacks
- [x] Set proxyUrl to `http://localhost:5000/api/mpesa` for local development

## Remaining Steps
- [ ] Install Python dependencies for proxy server
- [ ] Run the M-Pesa proxy server locally
- [ ] Make the callback URL publicly accessible (using ngrok or cloud deployment)
- [ ] Update callback URL in config with public URL
- [ ] Test STK push functionality
- [ ] Verify callback handling

## Instructions

### 1. Install Python Dependencies
```bash
pip install flask flask-cors requests
```

### 2. Run Proxy Server Locally
```bash
python mpesa_proxy_server.py
```

### 3. Make Callback URL Public (Using ngrok)
```bash
# Install ngrok if not already installed
# Expose local port 5000
ngrok http 5000
```

### 4. Update Config with Public URL
Replace `https://your-proxy-server.com` in `lib/config/mpesa_config.dart` with your ngrok URL:
```dart
static const String callbackUrl = 'https://abc123.ngrok.io/api/mpesa/callback';
```

### 5. Test the Integration
- Run your Flutter app
- Attempt an M-Pesa payment
- Check proxy server logs for callback reception
- Verify STK push appears on phone

## Alternative: Cloud Deployment
For production or persistent testing, deploy the proxy server to:
- Heroku
- Railway
- Vercel
- AWS/GCP/Azure

## Troubleshooting
- Ensure phone number is in correct format (254XXXXXXXXX)
- Verify sandbox credentials are correct
- Check network connectivity
- Monitor proxy server logs for errors
- Confirm ngrok tunnel is active

## Files Modified
- `lib/config/mpesa_config.dart`: Updated callback URL and proxy configuration
