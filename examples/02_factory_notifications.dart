// Factory (Simple Factory + Dart factory constructor) — Notifications
// Run: dart run 02_factory_notifications.dart
//
// Typical Flutter shapes: NotificationTemplate.forKind(kind) and
// ServerFailure.fromCode(code).

// ---------------------------------------------------------------------------
// BEFORE: every caller builds the notification by hand.
// ---------------------------------------------------------------------------
void beforeDemo() {
  // In the leave-approval screen:
  final a = {'title': 'Leave approved', 'route': '/leave', 'icon': 'check'};
  // In the attendance screen (someone typed it slightly differently):
  final b = {'title': 'Attendance Missing', 'route': '/attendence', 'icon': 'warn'};
  print('Before → $a | $b   (typo in route, no single place to fix)');
}

// ---------------------------------------------------------------------------
// AFTER: one place decides how each kind is built.
// ---------------------------------------------------------------------------
enum NotificationKind { leaveApproved, attendanceMissing, payslipReady }

class AppNotification {
  const AppNotification._({
    required this.title,
    required this.route,
    required this.icon,
  });

  final String title;
  final String route;
  final String icon;

  /// Factory constructor: callers only say *what* they want.
  factory AppNotification.forKind(NotificationKind kind, {String? name}) {
    return switch (kind) {
      NotificationKind.leaveApproved => AppNotification._(
          title: 'Leave approved${name == null ? '' : ' for $name'}',
          route: '/leave',
          icon: 'check',
        ),
      NotificationKind.attendanceMissing => const AppNotification._(
          title: 'Attendance missing',
          route: '/attendance',
          icon: 'warn',
        ),
      NotificationKind.payslipReady => const AppNotification._(
          title: 'Your payslip is ready',
          route: '/payslip',
          icon: 'money',
        ),
    };
  }

  /// Factory constructor that parses data coming from Firestore / FCM.
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final kind = NotificationKind.values.firstWhere(
      (k) => k.name == map['kind'],
      orElse: () => NotificationKind.attendanceMissing,
    );
    return AppNotification.forKind(kind, name: map['name'] as String?);
  }

  @override
  String toString() => '[$icon] $title → $route';
}

void main() {
  beforeDemo();
  print(AppNotification.forKind(NotificationKind.leaveApproved, name: 'Ahmed'));
  print(AppNotification.fromMap({'kind': 'payslipReady'}));
  print(AppNotification.fromMap({'kind': 'unknown'})); // safe fallback
}
