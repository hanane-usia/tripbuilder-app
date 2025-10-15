import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/trip_models_admin.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';
import 'TripManagement_Screen.dart';
import 'addtrip_screen.dart';
import 'client_edit_screen.dart';

class ClientTripsScreen extends StatefulWidget {
  final Client client;

  const ClientTripsScreen({Key? key, required this.client}) : super(key: key);

  @override
  _ClientTripsScreenState createState() => _ClientTripsScreenState();
}

class _ClientTripsScreenState extends State<ClientTripsScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Trip>> _clientTripsFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _loadTrips();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadTrips() {
    setState(() {
      _clientTripsFuture = ApiService.getClientTrips(
        widget.client.id,
        widget.client,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF7B68EE),
        onRefresh: () async => _loadTrips(),
        child: CustomScrollView(
          slivers: [
            _buildClientHeader(),
            _buildQuickActions(),
            FutureBuilder<List<Trip>>(
              future: _clientTripsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Container(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7B68EE),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: _buildErrorState(snapshot.error.toString()),
                  );
                }
                final clientTrips = snapshot.data ?? [];
                return _buildTripsList(clientTrips);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFF0EFF4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: Color(0xFF2D3142),
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Voyages',
        style: TextStyle(
          color: Color(0xFF2D3142),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFF0EFF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: Color(0xFF2D3142),
              ),
            ),
            onPressed: () => _showMoreOptions(),
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildClientHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: themeProvider.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color:
                    themeProvider.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Color(0xFF7B68EE).withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B68EE), Color(0xFF9D88F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.client.name
                        .split(' ')
                        .map((e) => e[0])
                        .take(2)
                        .join(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.client.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.textColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.client.email,
                      style: TextStyle(
                        color: themeProvider.subTextColor,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      widget.client.phone,
                      style: TextStyle(
                        color: themeProvider.subTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Color(0xFF7B68EE)),
                onPressed: () => _editClient(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics_rounded,
                title: 'Statistiques',
                color: Color(0xFF00D7B0),
                onTap: () => _showStatistics(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.history_rounded,
                title: 'Historique',
                color: Color(0xFFFF6B9D),
                onTap: () => _showHistory(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.info_outline_rounded,
                title: 'Détails',
                color: Color(0xFF7B68EE),
                onTap: () => _showClientDetails(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: themeProvider.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsList(List<Trip> trips) {
    if (trips.isEmpty) {
      return SliverFillRemaining(child: _buildEmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildTripCard(trips[index]),
                ),
              );
            },
          );
        }, childCount: trips.length),
      ),
    );
  }

  Widget _buildTripCard(Trip trip) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final formattedStartDate = DateFormat(
      'dd MMM',
      'fr_FR',
    ).format(trip.startDate);
    final formattedEndDate = DateFormat(
      'dd MMM yyyy',
      'fr_FR',
    ).format(trip.endDate);
    final duration = trip.endDate.difference(trip.startDate).inDays + 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripManagementScreen(trip: trip),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  themeProvider.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(0xFF7B68EE).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.flight_takeoff_rounded,
                      color: Color(0xFF7B68EE),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.tripDestination,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.textColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$formattedStartDate - $formattedEndDate',
                          style: TextStyle(
                            color: themeProvider.subTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _editTrip(trip),
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF7B68EE),
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Color(0xFF7B68EE).withOpacity(0.1),
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                      SizedBox(width: 4),
                      IconButton(
                        onPressed: () => _showDeleteConfirmation(trip),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(Icons.schedule_rounded, '$duration jours'),
                  SizedBox(width: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFF0EFF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Color(0xFF9FA5C0)),
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF9FA5C0))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFFF0EFF4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.airplanemode_off_rounded,
              size: 48,
              color: Color(0xFF9FA5C0),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Aucun voyage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Créez le premier voyage pour ce client',
            style: TextStyle(fontSize: 14, color: Color(0xFF9FA5C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: 300,
      padding: EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: Colors.red.shade400,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9FA5C0), fontSize: 14),
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
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _fadeAnimation,
        child: FloatingActionButton.extended(
          onPressed: () async {
            final tripWasCreated = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => CreateTripScreen(client: widget.client),
              ),
            );
            if (tripWasCreated == true) {
              _loadTrips();
            }
          },
          backgroundColor: Color(0xFF7B68EE),
          icon: Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Nouveau Voyage',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.share_outlined, color: Color(0xFF7B68EE)),
                  title: Text('Partager'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.print_outlined, color: Color(0xFF7B68EE)),
                  title: Text('Imprimer'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(
                    Icons.archive_outlined,
                    color: Color(0xFF7B68EE),
                  ),
                  title: Text('Archiver'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  void _editClient() async {
    final refreshDashboard = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ClientEditScreen(
              client: widget.client,
              onUpdate: (updatedClient) async {
                try {
                  await ApiService.updateClient(
                    clientId: widget.client.id,
                    name: updatedClient.name,
                    email: updatedClient.email,
                    phone: updatedClient.phone,
                  );

                  setState(() {
                    widget.client.name = updatedClient.name;
                    widget.client.email = updatedClient.email;
                    widget.client.phone = updatedClient.phone;
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Client mis à jour avec succès'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la mise à jour: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
      ),
    );

    if (refreshDashboard == true) {
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _showStatistics() async {
    final trips = await _clientTripsFuture;
    final totalTrips = trips.length;
    final activeTrips = trips.where((trip) => trip.status == 'Active').length;
    final completedTrips =
        trips.where((trip) => trip.status == 'Completed').length;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Statistiques du Client'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatItem(
                  'Total des voyages',
                  totalTrips.toString(),
                  Icons.flight_rounded,
                ),
                _buildStatItem(
                  'Voyages actifs',
                  activeTrips.toString(),
                  Icons.play_circle_outline_rounded,
                ),
                _buildStatItem(
                  'Voyages terminés',
                  completedTrips.toString(),
                  Icons.check_circle_outline_rounded,
                ),
                _buildStatItem(
                  'Date d\'inscription',
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  Icons.calendar_today_rounded,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF7B68EE), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Color(0xFF2D3142)),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7B68EE),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Historique du Client'),
            content: Text('Fonctionnalité d\'historique à implémenter'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showClientDetails() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Détails du Client'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nom: ${widget.client.name}'),
                SizedBox(height: 8),
                Text('Email: ${widget.client.email}'),
                SizedBox(height: 8),
                Text('Téléphone: ${widget.client.phone}'),
                SizedBox(height: 8),
                Text('ID: ${widget.client.id}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(Trip trip) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Supprimer le voyage'),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer le voyage ${trip.tripDestination} ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteTrip(trip);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Supprimer'),
              ),
            ],
          ),
    );
  }

