import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyDhRLD5muOXPFCQhXtcqYv5PXnecCakJ1Y';
  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models?key=\$apiKey',
  );
  final response = await HttpClient().getUrl(url).then((req) => req.close());
  final body = await response.transform(utf8.decoder).join();
  print(body);
}
