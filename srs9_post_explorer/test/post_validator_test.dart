import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/core/validation/post_validator.dart';

void main() {
  group('Post title validation', () {
    test('rejects null, empty and whitespace title', () {
      for (final v in <String?>[null, '', '     ']) {
        expect(PostValidator.title(v), isNotNull, reason: 'value: $v');
      }
    });
    test(
      'rejects 4 characters',
      () => expect(PostValidator.title('abcd'), isNotNull),
    );
    test(
      'accepts minimum 5 characters',
      () => expect(PostValidator.title('abcde'), isNull),
    );
    test(
      'accepts maximum 100 characters',
      () => expect(PostValidator.title('a' * 100), isNull),
    );
    test(
      'rejects 101 characters',
      () => expect(PostValidator.title('a' * 101), isNotNull),
    );
    test('trims before measuring length', () {
      expect(PostValidator.title('  abcde  '), isNull);
      expect(PostValidator.title('  abcd  '), isNotNull);
    });
  });
  group('Post body validation', () {
    test('rejects null, empty and whitespace body', () {
      for (final v in <String?>[null, '', '          ']) {
        expect(PostValidator.body(v), isNotNull);
      }
    });
    test(
      'rejects 9 characters',
      () => expect(PostValidator.body('a' * 9), isNotNull),
    );
    test(
      'accepts minimum 10 characters',
      () => expect(PostValidator.body('a' * 10), isNull),
    );
    test(
      'accepts maximum 1000 characters',
      () => expect(PostValidator.body('a' * 1000), isNull),
    );
    test(
      'rejects 1001 characters',
      () => expect(PostValidator.body('a' * 1001), isNotNull),
    );
  });
  group('Author validation', () {
    test('rejects missing or non-positive author ID', () {
      for (final id in <int?>[null, 0, -1]) {
        expect(PostValidator.author(id), isNotNull);
      }
    });
    test(
      'accepts positive author ID',
      () => expect(PostValidator.author(1), isNull),
    );
  });
}
