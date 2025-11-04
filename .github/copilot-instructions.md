# Project: TM Face Recognizer (Flutter + Node-RED + Alexa)

## Objective

Create a Flutter app that uses a TensorFlow Lite model exported from Teachable Machine
to classify images from the camera, send the result to Node-RED, and trigger Alexa
to say a personalized greeting.

## Tasks

1. Add model to assets:
   - assets/converted_tflite_quantized/model.tflite
   - assets/converted_tflite_quantized/labels.txt
2. Update pubspec.yaml to include these assets.
3. Install dependencies:
   flutter pub add tflite camera http
4. Build CameraScreen:
   - Load TFLite model.
   - Initialize camera.
   - On photo capture, run model inference.
   - Get top label and send to Node-RED using an HTTP GET request:
     http://<ngrok-url>/persona?nombre=<label>
5. Build simple Node-RED flow:
   - HTTP IN node (/persona)
   - Function node: create message “Bienvenido <label>”
   - Alexa node / simulator output.
6. Expose Node-RED port with ngrok.
7. Test full flow: Flutter → Node-RED → Alexa (simulator).

## Notes

- Use the TFLite export from Teachable Machine (not JS version).
- Use camera[1] for the front camera.
- Display recognition result under the camera preview.
- Keep code clean and reactive with setState().
