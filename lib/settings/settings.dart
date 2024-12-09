import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tomo/app_state.dart';

import 'package:tomo/content_root.dart';
import 'package:tomo/settings/auth.dart';
import 'package:tomo/settings/timers.dart';
import 'package:tomo/svg_icon.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const EditTimers(),
    ];
    if (AppState.syncEnabled) {
      children.add(const SizedBox(height: 30));
      children.add(const Auth());
    }
    return Scaffold(
      body: ContentRoot(
        children: children,
      ),
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Quit',
              color: Colors.white,
              icon: const SvgIcon("leave"),
              onPressed: () {
                exit(0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
