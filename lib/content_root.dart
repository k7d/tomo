import 'package:flutter/material.dart';

import 'package:tomo/platform.dart' as platform;
import 'package:tomo/theme.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class ContentRoot extends StatefulWidget {
  final List<Widget> children;

  const ContentRoot({
    super.key,
    required this.children,
  });

  @override
  State<ContentRoot> createState() => _ContentRoot();
}

class _ContentRoot extends State<ContentRoot> with RouteAware {
  final GlobalKey _contentKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    _syncContentSize();
  }

  @override
  void didPopNext() {
    _syncContentSize();
  }

  bool _syncContentSize() {
    final contentSize = _contentKey.currentContext?.size;
    if (contentSize == null) {
      return false;
    }
    final appBarHeight = Scaffold.of(context).appBarMaxHeight;
    platform.setContentHeight(contentSize.height + (appBarHeight ?? 0));
    return true;
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncContentSize();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final hasAppBar = Scaffold.of(context).appBarMaxHeight != null;
    return SingleChildScrollView(
        child: NotificationListener(
            onNotification: (SizeChangedLayoutNotification notification) {
              if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                return _syncContentSize();
              } else {
                return false;
              }
            },
            child: SizeChangedLayoutNotifier(
                child: Container(
                    key: _contentKey,
                    padding: hasAppBar
                        ? const EdgeInsets.only(
                            top: 10, bottom: 30, left: 30, right: 30)
                        : const EdgeInsets.all(30),
                    child: DefaultTextStyle(
                        style: labelTextStyle,
                        textAlign: TextAlign.center,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: widget.children))))));
  }
}

class NavButton extends IconButton {
  NavButton({
    super.key,
    required super.onPressed,
    required Icon icon,
    super.tooltip,
  }) : super(
          icon: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect bounds) => const LinearGradient(
              begin: Alignment(0, 0),
              end: Alignment(0, 1),
              colors: [Color(0xFF9B9B99), Color(0xFFB1B1AF)],
            ).createShader(bounds),
            child: icon,
          ),
          iconSize: 20,
          color: Colors.black,
        );
}

class NavButtonLocation implements FloatingActionButtonLocation {
  final Offset Function(ScaffoldPrelayoutGeometry scaffoldGeometry) _getOffset;

  NavButtonLocation(this._getOffset);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return _getOffset(scaffoldGeometry);
  }

  static final topRight = NavButtonLocation((scaffoldGeometry) => Offset(
        scaffoldGeometry.scaffoldSize.width - 40,
        0,
      ));

  static final bottomRight = NavButtonLocation((scaffoldGeometry) => Offset(
        scaffoldGeometry.scaffoldSize.width - 40,
        scaffoldGeometry.scaffoldSize.height - 40,
      ));
}
