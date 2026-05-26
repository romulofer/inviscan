import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/widgets/scan_details/fs_helpers.dart';

void main() {
  group('isTextFile', () {
    test('true for .txt', () => expect(isTextFile('subdomains.txt'), isTrue));
    test('true for .log', () => expect(isTextFile('scan.log'), isTrue));
    test('true for .json', () => expect(isTextFile('ffuf_output.json'), isTrue));
    test('false for .png', () => expect(isTextFile('shot.png'), isFalse));
    test('false for .csv', () => expect(isTextFile('data.csv'), isFalse));
    test('false for no extension', () => expect(isTextFile('Makefile'), isFalse));
    test('case-insensitive', () {
      expect(isTextFile('FILE.TXT'), isTrue);
      expect(isTextFile('OUT.JSON'), isTrue);
    });
  });

  group('isImageFile', () {
    test('true for .png', () => expect(isImageFile('shot.png'), isTrue));
    test('true for .jpg', () => expect(isImageFile('shot.jpg'), isTrue));
    test('true for .jpeg', () => expect(isImageFile('shot.jpeg'), isTrue));
    test('true for .webp', () => expect(isImageFile('shot.webp'), isTrue));
    test('false for .txt', () => expect(isImageFile('file.txt'), isFalse));
    test('false for .gif', () => expect(isImageFile('anim.gif'), isFalse));
    test('false for no extension', () => expect(isImageFile('image'), isFalse));
    test('case-insensitive', () {
      expect(isImageFile('SHOT.PNG'), isTrue);
      expect(isImageFile('PHOTO.JPEG'), isTrue);
    });
  });
}
