// Service Locator vs Dependency Injection — User permissions
// Run: dart run 05_service_locator_vs_di.dart
//
// In Flutter: context.read<T>() inside Screen.builder() is a *locate* step,
// then the Cubit receives everything through its constructor (DI).

class PermissionService {
  PermissionService(this.role);

  final String role;

  bool canApproveLeave() => role == 'manager' || role == 'hr';
}

// A tiny locator (what get_it does, in 15 lines).
class Locator {
  static final Map<Type, Object> _registry = {};

  static void register<T extends Object>(T instance) => _registry[T] = instance;

  static T get<T extends Object>() {
    final found = _registry[T];
    if (found == null) throw StateError('$T is not registered');
    return found as T;
  }
}

// ---------------------------------------------------------------------------
// Service Locator style: the class PULLS its dependency. Hidden dependency —
// you only discover it when it crashes at runtime.
// ---------------------------------------------------------------------------
class LeaveApprovalViewModelSL {
  bool get showApproveButton => Locator.get<PermissionService>().canApproveLeave();
}

// ---------------------------------------------------------------------------
// DI style: the dependency is PUSHED in. Visible in the constructor.
// ---------------------------------------------------------------------------
class LeaveApprovalViewModelDI {
  LeaveApprovalViewModelDI(this._permissions);

  final PermissionService _permissions;

  bool get showApproveButton => _permissions.canApproveLeave();
}

void main() {
  try {
    LeaveApprovalViewModelSL().showApproveButton;
  } on StateError catch (e) {
    print('SL before registration → crash at runtime: ${e.message}');
  }

  Locator.register(PermissionService('employee'));
  print('SL  → ${LeaveApprovalViewModelSL().showApproveButton}');

  // DI: you can't even build it without giving the dependency (compile-time).
  print('DI  → ${LeaveApprovalViewModelDI(PermissionService('manager')).showApproveButton}');

  // Common Flutter compromise (what many apps do): locate once at the edge,
  // then inject.
  final vm = LeaveApprovalViewModelDI(Locator.get<PermissionService>());
  print('Locate at the edge + inject → ${vm.showApproveButton}');
}
