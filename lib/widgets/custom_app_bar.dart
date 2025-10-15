import 'package:flutter/material.dart';
import '../constants/design_constants.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String userInitials;
  final String title;
  final String subtitle;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const ModernAppBar({
    Key? key,
    required this.userName,
    required this.userInitials,
    required this.title,
    required this.subtitle,
    this.onNotificationTap,
    this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: DesignConstants.cardBackground,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DesignConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: DesignConstants.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onNotificationTap,
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignConstants.dividerColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: DesignConstants.textPrimary,
              size: 20,
            ),
          ),
        ),  ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);
}

// Bottom Navigation Bar avec le style moderne comme dans l'image
class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMainTab(),
              _buildNavItem(1, Icons.folder_outlined, false),
              _buildNavItem(2, Icons.people_outline, false),
              _buildNavItem(3, Icons.inbox_outlined, false),
              _buildNavItem(4, Icons.settings_outlined, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTab() {
    final isSelected = currentIndex == 0;
    return GestureDetector(
      onTap: () => onTap(0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFF5B4FCF)
                      : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dashboard_rounded,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Main',
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color:
                  isSelected
                      ? const Color(0xFF5B4FCF)
                      : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, bool showLabel) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B4FCF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
          size: 22,
        ),
      ),
    );
  }
}
