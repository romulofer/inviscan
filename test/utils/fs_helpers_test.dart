import 'package:flutter_test/flutter_test.dart';
import 'package:inviscan/widgets/scan_details/fs_helpers.dart';

void main() {
  group('isTextFile', () {
    test('verdadeiro para .txt', () => expect(isTextFile('subdomains.txt'), isTrue));
    test('verdadeiro para .log', () => expect(isTextFile('scan.log'), isTrue));
    test('verdadeiro para .json',
        () => expect(isTextFile('ffuf_output.json'), isTrue));
    test('falso para .png', () => expect(isTextFile('shot.png'), isFalse));
    test('falso para .csv', () => expect(isTextFile('data.csv'), isFalse));
    test('falso sem extensão', () => expect(isTextFile('Makefile'), isFalse));
    test('ignora maiúsculas/minúsculas', () {
      expect(isTextFile('FILE.TXT'), isTrue);
      expect(isTextFile('OUT.JSON'), isTrue);
    });
  });

  group('isImageFile', () {
    test('verdadeiro para .png', () => expect(isImageFile('shot.png'), isTrue));
    test('verdadeiro para .jpg', () => expect(isImageFile('shot.jpg'), isTrue));
    test('verdadeiro para .jpeg', () => expect(isImageFile('shot.jpeg'), isTrue));
    test('verdadeiro para .webp', () => expect(isImageFile('shot.webp'), isTrue));
    test('falso para .txt', () => expect(isImageFile('file.txt'), isFalse));
    test('falso para .gif', () => expect(isImageFile('anim.gif'), isFalse));
    test('falso sem extensão', () => expect(isImageFile('image'), isFalse));
    test('ignora maiúsculas/minúsculas', () {
      expect(isImageFile('SHOT.PNG'), isTrue);
      expect(isImageFile('PHOTO.JPEG'), isTrue);
    });
  });
}
