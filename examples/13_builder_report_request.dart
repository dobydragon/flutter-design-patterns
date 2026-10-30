// Builder — Attendance report request with many optional parts
// Run: dart run 13_builder_report_request.dart
//
// Note: a screen's `static Widget builder(BuildContext)` on screens is a static
// FACTORY, not this pattern. BlocBuilder/LayoutBuilder are not GoF Builder either.

// ---------------------------------------------------------------------------
// BEFORE: a constructor with many positional/optional args.
// ---------------------------------------------------------------------------
class BeforeReportRequest {
  BeforeReportRequest(this.companyId, this.from, this.to, this.dept, this.onlyLate,
      this.includeWeekends, this.format);

  final String companyId;
  final DateTime from;
  final DateTime to;
  final String? dept;
  final bool onlyLate;
  final bool includeWeekends;
  final String format;
}

// ---------------------------------------------------------------------------
// AFTER: build step by step, validate once in build().
// ---------------------------------------------------------------------------
class ReportRequest {
  const ReportRequest._(this.query);

  final Map<String, String> query;

  @override
  String toString() => '/reports/attendance?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}';
}

class ReportRequestBuilder {
  ReportRequestBuilder(this._companyId);

  final String _companyId;
  DateTime? _from;
  DateTime? _to;
  String? _dept;
  bool _onlyLate = false;
  String _format = 'pdf';

  ReportRequestBuilder between(DateTime from, DateTime to) {
    _from = from;
    _to = to;
    return this;
  }

  ReportRequestBuilder department(String dept) {
    _dept = dept;
    return this;
  }

  ReportRequestBuilder onlyLateArrivals() {
    _onlyLate = true;
    return this;
  }

  ReportRequestBuilder asExcel() {
    _format = 'xlsx';
    return this;
  }

  ReportRequest build() {
    final from = _from, to = _to;
    if (from == null || to == null) throw StateError('Date range is required');
    if (to.isBefore(from)) throw StateError('"to" is before "from"');
    String d(DateTime x) => x.toIso8601String().substring(0, 10);
    return ReportRequest._({
      'company': _companyId,
      'from': d(from),
      'to': d(to),
      if (_dept != null) 'dept': _dept!,
      if (_onlyLate) 'late': 'true',
      'format': _format,
    });
  }
}

void main() {
  // Before: what do `true, false` mean? Easy to swap them by mistake.
  final b = BeforeReportRequest('acme', DateTime(2026, 1, 1), DateTime(2026, 1, 31), null, true, false, 'pdf');
  print('Before → onlyLate=${b.onlyLate} includeWeekends=${b.includeWeekends}');

  final request = ReportRequestBuilder('acme')
      .between(DateTime(2026, 1, 1), DateTime(2026, 1, 31))
      .department('HR')
      .onlyLateArrivals()
      .asExcel()
      .build();
  print('After  → $request');

  try {
    ReportRequestBuilder('acme').department('HR').build();
  } on StateError catch (e) {
    print('After  → ${e.message}');
  }
}