  void _editTrip(Trip trip) {
    final destinationController = TextEditingController(
      text: trip.tripDestination,
    );
    final statusController = TextEditingController(text: trip.status);
    DateTime selectedStartDate = trip.startDate;
    DateTime selectedEndDate = trip.endDate;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF7B68EE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF7B68EE),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Modifier le voyage'),
                  ],
                ),
                content: Container(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: destinationController,
                        decoration: InputDecoration(
                          labelText: 'Destination',
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Color(0xFF7B68EE),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF0EFF4),
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: statusController.text,
                        decoration: InputDecoration(
                          labelText: 'Statut',
                          prefixIcon: Icon(
                            Icons.flag,
                            color: Color(0xFF7B68EE),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Color(0xFFF0EFF4),
                        ),
                        items:
                            [
                                  'Active',
                                  'Completed',
                                  'Cancelled',
                                  'Planning',
                                  'Draft',
                                ]
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            statusController.text = value!;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedStartDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: Color(0xFF7B68EE),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedStartDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF0EFF4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF7B68EE),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Début: ${DateFormat('dd/MM/yyyy').format(selectedStartDate)}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedEndDate,
                                  firstDate: selectedStartDate,
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: ThemeData.light().copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: Color(0xFF7B68EE),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedEndDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF0EFF4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.event, color: Color(0xFF7B68EE)),
                                    SizedBox(width: 12),
                                    Text(
                                      'Fin: ${DateFormat('dd/MM/yyyy').format(selectedEndDate)}',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: TextStyle(color: Color(0xFF9FA5C0)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (destinationController.text.isNotEmpty) {
                        try {
                          await ApiService.updateTrip(
                            tripId: trip.id,
                            destination: destinationController.text,
                            status: statusController.text,
                            startDate: selectedStartDate,
                            endDate: selectedEndDate,
                          );

                          Navigator.pop(context);
                          _loadTrips();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Voyage modifié avec succès'),
                                  ],
                                ),
                                backgroundColor: Color(0xFF00D7B0),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Erreur lors de la modification: $e',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7B68EE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Enregistrer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _deleteTrip(Trip trip) async {
    try {
      await ApiService.deleteTrip(trip.id);
      _loadTrips();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voyage supprimé avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
