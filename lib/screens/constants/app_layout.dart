import 'package:flutter/material.dart';

class AppLayout {
  // Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;

  // Border Radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 32.0;

  // Card Elevations
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 16.0;

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Modern Container Decorations
  static BoxDecoration get modernCardDecoration {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radiusMd),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration modernGradientDecoration({
    required Color startColor,
    required Color endColor,
    double? radius,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, endColor],
      ),
      borderRadius: BorderRadius.circular(radius ?? radiusMd),
    );
  }

  // Modern Card Styles
  static CardTheme modernCardTheme(ThemeData theme) {
    return CardTheme(
      elevation: elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }

  // Modern Container Paddings
  static EdgeInsets get containerPadding => const EdgeInsets.all(md);
  static EdgeInsets get contentPadding => 
      const EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static EdgeInsets get listItemPadding =>
      const EdgeInsets.symmetric(horizontal: md, vertical: sm);

  // Responsive Grid
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return 1;
    if (width < tabletBreakpoint) return 2;
    if (width < desktopBreakpoint) return 3;
    return 4;
  }

  static double getGridItemWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = getGridCrossAxisCount(context);
    return (width - (md * (crossAxisCount + 1))) / crossAxisCount;
  }

  // Modern List Styles
  static double get modernListItemHeight => 72.0;
  static double get modernGridItemAspectRatio => 0.75;

  // Common Spacers
  static const Widget hSpaceXs = SizedBox(width: xs);
  static const Widget hSpaceSm = SizedBox(width: sm);
  static const Widget hSpaceMd = SizedBox(width: md);
  static const Widget hSpaceLg = SizedBox(width: lg);
  static const Widget hSpaceXl = SizedBox(width: xl);

  static const Widget vSpaceXs = SizedBox(height: xs);
  static const Widget vSpaceSm = SizedBox(height: sm);
  static const Widget vSpaceMd = SizedBox(height: md);
  static const Widget vSpaceLg = SizedBox(height: lg);
  static const Widget vSpaceXl = SizedBox(height: xl);

  // Modern Loading Gradient
  static LinearGradient get loadingGradient => LinearGradient(
        colors: const [
          Color(0xFFEBEBF4),
          Color(0xFFF4F4F4),
          Color(0xFFEBEBF4),
        ],
        stops: const [0.1, 0.3, 0.4],
        begin: const Alignment(-1.0, -0.3),
        end: const Alignment(1.0, 0.3),
        tileMode: TileMode.clamp,
      );
}

// Responsive Layout Widget

// Responsive Layout Widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppLayout.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= AppLayout.tabletBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

// Modern Card Widget
class ModernCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.color,
    this.elevation,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color ?? Theme.of(context).cardColor,
      elevation: elevation ?? AppLayout.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? AppLayout.containerPadding,
          child: child,
        ),
      ),
    );
  }
}

// Modern Grid Layout
class ModernGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final EdgeInsetsGeometry? padding;

  const ModernGrid({
    super.key,
    required this.children,
    this.spacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = AppLayout.getGridCrossAxisCount(context);
    final effectiveSpacing = spacing ?? AppLayout.md;

    return GridView.builder(
      padding: padding ?? EdgeInsets.all(effectiveSpacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: AppLayout.modernGridItemAspectRatio,
        crossAxisSpacing: effectiveSpacing,
        mainAxisSpacing: effectiveSpacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

// Modern List Item
class ModernListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const ModernListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      color: backgroundColor,
      padding: AppLayout.listItemPadding,
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            AppLayout.hSpaceMd,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                title,
                if (subtitle != null) ...[
                  AppLayout.vSpaceXs,
                  subtitle!,
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            AppLayout.hSpaceMd,
            trailing!,
          ],
        ],
      ),
    );
  }
}
