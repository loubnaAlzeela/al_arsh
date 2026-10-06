import 'dart:io';

void main() async {
  final urls = [
    'https://storage.googleapis.com/exoplayer-test-media-1/mp4/android-screens-10s.mp4',
    'https://storage.googleapis.com/exoplayer-test-media-1/mp4/dizzy-with-tx3g.mp4'
  ];
  for (var u in urls) {
    var req = await HttpClient().headUrl(Uri.parse(u));
    var res = await req.close();
    print('$u : ${res.statusCode}');
  }
}
