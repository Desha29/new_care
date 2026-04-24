// ignore_for_file: empty_catches

import 'dart:io';

void main() async {
  final fontDir = Directory('assets/fonts');
  if (!fontDir.existsSync()) {
    fontDir.createSync(recursive: true);
  }

  // Regular
  try {
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(
      Uri.parse(
        'https://fonts.gstatic.com/s/cairo/v28/SLXVc1nY6HkvalIPb6-3.ttf',
      ),
    );
    final response = await request.close();
    final file = File('assets/fonts/Cairo-Regular.ttf');
    await response.pipe(file.openWrite());
  } catch (e) {}

  // Bold
  try {
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(
      Uri.parse(
        'https://fonts.gstatic.com/s/cairo/v28/SLXWc1nY6HkvalIfbq2A6J0.ttf',
      ),
    );
    final response = await request.close();
    final file = File('assets/fonts/Cairo-Bold.ttf');
    await response.pipe(file.openWrite());
  } catch (e) {}
}
