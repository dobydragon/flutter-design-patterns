// State (GoF) vs enum status — Leave request workflow
// Run: dart run 12_state_leave_request.dart
//
// Many apps use enum statuses (e.g. AuthUiStatus { idle, loading, success, error }).
// That is fine for UI status. The GoF State pattern pays off when each state
// has DIFFERENT allowed actions.

// ---------------------------------------------------------------------------
// BEFORE: enum + switch in every method. Rules are scattered.
// ---------------------------------------------------------------------------
enum LeaveStatus { draft, submitted, approved, rejected }

class BeforeLeaveRequest {
  LeaveStatus status = LeaveStatus.draft;

  void submit() {
    if (status != LeaveStatus.draft) throw StateError('Only drafts can be submitted');
    status = LeaveStatus.submitted;
  }

  void approve() {
    if (status != LeaveStatus.submitted) throw StateError('Only submitted can be approved');
    status = LeaveStatus.approved;
  }

  void cancel() {
    // Easy to forget a case: should an approved leave be cancellable?
    if (status == LeaveStatus.rejected) throw StateError('Already rejected');
    status = LeaveStatus.draft;
  }
}

// ---------------------------------------------------------------------------
// AFTER: each state is an object that decides what each action does.
// ---------------------------------------------------------------------------
sealed class LeaveState {
  const LeaveState();

  String get label;
  LeaveState submit() => throw StateError('Cannot submit when $label');
  LeaveState approve() => throw StateError('Cannot approve when $label');
  LeaveState reject() => throw StateError('Cannot reject when $label');
  LeaveState cancel() => throw StateError('Cannot cancel when $label');
}

class Draft extends LeaveState {
  const Draft();

  @override
  String get label => 'Draft';

  @override
  LeaveState submit() => const Submitted();
}

class Submitted extends LeaveState {
  const Submitted();

  @override
  String get label => 'Submitted';

  @override
  LeaveState approve() => const Approved();

  @override
  LeaveState reject() => const Rejected();

  @override
  LeaveState cancel() => const Draft();
}

class Approved extends LeaveState {
  const Approved();

  @override
  String get label => 'Approved';
}

class Rejected extends LeaveState {
  const Rejected();

  @override
  String get label => 'Rejected';
}

class LeaveRequest {
  LeaveState _state = const Draft();

  String get status => _state.label;

  void submit() => _state = _state.submit();
  void approve() => _state = _state.approve();
  void reject() => _state = _state.reject();
  void cancel() => _state = _state.cancel();
}

void main() {
  final before = BeforeLeaveRequest()
    ..submit()
    ..approve()
    ..cancel(); // bug: approved leave silently went back to draft
  print('Before → ${before.status.name} (should not be allowed)');

  final leave = LeaveRequest()
    ..submit()
    ..approve();
  print('After  → ${leave.status}');
  try {
    leave.cancel();
  } on StateError catch (e) {
    print('After  → ${e.message}');
  }
}
