import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Interpreter? _interpreter;
  List<String>? _labels;
  List<Map<String, dynamic>>? _output;
  bool _isModelLoaded = false;
  bool _isCameraReady = false;
  bool _isProcessing = false;
  String _statusMessage = 'Inicializando...';
  List<CameraDescription>? _cameras;
  int _currentCameraIndex = 1; // Start with front camera (index 1)

  // IMPORTANT: Replace this URL with your ngrok URL
  // Example: "https://abc123.ngrok.io"
  final String ngrokUrl =
      "https://jubilant-jacquline-unintimately.ngrok-free.dev";

  // Model input/output shape (adjust based on your Teachable Machine model)
  static const int INPUT_SIZE = 224; // Teachable Machine default
  static const int NUM_CLASSES = 2; // Karol and Cachi

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadModel();
    await _loadLabels();
    await _initCamera();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/converted_tflite_quantized/model.tflite',
      );
      setState(() {
        _isModelLoaded = true;
        _statusMessage = 'Modelo cargado. Cargando etiquetas...';
      });
      print('✅ Model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Input type: ${_interpreter!.getInputTensor(0).type}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('Output type: ${_interpreter!.getOutputTensor(0).type}');
    } catch (e) {
      setState(() {
        _statusMessage = 'Error cargando modelo: $e';
      });
      print('❌ Error loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString(
        'assets/converted_tflite_quantized/labels.txt',
      );
      _labels = labelsData
          .split('\n')
          .where((label) => label.isNotEmpty)
          .toList();

      // Remove index numbers from labels (e.g., "0 Karol" -> "Karol")
      _labels = _labels!.map((label) {
        if (label.contains(' ')) {
          return label.split(' ').skip(1).join(' ');
        }
        return label;
      }).toList();

      setState(() {
        _statusMessage = 'Etiquetas cargadas: ${_labels!.join(", ")}';
      });
      print('✅ Labels loaded: $_labels');
    } catch (e) {
      setState(() {
        _statusMessage = 'Error cargando etiquetas: $e';
      });
      print('❌ Error loading labels: $e');
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() {
          _statusMessage = 'No se encontraron cámaras';
        });
        return;
      }

      // Use front camera (index 1) if available, otherwise use first camera
      if (_currentCameraIndex >= _cameras!.length) {
        _currentCameraIndex = 0;
      }
      final camera = _cameras![_currentCameraIndex];

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _statusMessage = 'Listo! Presiona el botón para tomar foto';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error iniciando cámara: $e';
      });
      print('❌ Error initializing camera: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length <= 1) return;

    setState(() {
      _isCameraReady = false;
      _statusMessage = 'Cambiando cámara...';
    });

    await _controller?.dispose();

    // Toggle between cameras
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;

    _controller = CameraController(
      _cameras![_currentCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _statusMessage = 'Listo! Presiona el botón para tomar foto';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error cambiando cámara: $e';
      });
      print('❌ Error switching camera: $e');
    }
  }

  Future<List<List<List<List<int>>>>> _preprocessImage(String imagePath) async {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to model input size
    img.Image resizedImage = img.copyResize(
      image,
      width: INPUT_SIZE,
      height: INPUT_SIZE,
    );

    // Convert to input format (uint8: 0-255)
    var input = List.generate(
      1,
      (_) => List.generate(
        INPUT_SIZE,
        (y) => List.generate(INPUT_SIZE, (x) {
          var pixel = resizedImage.getPixel(x, y);
          return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
        }),
      ),
    );

    return input;
  }

  Future<void> _takePicture() async {
    if (!_isCameraReady || !_isModelLoaded || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Procesando imagen...';
    });

    try {
      final image = await _controller!.takePicture();

      // Preprocess image
      final input = await _preprocessImage(image.path);

      // Prepare output buffer (uint8 quantized output)
      var output = List.filled(
        1,
        List.filled(NUM_CLASSES, 0),
      ).map((e) => List<int>.from(e)).toList();

      // Run inference
      _interpreter!.run(input, output);

      print('🔍 Raw output: $output');

      // Process results - convert uint8 output (0-255) to confidence (0-1)
      List<Map<String, dynamic>> results = [];
      for (int i = 0; i < NUM_CLASSES; i++) {
        if (_labels != null && i < _labels!.length) {
          results.add({
            'label': _labels![i],
            'confidence': output[0][i] / 255.0, // Convert uint8 to probability
          });
        }
      }

      // Sort by confidence
      results.sort((a, b) => b['confidence'].compareTo(a['confidence']));

      setState(() {
        _output = results;
      });

      if (results.isNotEmpty) {
        String label = results[0]['label'];
        double confidence = results[0]['confidence'];

        setState(() {
          _statusMessage =
              'Reconocido: $label (${(confidence * 100).toStringAsFixed(1)}%)';
        });

        // Send to Node-RED via ngrok
        await _sendToNodeRed(label);
      } else {
        setState(() {
          _statusMessage = 'No se detectó ninguna persona';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
      print('❌ Error taking picture: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _sendToNodeRed(String label) async {
    if (ngrokUrl == "YOUR_NGROK_URL_HERE") {
      print('⚠️  NGROK URL NOT SET! Update ngrokUrl in camera_screen.dart');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$ngrokUrl/persona?nombre=$label"),
      );
      print('✅ HTTP Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = '$_statusMessage\n✅ Enviado a Node-RED';
        });
      }
    } catch (e) {
      print('❌ Error sending HTTP request: $e');
      setState(() {
        _statusMessage = 'Error enviando a Node-RED: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TM Face Recognizer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraReady && _controller != null
                ? Stack(
                    children: [
                      // 16:9 Camera Preview
                      Center(
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller!.value.previewSize!.height,
                                  height: _controller!.value.previewSize!.width,
                                  child: CameraPreview(_controller!),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Switch Camera Button
                      if (_cameras != null && _cameras!.length > 1)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            heroTag: 'switchCamera',
                            onPressed: _switchCamera,
                            backgroundColor: Colors.black54,
                            child: const Icon(
                              Icons.flip_camera_android,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                if (_output != null && _output!.isNotEmpty) ...[
                  const Divider(color: Colors.white54),
                  const Text(
                    'Resultados:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  ..._output!.map((result) {
                    String label = result['label'];
                    double confidence = result['confidence'];
                    return Text(
                      '$label: ${(confidence * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed:
                      (_isCameraReady && _isModelLoaded && !_isProcessing)
                      ? _takePicture
                      : null,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(_isProcessing ? 'Procesando...' : 'Tomar Foto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
