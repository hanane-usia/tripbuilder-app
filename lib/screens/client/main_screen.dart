import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math';
import '../../widgets/custom_app_bar.dart';
import '../../constants/design_constants.dart';
import '../../services/client_api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/localization.dart';
import 'dashboard_screen.dart';
import 'dossiers_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../login_screen.dart';

String generateRandomId({int length = 5}) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

String getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  String first = parts[0].isNotEmpty ? parts[0][0] : '';
  String second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
  return (first + second).toUpperCase();
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  List<Widget> _screens = [];
  bool _isDateFormattingInitialized = false;
  bool _isLoading = true;
  String? _error;
  String _userName = 'Utilisateur';
  String _userInitials = 'U';
  Timer? _periodicRefreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _autoRefreshData();
    }
  }

  Future<void> _initializeApp() async {
    try {
      print('🔄 Initializing main screen...');
      await initializeDateFormatting('fr_FR', null);

      print('👤 Loading client profile...');
      final client = await ClientApiService.getClientProfile();
      print('✅ Client profile loaded: ${client.name}');

      setState(() {
        _userName = client.name;
        _userInitials = getInitials(client.name);
        _lastRefreshTime = DateTime.now();
      });

      setState(() {
        _isDateFormattingInitialized = true;
        _isLoading = false;

        _screens = [
          const DashboardScreen(),
          const DossiersScreen(),
          const ProfileScreen(),
          const SettingsScreen(),
        ];
      });
      print('✅ Main screen initialized successfully');
    } catch (e) {
      print('❌ Error initializing main screen: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _refreshAppData() async {
    try {
      print('🔄 Refreshing app data...');
      final client = await ClientApiService.getClientProfile();

      setState(() {
        _userName = client.name;
        _userInitials = getInitials(client.name);
        _lastRefreshTime = DateTime.now();
      });

      // App bar is built dynamically using current locale and index

      HapticFeedback.lightImpact();
      print('✅ App data refreshed successfully');
    } catch (e) {
      print('❌ Error refreshing app data: $e');
    }
  }

  void _autoRefreshData() {
    if (_lastRefreshTime == null ||
        DateTime.now().difference(_lastRefreshTime!).inSeconds > 5) {
      _refreshAppData();
    }
  }

  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshAppData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
    final l10n = context.l10n(localeProvider.locale);
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeApp,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isDateFormattingInitialized || _screens.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _localizedAppBar(l10n),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNavigationBar(),
      drawer: _buildDrawer(context),
    );
  }

  PreferredSizeWidget _localizedAppBar(AppLocalizations l10n) {
    switch (_currentIndex) {
      case 0:
        return ModernAppBar(
          userName: _userName,
          userInitials: _userInitials,
          title: '${l10n.t('greet.hello')} ${_userName.split(' ')[0]} 👋',
          subtitle: l10n.t('dashboard.subtitle'),
        );
      case 1:
        return ModernAppBar(
          userName: _userName,
          userInitials: _userInitials,
          title: l10n.t('documents.title'),
          subtitle: l10n.t('documents.subtitle'),
        );
      case 2:
        return ModernAppBar(
          userName: _userName,
          userInitials: _userInitials,
          title: l10n.t('profile.title'),
          subtitle: l10n.t('profile.subtitle'),
        );
      case 3:
      default:
        return ModernAppBar(
          userName: _userName,
          userInitials: _userInitials,
          title: l10n.t('settings.title'),
          subtitle: l10n.t('settings.preferences'),
        );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: true).locale;
    final l10n = context.l10n(locale);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF3B82F6)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Text(
                    _userInitials,
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Client',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Color(0xFF3B82F6)),
            title: Text(l10n.t('nav.home')),
            onTap: () {
              setState(() {
                _currentIndex = 0;
              });
              _autoRefreshData();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.folder_open_rounded,
              color: Color(0xFF3B82F6),
            ),
            title: Text(l10n.t('nav.dossiers')),
            onTap: () {
              setState(() {
                _currentIndex = 1;
              });
              _autoRefreshData();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded, color: Color(0xFF3B82F6)),
            title: Text(l10n.t('nav.profile')),
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
              _autoRefreshData();
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.settings_rounded,
              color: Color(0xFF3B82F6),
            ),
            title: Text(l10n.t('nav.settings')),
            onTap: () {
              setState(() {
                _currentIndex = 3;
              });
              _autoRefreshData();
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              l10n.t('nav.logout'),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();

                try {
                  await ClientApiService.logout();
                } catch (e) {
                  print('Logout error: $e');
                }

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    final locale = Provider.of<LocaleProvider>(context, listen: true).locale;
    final l10n = context.l10n(locale);
    return Container(
      decoration: BoxDecoration(
        color: DesignConstants.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(
            horizontal: DesignConstants.spacingSmall,
            vertical: 6,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.home_outlined,
                l10n.t('nav.home'),
                activeIcon: Icons.home_rounded,
                showLabel: true,
              ),
              _buildNavItem(
                1,
                Icons.folder_outlined,
                l10n.t('nav.dossiers'),
                activeIcon: Icons.folder_rounded,
                showLabel: true,
              ),
              _buildNavItem(
                2,
                Icons.person_outline_rounded,
                l10n.t('nav.profile'),
                activeIcon: Icons.person_rounded,
                showLabel: true,
              ),
              _buildNavItem(
                3,
                Icons.settings_outlined,
                l10n.t('nav.settings'),
                activeIcon: Icons.settings_rounded,
                showLabel: true,
              ),
              _buildNavItem(
                4,
                Icons.logout_rounded,
                l10n.t('nav.logout'),
                showLabel: true,
                isLogout: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    IconData? activeIcon,
    bool showLabel = false,
    bool isLogout = false,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (isLogout) {
          _showLogoutDialog(context);
        } else {
          setState(() => _currentIndex = index);
          _autoRefreshData();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isLogout
                        ? DesignConstants.errorColor.withOpacity(0.08)
                        : (isSelected
                            ? DesignConstants.primaryColor.withOpacity(0.1)
                            : Colors.transparent),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected && activeIcon != null ? activeIcon : icon,
                color:
                    isLogout
                        ? DesignConstants.errorColor
                        : (isSelected
                            ? DesignConstants.primaryColor
                            : const Color(0xFFB8B8D2)),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            if (showLabel) ...[
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isLogout
                          ? DesignConstants.errorColor
                          : (isSelected
                              ? DesignConstants.primaryColor
                              : const Color(0xFFB8B8D2)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
