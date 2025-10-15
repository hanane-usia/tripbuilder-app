import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../../models/trip_models_admin.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_navigation.dart';
import '../../providers/theme_provider.dart';
import 'addtrip_screen.dart';
import 'client_trips_screen.dart';
import 'documents_screen.dart';
import 'planning_screen.dart';
import 'profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? adminName;

  AdminDashboardScreen({this.adminName});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with WidgetsBindingObserver {
  int _currentNavIndex = 0;
  late Future<List<Client>> _clientsFuture;
  late Future<List<Trip>> _tripsFuture;
  DateTime? _lastRefreshTime;
  Timer? _periodicRefreshTimer;
  final Map<String, int> _clientTripCounts = {};
  final Set<String> _loadingTripCounts = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    WidgetsBinding.instance.addObserver(this);
    _clientsFuture = ApiService.getAllClients();
    _tripsFuture = ApiService.getAllTrips();
    _lastRefreshTime = DateTime.now();
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
    if (state == AppLifecycleState.resumed && _currentNavIndex == 0) {
      _autoRefreshData();
    }
  }

  void _refreshClients() {
    setState(() {
      _clientsFuture = ApiService.getAllClients();
      _tripsFuture = ApiService.getAllTrips();
      _lastRefreshTime = DateTime.now();
      _clientTripCounts.clear();
      _loadingTripCounts.clear();
    });
    HapticFeedback.lightImpact();
  }

  void _autoRefreshData() {
    if (_lastRefreshTime == null ||
        DateTime.now().difference(_lastRefreshTime!).inSeconds > 5) {
      _refreshClients();
    }
  }

  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (_currentNavIndex == 0 && mounted) {
        _refreshClients();
      }
    });
  }

  void _ensureTripCountLoaded(Client client) async {
    if (_clientTripCounts.containsKey(client.id) ||
        _loadingTripCounts.contains(client.id)) {
      return;
    }
    _loadingTripCounts.add(client.id);
    try {
      final trips = await ApiService.getClientTrips(client.id, client);
      if (!mounted) return;
      setState(() {
        _clientTripCounts[client.id] = trips.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clientTripCounts[client.id] = 0;
      });
    } finally {
      _loadingTripCounts.remove(client.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        appBar:
            _currentNavIndex == 0
                ? AdminAppBar(
                  title: 'Trip Builder',
                  currentScreen: 'dashboard',
                  showBackButton: false,
                  adminName: widget.adminName,
                )
                : null,
        body: _buildCurrentPage(),
        bottomNavigationBar: AdminBottomNavBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() => _currentNavIndex = index);
            if (index == 0) {
              _autoRefreshData();
            }
          },
        ),
        floatingActionButton:
            _currentNavIndex == 0
                ? Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5B67CA), Color(0xFF8B9DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5B67CA).withOpacity(0.25),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateTripScreen(),
                            ),
                          ),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Nouveau Client',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentNavIndex) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return PlanningScreen();
      case 2:
        return DocumentsScreen();
      case 3:
        return ProfileScreen();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildDashboardPage() {
    return RefreshIndicator(
      color: Color(0xFF5B67CA),
      backgroundColor: Colors.white,
      onRefresh: () async => _refreshClients(),
      child: CustomScrollView(
        slivers: [
          _buildWelcomeSection(),
          _buildStatsSection(),
          _buildClientListHeader(),
          FutureBuilder<List<Client>>(
            future: _clientsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF5B67CA),
                      strokeWidth: 2,
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFEBEE),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Color(0xFFE57373),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Erreur de chargement",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Impossible de charger les clients",
                          style: TextStyle(
                            color: Color(0xFF9FA5C0),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _refreshClients,
                          icon: Icon(Icons.refresh_rounded, size: 18),
                          label: Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5B67CA),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF5B67CA).withOpacity(0.1),
                                Color(0xFF8B9DFF).withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.people_outline_rounded,
                            size: 56,
                            color: Color(0xFF5B67CA),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Aucun client trouvé",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Commencez par ajouter votre premier client",
                          style: TextStyle(
                            color: Color(0xFF9FA5C0),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              }

              final clients = snapshot.data!;
              return _buildClientsList(clients);
            },
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildWelcomeSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${widget.adminName?.trim().isNotEmpty == true ? widget.adminName : 'Admin'}! 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3142),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Gérez vos clients et voyages facilement',
              style: TextStyle(color: Color(0xFF9FA5C0), fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildStatsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          children: [
            FutureBuilder<List<Client>>(
              future: _clientsFuture,
              builder: (context, clientSnap) {
                final clients = clientSnap.data ?? [];
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Clients',
                        clientSnap.connectionState == ConnectionState.waiting
                            ? '...'
                            : '${clients.length}',
                        Icons.groups_outlined,
                        Color(0xFF2ED8B6),
                        Color(0xFFE6FFF9),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: FutureBuilder<List<Trip>>(
                        future: _tripsFuture,
                        builder: (context, tripsSnap) {
                          final trips = tripsSnap.data ?? [];
                          return _buildStatCard(
                            'Total Voyages',
                            tripsSnap.connectionState == ConnectionState.waiting
                                ? '...'
                                : '${trips.length}',
                            Icons.airplane_ticket_outlined,
                            Color(0xFF5B67CA),
                            Color(0xFFEEF0FF),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                themeProvider.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : color.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: themeProvider.textColor,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: themeProvider.subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildClientListHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clients Récents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                if (_lastRefreshTime != null)
                  Text(
                    'Mis à jour ${_formatLastRefreshTime()}',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9FA5C0)),
                  ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _refreshClients,
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF5B67CA),
                      size: 18,
                    ),
                    tooltip: 'Actualiser',
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    icon: Icon(
                      Icons.filter_list_rounded,
                      color: Color(0xFF5B67CA),
                      size: 18,
                    ),
                    tooltip: 'Filtrer',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastRefreshTime() {
    if (_lastRefreshTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(_lastRefreshTime!);

    if (difference.inSeconds < 60) {
      return 'il y a ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes}min';
    } else {
      return 'il y a ${difference.inHours}h';
    }
  }

  SliverPadding _buildClientsList(List<Client> clients) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final client = clients[index];
          _ensureTripCountLoaded(client);
          final tripCount = _clientTripCounts[client.id] ?? 0;
          return _buildClientCard(client, tripCount);
        }, childCount: clients.length),
      ),
    );
  }

  Widget _buildClientCard(Client client, int tripCount) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () async {
        final refresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => ClientTripsScreen(client: client),
          ),
        );
        if (refresh == true) {
          _refreshClients();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  themeProvider.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientTripsScreen(client: client),
                  ),
                ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5B67CA), Color(0xFF8B9DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        client.name
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join()
                            .toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.textColor,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          client.email,
                          style: TextStyle(
                            color: themeProvider.subTextColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF5B67CA).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$tripCount voyage${tripCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5B67CA),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFB8B8D2),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
