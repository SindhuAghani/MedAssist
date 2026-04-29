import 'package:flutter/material.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/sizes.dart';


/// A container widget with rounded corners, shadows, borders, and customizable properties.
class TContainer extends StatelessWidget {
  /// Create a rounded container with flexible customization options.
  ///
  /// Parameters:
  ///   - width: The width of the container.
  ///   - height: The height of the container.
  ///   - borderRadius: The border radius for rounded corners.
  ///   - radius: Optional shorthand for border radius.
  ///   - padding: The internal padding of the container.
  ///   - margin: The external margin around the container.
  ///   - child: The widget to display inside the container.
  ///   - backgroundColor: The background color of the container.
  ///   - border: Optional custom border for the container.
  ///   - borderColor: The color of the border (used if `border` is not provided).
  ///   - showBorder: Whether to display the border.
  ///   - shadow: Optional custom shadow for the container.
  ///   - showShadow: Whether to display a default shadow.
  ///   - alignment: Align the child widget inside the container.
  ///   - onTap: Callback for tap gestures on the container.
  ///   - showRipple: Whether to show a ripple effect on tap.
  ///   - circle: Whether the container should be circular.
  const TContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.margin,
    this.padding,
    this.border,
    this.borderColor,
    this.showBorder = false,
    this.radius,
    this.borderRadius,
    this.backgroundColor,
    this.shadow,
    this.showShadow = false,
    this.alignment,
    this.onTap,
    this.showRipple = true,
    this.circular = false,
  });

  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final BoxBorder? border;
  final Color? borderColor;
  final bool showBorder;
  final double? radius;
  final BorderRadius? borderRadius;
  final BoxShadow? shadow;
  final bool showShadow;
  final AlignmentGeometry? alignment;
  final void Function()? onTap;
  final bool showRipple;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    // Adjust dimensions for a circular shape.
    final double? size = circular ? (width ?? height) : null;

    return Container(
      alignment: alignment,
      width: circular ? size : width,
      height: circular ? size : height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: circular
            ? BorderRadius.circular(size != null ? size / 2 : TSizes.borderRadiusLg)
            : borderRadius ?? BorderRadius.circular(radius ?? TSizes.borderRadiusLg),
        border: showBorder ? border ?? Border.all(color: borderColor ?? TColors.borderPrimary) : null,
        boxShadow: showShadow
            ? [
                shadow ??
                    BoxShadow(
                      spreadRadius: 2,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
              ]
            : [],
      ),
      child: (onTap != null)
          ? (showRipple)
              ? Material(
                  color: Colors.transparent,
                  borderRadius: circular
                      ? BorderRadius.circular(size != null ? size / 2 : TSizes.borderRadiusLg)
                      : borderRadius ?? BorderRadius.circular(radius ?? TSizes.borderRadiusLg),
                  child: InkWell(
                    borderRadius: circular
                        ? BorderRadius.circular(size != null ? size / 2 : TSizes.borderRadiusLg)
                        : borderRadius ?? BorderRadius.circular(radius ?? TSizes.borderRadiusLg),
                    splashColor: backgroundColor?.withValues(alpha: 0.2) ?? Colors.grey.withValues(alpha: 0.2),
                    highlightColor: backgroundColor?.withValues(alpha: 0.1) ?? Colors.grey.withValues(alpha: 0.1),
                    onTap: onTap,
                    child: Container(
                      margin: margin,
                      padding: padding ?? EdgeInsets.all(TSizes.md),
                      child: child,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: onTap,
                  child: Container(
                    margin: margin,
                    padding: padding ?? EdgeInsets.all(TSizes.md),
                    child: child,
                  ),
                )
          : Container(
              margin: margin,
              padding: padding ?? EdgeInsets.all(TSizes.md),
              child: child,
            ),
    );
  }
}
