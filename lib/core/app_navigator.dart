import 'package:flutter/widgets.dart';

/// Chave global do Navigator raiz — permite navegar sem `BuildContext`
/// (ex.: o interceptor do dio rotear para o login quando a sessão expira).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
