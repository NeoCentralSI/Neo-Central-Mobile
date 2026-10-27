import 'package:flutter/widgets.dart';

/// Root navigator of the app, used to open screens from outside the widget
/// tree (notification taps, the Microsoft sign-in page).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
