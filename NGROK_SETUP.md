# 🚀 Ngrok Setup Instructions

## What is Ngrok?

Ngrok creates a secure tunnel to your local Node-RED server, making it accessible from your Android device over the internet.

## Setup Steps

### 1. Install Ngrok

Download and install from: https://ngrok.com/download

### 2. Start Node-RED

Make sure Node-RED is running on your local machine (default port: 1880)

```bash
node-red
```

### 3. Create Ngrok Tunnel

In a new terminal, run:

```bash
ngrok http 1880
```

### 4. Copy the Ngrok URL

Ngrok will display something like:

```
Forwarding    https://abc123.ngrok.io -> http://localhost:1880
```

Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`)

### 5. Update the Flutter App

Open `lib/camera_screen.dart` and find this line (around line 25):

```dart
final String ngrokUrl = "YOUR_NGROK_URL_HERE";
```

Replace it with your ngrok URL:

```dart
final String ngrokUrl = "https://abc123.ngrok.io";
```

**IMPORTANT:** Use the URL WITHOUT the trailing slash and WITHOUT `/persona` path

### 6. Node-RED Flow Setup

Create this flow in Node-RED:

1. **HTTP IN node**

   - Method: GET
   - URL: `/persona`

2. **Function node** (connect to HTTP IN)

   - Name: Create Message
   - Code:

   ```javascript
   const nombre = msg.req.query.nombre || "Desconocido";
   msg.payload = `Bienvenido ${nombre}`;
   return msg;
   ```

3. **Debug node** (connect to Function) - to see the messages

4. **Alexa node** (if you have it installed) or **HTTP Response node**

   - For HTTP Response: set Status code to 200

5. Connect all nodes and deploy!

### 7. Test the Flow

1. Run the Flutter app on your Android device
2. Take a picture
3. Check Node-RED debug panel - you should see the recognized name!

## Expected Request Format

The app will send:

```
GET https://your-ngrok-url.ngrok.io/persona?nombre=Karol
```

## Troubleshooting

### ⚠️ Ngrok URL not set

If you see this in the console: `NGROK URL NOT SET!`

- Update the `ngrokUrl` variable in `camera_screen.dart`

### 🔴 HTTP Request fails

- Check that ngrok tunnel is running
- Verify the URL is correct (HTTPS, no trailing slash)
- Make sure Node-RED is running
- Check Node-RED has the `/persona` endpoint configured

### 📱 App crashes on startup

- Check camera permissions are granted
- Ensure you're running on a physical device (not all emulators support camera)

### 🎥 Camera not working

- Grant camera permission when prompted
- Check that your device has a front camera

## Quick Reference

**Run the complete setup:**

```bash
# Terminal 1: Start Node-RED
node-red

# Terminal 2: Start Ngrok
ngrok http 1880

# Update camera_screen.dart with the ngrok URL
# Run the Flutter app:
flutter run
```

## Recognition Labels

Your model recognizes:

- **Karol** (label 0)
- **Cachi** (label 1)

The app will automatically send the name with highest confidence to Node-RED!
