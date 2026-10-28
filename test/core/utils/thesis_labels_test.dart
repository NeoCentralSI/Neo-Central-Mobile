import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/utils/thesis_labels.dart';

void main() {
  test('Jenis badge uses the web labels', () {
    expect(thesisPhaseLabel('proposal'), 'Proposal');
    expect(thesisPhaseLabel('research'), 'Penelitian');
    expect(thesisPhaseLabel('other'), '-');
    expect(thesisPhaseLabel(null), '-');
  });

  test('thesis status labels', () {
    expect(thesisStatusLabel('proposal'), 'Proposal');
    expect(thesisStatusLabel('research'), 'Penelitian');
    expect(thesisStatusLabel('completed'), 'Selesai');
    expect(thesisStatusLabel('failed'), 'Gagal');
    expect(thesisStatusLabel('on_leave'), '-');
  });
}
