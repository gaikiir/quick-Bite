@echo off
cd /d "C:\Users\%USERNAME%\Desktop\webdev\android_dev\quick_bite"
echo 🚀 Starting M-Pesa Proxy Server...
echo 📱 This server handles CORS issues for M-Pesa integration
echo 🌐 Server will be available at: http://localhost:5000
echo 🔗 Set proxyUrl in MpesaConfig to: http://localhost:5000/api/mpesa
echo 💡 For production, deploy this to a cloud service
echo.
"C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python311\python.exe" mpesa_proxy_server.py
pause