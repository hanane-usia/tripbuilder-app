import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/trip_models_admin.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';
import 'TripManagement_Screen.dart';

class DayPlan {
  final DateTime date;
  String title;
  String description;

  DayPlan({required this.date, this.title = '', this.description = ''});
}

class TripPlanningScreen extends StatefulWidget {
  final Trip trip;

  const TripPlanningScreen({Key? key, required this.trip}) : super(key: key);

  @override
  _TripPlanningScreenState createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late List<DayPlan> _dayPlans;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _generateDayPlans();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _generateDayPlans() {
    _dayPlans = [];
    final duration =
        widget.trip.endDate.difference(widget.trip.startDate).inDays + 1;

    for (int i = 0; i < duration; i++) {
      final date = widget.trip.startDate.add(Duration(days: i));
      _dayPlans.add(
        DayPlan(date: date, title: 'Jour ${i + 1}', description: ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildHeaderCard(),
              _buildTimelineHeader(),
              _buildDaysList(),
              SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      backgroundColor: themeProvider.cardColor,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeProvider.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: themeProvider.textColor,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Planification',
        style: TextStyle(
          color: themeProvider.textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _isLoading
                        ? themeProvider.backgroundColor
                        : Color(0xFF7B68EE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.save_rounded,
                size: 20,
                color:
                    _isLoading ? themeProvider.subTextColor : Color(0xFF7B68EE),
              ),
            ),
            onPressed: _isLoading ? null : _saveAndContinue,
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeProvider.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: themeProvider.textColor,
              ),
            ),
            onPressed: _showMoreOptions,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildHeaderCard() {
    final duration =
        widget.trip.endDate.difference(widget.trip.startDate).inDays + 1;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B68EE), Color(0xFF9D88F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF7B68EE).withOpacity(0.25),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.flight_takeoff_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trip.tripDestination,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.trip.client.name,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    Icons.calendar_today_rounded,
                    DateFormat('dd MMM').format(widget.trip.startDate),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildInfoItem(Icons.schedule_rounded, '$duration jours'),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildInfoItem(
                    Icons.event_rounded,
                    DateFormat('dd MMM').format(widget.trip.endDate),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildTimelineHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Itinéraire jour par jour',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.textColor,
              ),
            ),
            TextButton.icon(
              onPressed: _showSuggestions,
              icon: Icon(Icons.auto_awesome, size: 16),
              label: Text('Suggestions'),
              style: TextButton.styleFrom(foregroundColor: Color(0xFF7B68EE)),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildDaysList() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: _buildDayCard(_dayPlans[index], index),
              ),
            );
          },
        );
      }, childCount: _dayPlans.length),
    );
  }

  Widget _buildDayCard(DayPlan dayPlan, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = [
      Color(0xFF7B68EE),
      Color(0xFF00D7B0),
      Color(0xFFFF6B9D),
      Color(0xFFFFAA00),
      Color(0xFF4ECDC4),
    ];
    final cardColor = colors[index % colors.length];
    final isLastCard = index == _dayPlans.length - 1;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        children: [
          if (!isLastCard)
            Positioned(
              left: 27,
              top: 60,
              bottom: -20,
              child: Container(width: 2, color: cardColor.withOpacity(0.2)),
            ),

          Container(
            margin: EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cardColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),

                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: themeProvider.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color:
                              themeProvider.isDarkMode
                                  ? Colors.black.withOpacity(0.3)
                                  : cardColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: cardColor,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'EEEE dd MMMM',
                                'fr_FR',
                              ).format(dayPlan.date),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: themeProvider.textColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          initialValue:
                              dayPlan.title.isNotEmpty
                                  ? dayPlan.title
                                  : 'Jour ${index + 1}',
                          onChanged: (value) => dayPlan.title = value,
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Titre du jour',
                            hintText: 'Jour ${index + 1}',
                            prefixIcon: Icon(
                              Icons.title_rounded,
                              color: cardColor,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: themeProvider.backgroundColor,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            floatingLabelStyle: TextStyle(color: cardColor),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: cardColor,
                                width: 2,
                              ),
                            ),
                          ),
                          validator:
                              (value) =>
                                  value?.isEmpty == true
                                      ? 'Titre requis'
                                      : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          initialValue: dayPlan.description,
                          onChanged: (value) => dayPlan.description = value,
                          maxLines: 3,
                          style: TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Activités prévues',
                            hintText: 'Décrivez les activités de la journée...',
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 50),
                              child: Icon(
                                Icons.description_rounded,
                                color: cardColor,
                                size: 20,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: themeProvider.backgroundColor,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            floatingLabelStyle: TextStyle(color: cardColor),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: cardColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            _buildActionChip(
                              Icons.add_location_rounded,
                              'Lieux',
                              cardColor,
                              () => _showPlacesDialog(index),
                            ),
                            SizedBox(width: 8),
                            _buildActionChip(
                              Icons.restaurant_rounded,
                              'Repas',
                              cardColor,
                              () => _showMealsDialog(index),
                            ),
                            SizedBox(width: 8),
                            _buildActionChip(
                              Icons.hotel_rounded,
                              'Hôtel',
                              cardColor,
                              () => _showHotelDialog(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        boxShadow: [
          BoxShadow(
            color:
                themeProvider.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF7B68EE),
                    strokeWidth: 2,
                  ),
                )
                : Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: themeProvider.dividerColor),
                          ),
                        ),
                        child: Text(
                          'Précédent',
                          style: TextStyle(
                            color: themeProvider.subTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saveAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7B68EE),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Finaliser',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await ApiService.planTrip(
          tripId: widget.trip.id,
          dayPlans: _dayPlans,
          startDate: widget.trip.startDate,
        );

        final updatedTrip = await ApiService.getTripDetails(widget.trip.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Planification sauvegardée avec succès!'),
                ],
              ),
              backgroundColor: Color(0xFF00D7B0),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          await Future.delayed(Duration(milliseconds: 500));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TripManagementScreen(trip: updatedTrip),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Erreur: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showMoreOptions() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: themeProvider.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.auto_awesome, color: Color(0xFF7B68EE)),
                  title: Text('Générer automatiquement'),
                  onTap: () {
                    Navigator.pop(context);
                    _autoGeneratePlan();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.copy_rounded, color: Color(0xFF7B68EE)),
                  title: Text('Copier d\'un modèle'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.save_outlined, color: Color(0xFF7B68EE)),
                  title: Text('Sauvegarder comme modèle'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  void _showSuggestions() {}

  void _showPlacesDialog(int dayIndex) {}

  void _showMealsDialog(int dayIndex) {}

  void _showHotelDialog(int dayIndex) {}

  void _autoGeneratePlan() {}
}
