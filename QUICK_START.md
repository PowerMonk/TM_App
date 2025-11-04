# ⚡ QUICK START - TM Face Recognizer

## 📋 3-Minute Setup

### 1️⃣ Setup Ngrok (First Time Only)

```bash
# Terminal 1: Start Node-RED
node-red

# Terminal 2: Start ngrok
ngrok http 1880
```

**Copy the HTTPS URL** from ngrok output (e.g., `https://abc123.ngrok.io`)

### 2️⃣ Update App

Open `lib/camera_screen.dart` → Line ~25:

```dart
final String ngrokUrl = "https://abc123.ngrok.io";  // ← YOUR URL HERE
```

### 3️⃣ Import Node-RED Flow

1. Open http://localhost:1880
2. Menu → Import → Select `node-red-flow.json`
3. Click Deploy

### 4️⃣ Run App

```bash
flutter run
```

### 5️⃣ Test!

- Grant camera permission
- Take a picture of Karol or Cachi
- Check Node-RED debug panel!

---

## 🔄 Daily Use (After First Setup)

```bash
# Terminal 1
node-red

# Terminal 2
ngrok http 1880
# ⚠️ If URL changed, update camera_screen.dart

# Terminal 3
flutter run
```

---

## 🎯 Expected Flow

```
[Flutter App]
    📸 Take Picture
    ↓
[TFLite Model]
    🧠 Recognize: "Karol" or "Cachi"
    ↓
[HTTP GET Request]
    📡 https://your-ngrok.io/persona?nombre=Karol
    ↓
[Node-RED]
    📥 Receives name
    ↓
[Alexa/Response]
    🗣️ "Bienvenido Karol"
```

---

## ⚠️ Common Issues

| Problem              | Solution                                  |
| -------------------- | ----------------------------------------- |
| "NGROK URL NOT SET!" | Update `ngrokUrl` in `camera_screen.dart` |
| Camera not working   | Grant permission, use physical device     |
| HTTP fails           | Check ngrok is running, verify URL        |
| Model not loading    | Run `flutter clean && flutter pub get`    |

---

## 📞 Need Help?

Check:

- `README.md` - Full setup guide
- `NGROK_SETUP.md` - Detailed ngrok instructions
- `node-red-flow.json` - Pre-configured flow

---

**💡 Pro Tip:** Use paid ngrok for a permanent URL so you don't have to update the app every time!
