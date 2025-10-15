import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/trip_models_admin.dart';
import '../../widgets/admin_navigation.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';
import 'addtrip_screen.dart';
import 'TripManagement_Screen.dart';

class PlanningScreen extends StatefulWidget {
  @override
  _PlanningScreenState createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadTrips();
  }

  void _loadTrips() {
    setState(() {
      _tripsFuture = ApiService.getAllTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AdminAppBar(
        title: 'Planification',
        currentScreen: 'planning',
        showBackButton: false,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTodayView()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final tripWasCreated = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => CreateTripScreen()),
          );
          if (tripWasCreated == true) {
            _loadTrips();
          }
        },
        label: Text('Nouveau Voyage', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF4F46E5),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Color(0xFF7B68EE), size: 24),
              SizedBox(width: 12),
              Text(
                'Sélectionner une date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Spacer(),

              GestureDetector(
                onTap: _selectCustomDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF7B68EE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.today, color: Color(0xFF7B68EE), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Autre date',
                        style: TextStyle(
                          color: Color(0xFF7B68EE),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF7B68EE).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: Color(0xFF7B68EE), size: 20),
                SizedBox(width: 8),
                Text(
                  'Date sélectionnée: ${DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate)}',
                  style: TextStyle(
                    color: Color(0xFF7B68EE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickDateButton(
                  'Aujourd\'hui',
                  DateTime.now(),
                  Icons.today,
                ),
                SizedBox(width: 8),

                _buildQuickDateButton(
                  'Demain',
                  DateTime.now().add(Duration(days: 1)),
                  Icons.schedule,
                ),
                SizedBox(width: 8),

                ...List.generate(5, (index) {
                  final date = DateTime.now().add(Duration(days: index + 2));
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: _buildDateChip(date),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(String label, DateTime date, IconData icon) {
    final isSelected =
        date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF7B68EE) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF7B68EE) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Color(0xFF7B68EE),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Color(0xFF7B68EE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(DateTime date) {
    final isSelected =
        date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF7B68EE) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              DateFormat('EEE', 'fr_FR').format(date).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            SizedBox(height: 2),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF7B68EE),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: Color(0xFF7B68EE)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Color(0xFF9FA5C0),
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: [
          Tab(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text('Planning'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayView() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF7B68EE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFF7B68EE)),
                SizedBox(width: 12),
                Text(
                  'Voyages du ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B68EE),
                  ),
                ),
                Spacer(),
                FutureBuilder<List<Trip>>(
                  future: _tripsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final selectedTrips =
                          snapshot.data!.where((trip) {
                            return trip.startDate.day == _selectedDate.day &&
                                trip.startDate.month == _selectedDate.month &&
                                trip.startDate.year == _selectedDate.year;
                          }).toList();
                      return Text(
                        '${selectedTrips.length} voyage(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7B68EE),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Text(
                      '0 voyage(s)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7B68EE),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          Expanded(
            child: FutureBuilder<List<Trip>>(
              future: _tripsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B68EE)),
                  );
                }
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final trips = snapshot.data ?? [];
                if (trips.isEmpty) {
                  return _buildEmptyState(
                    'Aucun voyage trouvé',
                    'Créez un nouveau voyage pour commencer',
                  );
                }

                final selectedTrips =
                    trips.where((trip) {
                      return trip.startDate.day == _selectedDate.day &&
                          trip.startDate.month == _selectedDate.month &&
                          trip.startDate.year == _selectedDate.year;
                    }).toList();

                return selectedTrips.isEmpty
                    ? _buildEmptyState(
                      'Aucun voyage à cette date',
                      'Sélectionnez une autre date ou créez un nouveau voyage',
                    )
                    : RefreshIndicator(
                      onRefresh: () async => _loadTrips(),
                      color: Color(0xFF7B68EE),
                      child: ListView.builder(
                        itemCount: selectedTrips.length,
                        itemBuilder:
                            (context, index) =>
                                _buildTripCard(selectedTrips[index]),
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Removed calendar tab view as requested

  Widget _buildTripCard(Trip trip) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final daysUntil = trip.startDate.difference(DateTime.now()).inDays;
    final statusColor = trip.status == 'Active' ? Colors.green : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                themeProvider.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripManagementScreen(trip: trip),
              ),
            ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Text(
                      trip.client.name.isNotEmpty
                          ? trip.client.name
                              .split(' ')
                              .where((e) => e.isNotEmpty)
                              .map((e) => e[0])
                              .take(2)
                              .join()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.tripDestination,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: themeProvider.textColor,
                          ),
                        ),
                        Text(
                          trip.client.name.isNotEmpty
                              ? trip.client.name
                              : 'Nom non disponible',
                          style: TextStyle(color: themeProvider.subTextColor),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      trip.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: themeProvider.subTextColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd MMM yyyy', 'fr_FR').format(trip.startDate)} - ${DateFormat('dd MMM yyyy', 'fr_FR').format(trip.endDate)}',
                    style: TextStyle(color: themeProvider.subTextColor),
                  ),
                ],
              ),
              if (daysUntil >= 0) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      daysUntil == 0
                          ? 'Aujourd\'hui'
                          : 'Dans $daysUntil jour(s)',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 80,
          ),
          SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              color: Colors.red.shade400,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadTrips,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7B68EE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Réessayer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
