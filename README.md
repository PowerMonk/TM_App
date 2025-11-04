# 🎯 TM Face Recognizer - Complete Setup Guide

## 📱 Your App is Ready!

I've set up your Flutter app to recognize **Karol** and **Cachi** using your Teachable Machine model. Here's what I did:

### ✅ Changes Made

1. **Updated `lib/main.dart`**

   - Now launches directly to the camera screen
   - Clean, simple interface

2. **Rewrote `lib/camera_screen.dart`**

   - ✅ Loads TFLite model from assets
   - ✅ Initializes front camera (camera[1])
   - ✅ Takes pictures and runs inference
   - ✅ Displays recognition results with confidence percentages
   - ✅ Sends the top result to your ngrok endpoint
   - ✅ Better error handling and UI feedback
   - ✅ Shows loading states

3. **Updated `android/app/src/main/AndroidManifest.xml`**

   - ✅ Added CAMERA permission
   - ✅ Added INTERNET permission
   - ✅ Added storage permissions
   - ✅ Added camera features

4. **Updated `android/app/build.gradle.kts`**

   - ✅ Set minSdk to 21 (required for camera & tflite)

5. **Assets are already configured in `pubspec.yaml`**

   - ✅ model.tflite
   - ✅ labels.txt

6. **Dependencies installed:**
   - ✅ tflite: ^1.1.2
   - ✅ camera: ^0.11.2+1
   - ✅ http: ^1.5.0

---

## 🚀 HOW TO RUN

### Step 1: Configure Ngrok URL

**IMPORTANT:** Open `lib/camera_screen.dart` and find line ~25:

```dart
final String ngrokUrl = "YOUR_NGROK_URL_HERE";
```

Replace it with your actual ngrok URL (see ngrok setup below).

### Step 2: Run the App

```bash
flutter run
```

Or press F5 in VS Code with your Android device connected.

### Step 3: Grant Permissions

When the app starts, it will ask for camera permission. **Accept it!**

### Step 4: Take a Picture

- Point the camera at Karol or Cachi
- Press "Tomar Foto" button
- The app will:
  1. Capture the image
  2. Run it through the TFLite model
  3. Show the recognition result
  4. Send the name to your ngrok endpoint

---

## 🌐 NGROK SETUP (for Node-RED connection)

### What You Need:

1. **Node-RED** running locally (usually on port 1880)
2. **Ngrok** to expose Node-RED to the internet

### Quick Setup:

#### 1. Install Ngrok

Download from: https://ngrok.com/download

#### 2. Start Node-RED

```bash
node-red
```

#### 3. Start Ngrok Tunnel

In a new terminal:

```bash
ngrok http 1880
```

You'll see output like:

```
Forwarding    https://abc123.ngrok.io -> http://localhost:1880
```

#### 4. Copy the HTTPS URL

Example: `https://abc123.ngrok.io`

#### 5. Update Flutter App

In `lib/camera_screen.dart`, line ~25:

```dart
final String ngrokUrl = "https://abc123.ngrok.io";
```

**⚠️ IMPORTANT:**

- Use HTTPS (not HTTP)
- NO trailing slash
- NO `/persona` at the end

#### 6. Import Node-RED Flow

1. Open Node-RED: http://localhost:1880
2. Click the hamburger menu (top right) → Import
3. Select the `node-red-flow.json` file from this project
4. Click Deploy

**OR** create manually:

- HTTP IN node → URL: `/persona`, Method: GET
- Function node → Code:
  ```javascript
  const nombre = msg.req.query.nombre || "Desconocido";
  msg.payload = \`Bienvenido \${nombre}\`;
  return msg;
  ```
- Debug node (to see messages)
- HTTP Response node (status 200)

#### 7. Test!

Run your app, take a picture, and check Node-RED debug panel!

---

## 📊 Expected Behavior

### App Flow:

1. App starts → Loads model → Initializes camera
2. User presses "Tomar Foto"
3. Model analyzes image
4. Shows: "Reconocido: Karol (87.5%)" (example)
5. Sends HTTP GET: `https://your-ngrok.io/persona?nombre=Karol`
6. Node-RED receives and processes

### Recognition Labels:

- **0 Karol** → Sends "Karol"
- **1 Cachi** → Sends "Cachi"

The app automatically strips the number prefix and sends only the name.

---

## 🐛 Troubleshooting

### "NGROK URL NOT SET!" in console

→ Update `ngrokUrl` in `camera_screen.dart`

### Camera not working

→ Grant camera permission
→ Use a physical device (emulators have limited camera support)

### Model not loading

→ Check assets are in: `assets/converted_tflite_quantized/`
→ Run `flutter pub get`
→ Try `flutter clean` then `flutter run`

### HTTP request fails

→ Check ngrok is running
→ Verify URL format (HTTPS, no trailing slash)
→ Check Node-RED is running
→ Test ngrok URL in browser: `https://your-url.ngrok.io/persona?nombre=test`

### App crashes on startup

→ Check Android device is connected: `flutter devices`
→ Check minSdk is 21 (already set)
→ Try `flutter clean`

---

## 📁 Project Structure

```
tm_app/
├── lib/
│   ├── main.dart              # App entry point
│   └── camera_screen.dart     # Main screen (UPDATE NGROK URL HERE!)
├── assets/
│   └── converted_tflite_quantized/
│       ├── model.tflite       # Your TM model
│       └── labels.txt         # Karol, Cachi
├── android/                   # Android-specific config
├── pubspec.yaml              # Dependencies
├── NGROK_SETUP.md            # Detailed ngrok guide
├── node-red-flow.json        # Import this to Node-RED
└── README.md                 # This file
```

---

## 🎯 Quick Start Checklist

- [ ] Update `ngrokUrl` in `lib/camera_screen.dart`
- [ ] Start Node-RED: `node-red`
- [ ] Start ngrok: `ngrok http 1880`
- [ ] Import `node-red-flow.json` to Node-RED
- [ ] Connect Android device
- [ ] Run: `flutter run`
- [ ] Grant camera permission
- [ ] Take a picture of Karol or Cachi
- [ ] Check Node-RED debug panel for the greeting!

---

## 🔗 Connect to Alexa

Once Node-RED receives the name, you can:

1. Install Alexa nodes in Node-RED (if not already)
2. Connect the function output to Alexa node
3. Configure Alexa to speak: "Bienvenido [nombre]"

For Alexa setup, check Node-RED Alexa documentation or use a simulator.

---

## 💡 Tips

- **Better Recognition:** Take pictures in good lighting
- **Front Camera:** App uses camera[1] by default (front camera)
- **Confidence:** App shows percentage confidence for each recognition
- **Free Ngrok:** Free tier gives you a new URL each time you restart
- **Paid Ngrok:** Get a static URL so you don't have to update the app

---

## 📝 Notes

- This app is **Android-only** as requested
- Model recognizes between Karol and Cachi
- Uses the highest confidence prediction
- Sends via HTTP GET to Node-RED
- All permissions and dependencies are configured

---

## 🎉 You're All Set!

The app is ready to go. Just:

1. Set your ngrok URL
2. Run the app
3. Take pictures!

Check `NGROK_SETUP.md` for detailed ngrok instructions.

Happy coding! 🚀
