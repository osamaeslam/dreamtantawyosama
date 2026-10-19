import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A single logical destination shared across the mobile bottom nav and the
/// desktop [NavigationRail]. Keeping this in one place removes the destination
/// duplication that previously lived inline in [AdaptiveHomeScreen].
class AppDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool showBadge;
  final List<String>? allowedRoles;

  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.showBadge = false,
    this.allowedRoles,
  });
}

/// Central catalog of every navigable section in the app.
/// The list order matches the `_buildSelectedScreen` switch in
/// `AdaptiveHomeScreen`, so callers use the raw list index directly.
class AppNavigation {
  static const List<AppDestination> destinations = [
    AppDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'الرئيسية',
    ),
    AppDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'الكتالوج',
    ),
    AppDestination(
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag,
      label: 'الطلبية',
      showBadge: true,
      allowedRoles: ['sales_rep'],
    ),
    AppDestination(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      label: 'الفواتير',
    ),
    AppDestination(
      icon: Icons.location_on_outlined,
      selectedIcon: Icons.location_on,
      label: 'الزيارات',
    ),
    AppDestination(
      icon: Icons.warehouse_outlined,
      selectedIcon: Icons.warehouse,
      label: 'المخزون',
    ),
    AppDestination(
      icon: Icons.energy_savings_leaf_outlined,
      selectedIcon: Icons.energy_savings_leaf,
      label: 'التوقعات',
    ),
  ];

  /// Indices surfaced as direct tabs on the mobile bottom navigation bar.
  static const List<int> mobileTabIndices = [0, 1, 2];

  /// Indices collected inside the mobile "More" overflow screen.
  static const List<int> overflowIndices = [3, 4, 5, 6];

  /// Index reserved for the "More" overflow entry on mobile.
  static const int moreIndex = 7;

  static List<int> visibleDestinationIndices(String role) => [
        for (var i = 0; i < destinations.length; i++)
          if (destinations[i].allowedRoles == null ||
              destinations[i].allowedRoles!.contains(role))
            i,
      ];

  /// Builds a [NavigationDestination] for the mobile bottom nav. The cart
  /// destination receives a [Badge] showing the live cart item count.
  static NavigationDestination buildMobileDestination(
    int logicalIndex,
    int cartItemCount,
  ) {
    if (logicalIndex == moreIndex) {
      return const NavigationDestination(
        icon: Icon(Icons.more_horiz),
        selectedIcon: Icon(Icons.more_horiz),
        label: 'المزيد',
      );
    }

    final dest = destinations[logicalIndex];
    final icon = _buildIcon(dest, cartItemCount, light: true);
    final selectedIcon = _buildIcon(dest, cartItemCount, light: false);
    return NavigationDestination(
      icon: icon,
      selectedIcon: selectedIcon,
      label: dest.label,
    );
  }

  /// Builds a [NavigationRailDestination] for the desktop rail.
  static NavigationRailDestination buildRailDestination(
    int logicalIndex,
    int cartItemCount,
  ) {
    final dest = destinations[logicalIndex];
    return NavigationRailDestination(
      icon: _buildRailIcon(dest, cartItemCount, selected: false),
      selectedIcon: _buildRailIcon(dest, cartItemCount, selected: true),
      label: Text(dest.label),
    );
  }

  static Widget _buildIcon(
    AppDestination dest,
    int cartItemCount, {
    required bool light,
  }) {
    final iconData = light ? dest.icon : dest.selectedIcon;
    if (dest.showBadge) {
      return Badge(
        label: Text('$cartItemCount'),
        isLabelVisible: cartItemCount > 0,
        child: Icon(iconData),
      );
    }
    return Icon(iconData);
  }

  static Widget _buildRailIcon(
    AppDestination dest,
    int cartItemCount, {
    required bool selected,
  }) {
    if (dest.showBadge) {
      return Badge(
        label: Text('$cartItemCount'),
        isLabelVisible: cartItemCount > 0,
        child: Icon(
          selected ? dest.selectedIcon : dest.icon,
          color: selected ? AppTheme.darkSlate : Colors.white,
        ),
      );
    }
    return Icon(
      selected ? dest.selectedIcon : dest.icon,
      color: selected ? AppTheme.darkSlate : Colors.white,
    );
  }
}

/// Reusable [NavigationRail] for wide-screen (web/desktop) layouts. The parent
/// is responsible for holding `_selectedIndex` and reacting to `onSelected`.
class AppNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final int cartItemCount;
  final List<int> visibleDestinationIndices;
  final void Function(int logicalIndex) onSelected;

  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.cartItemCount,
    required this.visibleDestinationIndices,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedVisibleIndex = visibleDestinationIndices.indexOf(selectedIndex);
    return NavigationRail(
      selectedIndex: selectedVisibleIndex < 0 ? 0 : selectedVisibleIndex,
      backgroundColor: AppTheme.darkSlate,
      indicatorColor: AppTheme.primaryGold,
      useIndicator: true,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryGold, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.storefront_rounded,
                color: AppTheme.darkSlate, size: 24),
          ),
        ),
      ),
        onDestinationSelected: (index) =>
          onSelected(visibleDestinationIndices[index]),
      selectedLabelTextStyle: GoogleFonts.cairo(
        fontWeight: FontWeight.bold,
        color: AppTheme.secondaryGold,
        fontSize: 11,
      ),
      unselectedLabelTextStyle:
          GoogleFonts.cairo(color: Colors.grey.shade400, fontSize: 10),
      destinations: visibleDestinationIndices
          .map((index) =>
              AppNavigation.buildRailDestination(index, cartItemCount))
          .toList(),
    );
  }
}
