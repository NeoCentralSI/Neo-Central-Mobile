/// Parses decimal input accepted by the yudisium backend and web client.
///
/// Both `12.5` and Indonesian `12,5` are accepted. Thousands separators such
/// as `1.234,5` are normalized before parsing.
num? parseIndonesianSurveyNumber(String value) {
  final text = value.trim();
  if (text.isEmpty) return null;
  final direct = num.tryParse(text);
  if (direct != null) return direct;
  return num.tryParse(text.replaceAll('.', '').replaceAll(',', '.'));
}
