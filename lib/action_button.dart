import 'package:flutter/material.dart';

import 'package:tomo/inner_shadow.dart';
import 'package:tomo/theme.dart';

const actionButtonBorderRadius = 6.0;
final _borderRadius = BorderRadius.circular(actionButtonBorderRadius);
const _bezelHeight = 4.0;
const _bezelPressedHeight = 1.0;

class ActionButton extends StatefulWidget {
  const ActionButton({
    super.key,
    this.left,
    required this.center,
    this.right,
    this.color = grayColor,
    this.textColor = grayTextColor,
    this.minHeight = 55,
    this.backgroundDecoration,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
  });

  final void Function()? onPressed;
  final Widget? left;
  final Widget center;
  final Widget? right;
  final Color color;
  final Color textColor;
  final double minHeight;
  final Decoration? backgroundDecoration;
  final EdgeInsets padding;

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool isHovering = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pressable = widget.onPressed != null;
    return Container(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      padding: EdgeInsets.only(
          top: isPressed ? _bezelHeight - _bezelPressedHeight : 0),
      child: Container(
        padding: EdgeInsets.only(
            bottom: isPressed ? _bezelPressedHeight : _bezelHeight),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: _borderRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: _borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(pressable ? 0.3 : 0),
                offset:
                    Offset(0, isPressed ? _bezelPressedHeight : _bezelHeight),
                blurRadius: 0,
              ),
            ],
          ),
          child: InnerShadow(
            shadows: [
              if (pressable)
                Shadow(
                    color: Colors.white.withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 1),
            ],
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: _borderRadius,
              ),
              child: Container(
                decoration: pressable
                    ? BoxDecoration(
                        borderRadius: _borderRadius,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomLeft,
                          colors: [
                            Colors.black.withOpacity(isHovering ? 0.20 : 0.15),
                            Colors.black.withOpacity(isHovering ? 0.05 : 0)
                          ],
                        ),
                      )
                    : null,
                child: Container(
                  decoration: widget.backgroundDecoration,
                  child: InkWell(
                    onTapDown: pressable
                        ? (_) => setState(() {
                              isPressed = true;
                            })
                        : null,
                    onTapUp: pressable
                        ? (_) => setState(() {
                              isPressed = false;
                            })
                        : null,
                    onTap: widget.onPressed,
                    onTapCancel: pressable
                        ? () => setState(() {
                              isPressed = false;
                            })
                        : null,
                    onHover: pressable
                        ? (hover) => setState(() {
                              isHovering = hover;
                            })
                        : null,
                    customBorder: RoundedRectangleBorder(
                      borderRadius: _borderRadius,
                    ),
                    child: Padding(
                      padding: widget.padding,
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        child: IconTheme(
                          data: IconThemeData(color: widget.textColor),
                          child: Stack(
                            fit: StackFit.passthrough,
                            children: [
                              Container(
                                alignment: Alignment.center,
                                child: widget.center,
                              ),
                              if (widget.left != null)
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: widget.left, // child: Align(
                                ),
                              if (widget.right != null)
                                Container(
                                  alignment: Alignment.centerRight,
                                  child: widget.right!,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
