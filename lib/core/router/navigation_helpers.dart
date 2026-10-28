import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Returns to the previous route, or to the home tab when opened directly.
void goBackOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}
