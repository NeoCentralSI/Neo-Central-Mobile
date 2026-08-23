import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/features/yudisium/presentation/utils/yudisium_survey_validation.dart';

void main() {
  group('parseIndonesianSurveyNumber', () {
    test('accepts integers and decimal points', () {
      expect(parseIndonesianSurveyNumber('42'), 42);
      expect(parseIndonesianSurveyNumber('12.5'), 12.5);
    });

    test('accepts decimal commas and Indonesian thousands separators', () {
      expect(parseIndonesianSurveyNumber('12,5'), 12.5);
      expect(parseIndonesianSurveyNumber('1.234,5'), 1234.5);
    });

    test('rejects empty and nonnumeric answers', () {
      expect(parseIndonesianSurveyNumber('  '), isNull);
      expect(parseIndonesianSurveyNumber('dua belas'), isNull);
    });
  });
}
