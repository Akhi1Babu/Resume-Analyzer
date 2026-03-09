import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final apiKey = 'AIzaSyDhRLD5muOXPFCQhXtcqYv5PXnecCakJ1Y';
  try {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final response = await model.generateContent([Content.text('Hello')]);
    print('Response: \${response.text}');
  } catch (e) {
    print('Error: \$e');
  }
}
