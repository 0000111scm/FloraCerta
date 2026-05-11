import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_routes.dart';

AppBar buildFloraAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    leading: IconButton(
      tooltip: 'Voltar',
      onPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(AppRoutes.home);
      },
      icon: const Icon(Icons.arrow_back_rounded),
    ),
    title: Text(title),
    actions: actions,
  );
}
