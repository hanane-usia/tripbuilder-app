import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/admin/dashboard_screen.dart';
import '../providers/theme_provider.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final String? currentScreen;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onNotificationPressed;
  final String? adminName;

  const AdminAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.currentScreen,
    this.onSearchPressed,
    this.onFilterPressed,
    this.onNotificationPressed,
    this.adminName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: themeProvider.textColor,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
      ),
      backgroundColor: themeProvider.backgroundColor,
      elevation: 0,
      centerTitle: false,
      leading: _buildLeading(context),
      actions: _buildActions(context),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (currentScreen == 'dashboard') {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    themeProvider.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Color(0xFF5B67CA).withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.menu_rounded, color: Color(0xFF5B67CA), size: 20),
            onPressed: () {},
          ),
        ),
      );
    } else if (showBackButton) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    themeProvider.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Color(0xFF5B67CA).withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5B67CA),
              size: 16,
            ),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
                (route) => false,
              );
            },
          ),
        ),
      );
    }
    return null;
  }

  List<Widget> _buildActions(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    List<Widget> defaultActions = [];

    switch (currentScreen) {
      case 'dashboard':
        defaultActions = [
          Container(
            margin: EdgeInsets.only(right: 8),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.search_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: onSearchPressed ?? () => _showSearchDialog(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _showAdminProfile(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF5B67CA), Color(0xFF8B9DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF5B67CA).withOpacity(0.25),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(adminName),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ];
        break;

      case 'planning':
        defaultActions = [
          Container(
            margin: EdgeInsets.only(right: 8),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.calendar_view_month_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: () => _showCalendarView(context),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.filter_list_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: onFilterPressed ?? () => _showPlanningFilters(context),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.search_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: onSearchPressed ?? () => _showSearchDialog(context),
            ),
          ),
        ];
        break;

      case 'documents':
        defaultActions = [
          Container(
            margin: EdgeInsets.only(right: 8),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.search_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: onSearchPressed ?? () => _showDocumentSearch(context),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.filter_list_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: onFilterPressed ?? () => _showDocumentFilters(context),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.sort_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: () => _showSortOptions(context),
            ),
          ),
        ];
        break;

      case 'profile':
        defaultActions = [
          Container(
            margin: EdgeInsets.only(right: 8),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.edit_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: () => _editProfile(context),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      themeProvider.isDarkMode
                          ? Colors.black.withOpacity(0.3)
                          : Color(0xFF5B67CA).withOpacity(0.08),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.settings_rounded,
                color: Color(0xFF5B67CA),
                size: 20,
              ),
              onPressed: () => _showSettings(context),
            ),
          ),
        ];
        break;

      default:
        if (actions != null) {
          defaultActions.addAll(actions!);
        }
        break;
    }

    return defaultActions;
  }

  String _getInitials(String? name) {
    final source = (name ?? '').trim();
    if (source.isEmpty) return 'AD';
    final parts = source.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'AD';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  void _showSearchDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeProvider.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Annuler',
                            style: TextStyle(color: themeProvider.subTextColor),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5B67CA),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Rechercher',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showAdminProfile(BuildContext context) {}

  void _showCalendarView(BuildContext context) {}

  void _showPlanningFilters(BuildContext context) {}

  void _showDocumentSearch(BuildContext context) {}

  void _showDocumentFilters(BuildContext context) {}

  void _showSortOptions(BuildContext context) {}

  void _editProfile(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Modification du profil')));
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Paramètres')));
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + 8);
}

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        boxShadow: [
          BoxShadow(
            color:
                themeProvider.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Accueil'),
          _buildNavItem(
            1,
            Icons.calendar_today_outlined,
            Icons.calendar_today_rounded,
            'Planning',
          ),
          _buildNavItem(
            2,
            Icons.folder_outlined,
            Icons.folder_rounded,
            'Documents',
          ),
          _buildNavItem(
            3,
            Icons.person_outline_rounded,
            Icons.person_rounded,
            'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isActive
                        ? Color(0xFF5B67CA).withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Color(0xFF5B67CA) : Color(0xFFB8B8D2),
                size: 24,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Color(0xFF5B67CA) : Color(0xFFB8B8D2),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
