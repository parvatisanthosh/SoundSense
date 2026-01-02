import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class SoundClassifierSleep {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isLoaded = false;

  static final SoundClassifierSleep _instance = SoundClassifierSleep._internal();
  factory SoundClassifierSleep() => _instance;
  SoundClassifierSleep._internal();

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      // Load the model
      final options = InterpreterOptions();
      // Add delegate creation here if necessary (e.g. GPU, NNAPI)
      
      _interpreter = await Interpreter.fromAsset('assets/models/critical_sounds.tflite', options: options);
      
      // Load labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n');
      
      _isLoaded = true;
      print("Sleep Mode Model loaded successfully");
    } catch (e) {
      print("Error loading sleep mode model: $e");
    }
  }

  Future<String?> classify(List<double> audioData) async {
    if (!_isLoaded || _interpreter == null) {
      await loadModel();
      if (!_isLoaded) return null;
    }

    try {
      // Data preprocessing would go here (e.g., FFT, spectrogram)
      // This is a placeholder as the specific input tensor shape depends on the model training
      // For now we assume the model takes a specific input size
      
      // Input: [1, input_size]
      // Output: [1, num_classes]
      
      // Note: Real implementation depends on the expected input of 'critical_sounds.tflite'
      var input = [audioData]; 
      var output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

      _interpreter!.run(input, output);

      // Find the label with the highest probability
      // Find the label with the highest probability
      double maxProb = 0.0;
      int maxIndex = -1;
      final probabilities = output[0];
      
      // Debug print all non-zero probs
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > 0.1) {
           print("  Label: ${_labels![i]}, Prob: ${probabilities[i]}");
        }
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      print("Top detection: ${maxIndex != -1 ? _labels![maxIndex] : 'None'} ($maxProb)");

      // Lower threshold for testing
      if (maxProb > 0.35 && maxIndex != -1) {
        return _labels![maxIndex];
      }
      
    } catch (e) {
      print("Inference error: $e");
    }
    return null;
  }
  
  void close() {
    _interpreter?.close();
    _isLoaded = false;
  }
}
