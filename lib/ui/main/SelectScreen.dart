
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:smart_file_sync/src/config/AppData.dart';

class SelectScreen extends StatelessWidget {
  const SelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Theme.of(context).colorScheme.primary
                      ),
                      padding: EdgeInsets.all(5),
                      child: Wrap(
                        children: [
                          _SelectableItem(
                            onClick: (context) {
                              print('Open Chat');
                              context.goNamed('chat');
                            },
                          ),
                          _SelectableItem(
                            onClick: (context) {
                              print('Open File Send');
                              context.goNamed('send-file');
                            },
                          ),
                          _SelectableItem(
                            onClick: !kIsWeb ? (context) {
                              print('Open File Sync');
                              context.goNamed('sync-file');
                            } : null,
                          )
                        ],
                      )
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SelectableItem extends StatelessWidget {
  const _SelectableItem({
    this.backgroundColor,
    this.onClick,
    this.child,
    super.key,
  });

  final Color? backgroundColor;
  final Function(BuildContext context)? onClick;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SizedBox(
        width: 200,
        height: 200,
        child: Material(
          color: backgroundColor ?? Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: (onClick != null) ? () => onClick!(context) : null,
            child: child ?? Container(),
          ),
        ),
      ),
    );
  }
}
