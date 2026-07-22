import 'package:flutter/material.dart';
import 'package:mindflow/core/l10n/app_language.dart';
import 'package:mindflow/core/l10n/app_strings.dart';
import 'package:mindflow/core/utils/responsive.dart';

/// Persistent nav chrome around Library / Stats / Settings. A
/// `NavigationRail` on tablet/desktop widths, a bottom `NavigationBar` on
/// phones -- one widget tree, chosen purely by [Responsive], so it keeps
/// working correctly once Windows/Web targets are added.
class AppShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppLanguage language;

  const AppShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.language,
  });

  List<({IconData icon, IconData selectedIcon, String label})> get _destinations => [
        (icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book, label: AppStrings.t(language, 'navLibrary')),
        (icon: Icons.format_quote_outlined, selectedIcon: Icons.format_quote, label: AppStrings.t(language, 'navQuotes')),
        (icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: AppStrings.t(language, 'navStats')),
        (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: AppStrings.t(language, 'navSettings')),
      ];

  @override
  Widget build(BuildContext context) {
    if (Responsive.isPhone(context)) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: _destinations
              .map((d) => NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label))
              .toList(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            extended: Responsive.isDesktop(context),
            destinations: _destinations
                .map((d) => NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
