import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Shared fade + gentle rise used by [SoftPageRoute] and theme builders.
Widget buildSoftPageTransition({
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required Widget child,
}) {
  final incoming = CurvedAnimation(
    parent: animation,
    curve: AppConstants.pageCurve,
    reverseCurve: AppConstants.pageReverseCurve,
  );
  final outgoing = CurvedAnimation(
    parent: secondaryAnimation,
    curve: AppConstants.pageCurve,
    reverseCurve: AppConstants.pageReverseCurve,
  );

  return FadeTransition(
    opacity: Tween<double>(begin: 0, end: 1).animate(incoming),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(incoming),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.92).animate(outgoing),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -0.012),
          ).animate(outgoing),
          child: child,
        ),
      ),
    ),
  );
}

/// Soft fade/slide route for push/pop navigations.
class SoftPageRoute<T> extends PageRouteBuilder<T> {
  SoftPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: AppConstants.pageTransition,
          reverseTransitionDuration: AppConstants.pageReverseTransition,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return buildSoftPageTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );
}

/// Applies [buildSoftPageTransition] to platform [MaterialPageRoute]s via theme.
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildSoftPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

Future<T?> pushSoft<T extends Object?>(
  BuildContext context,
  Widget page, {
  bool fullscreenDialog = false,
}) {
  return Navigator.of(context).push<T>(
    SoftPageRoute<T>(
      builder: (_) => page,
      fullscreenDialog: fullscreenDialog,
    ),
  );
}

Future<T?> showSoftModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  bool useRootNavigator = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor,
    useRootNavigator: useRootNavigator,
    showDragHandle: false,
    sheetAnimationStyle: AnimationStyle(
      duration: AppConstants.pageTransition,
      reverseDuration: AppConstants.pageReverseTransition,
      curve: AppConstants.pageCurve,
      reverseCurve: AppConstants.pageReverseCurve,
    ),
    builder: builder,
  );
}
