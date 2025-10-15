import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../constants/design_constants.dart';
import '../../models/trip_models.dart';
import '../../services/client_api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/localization.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  Client? client;
  List<Trip> trips = [];
  bool isLoading = true;
  String? error;
  Timer? _periodicRefreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileData();
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

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final clientData = await ClientApiService.getClientProfile();
      final clientTrips = await ClientApiService.getClientTrips();

      setState(() {
        client = clientData;
        trips = clientTrips;
        isLoading = false;
        _lastRefreshTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _refreshProfileData() {
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
    _loadProfileData();
    HapticFeedback.lightImpact();
  }

  Future<void> _refreshProfileDataSilently() async {
    try {
      setState(() {
        _lastRefreshTime = DateTime.now();
      });

      final clientData = await ClientApiService.getClientProfile();
      final clientTrips = await ClientApiService.getClientTrips();

      if (mounted) {
        setState(() {
          client = clientData;
          trips = clientTrips;
        });
      }
    } catch (e) {
      print('❌ Silent refresh - Erreur lors du chargement du profil: $e');
    }
  }

  void _autoRefreshData() {
    if (_lastRefreshTime == null ||
        DateTime.now().difference(_lastRefreshTime!).inSeconds > 5) {
      _refreshProfileDataSilently();
    }
  }

  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshProfileDataSilently();
      }
    });
  }

  List<Trip> get activeTrips {
    return trips.where((trip) => trip.status.toLowerCase() == 'active').toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: true).locale;
    final l10n = context.l10n(locale);
    if (isLoading) {
      return Container(
        color: DesignConstants.backgroundSecondary,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || client == null) {
      return Container(
        color: DesignConstants.backgroundSecondary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: DesignConstants.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.t('error.load_failed'),
                style: DesignConstants.textStyleTitle,
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'فشل في تحميل الملف الشخصي',
                style: DesignConstants.textStyleCaption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfileData,
                child: Text(l10n.t('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: DesignConstants.backgroundSecondary,
      child: RefreshIndicator(
        color: DesignConstants.primaryColor,
        backgroundColor: Colors.white,
        onRefresh: () async => _refreshProfileData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignConstants.spacingLarge),
          child: Column(
            children: [
              const SizedBox(height: DesignConstants.spacingTiny),
              _buildProfileHeader(),

              const SizedBox(height: DesignConstants.spacingLarge),
              _buildStatsRow(),

              const SizedBox(height: DesignConstants.spacingLarge),
              _buildInfoCard(),

              const SizedBox(height: DesignConstants.spacingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignConstants.spacingLarge),
      decoration: DesignConstants.cardDecoration,
      child: Column(
        children: [
          Container(
            width: DesignConstants.containerSizeLarge,
            height: DesignConstants.containerSizeLarge,
            decoration: BoxDecoration(
              color: DesignConstants.primaryColor,
              borderRadius: BorderRadius.circular(DesignConstants.radiusLarge),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignConstants.radiusLarge),
              child: Image.network(
                'https://via.placeholder.com/150',

                width: DesignConstants.containerSizeLarge,
                height: DesignConstants.containerSizeLarge,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      client!.name
                          .split(' ')
                          .map((name) => name[0])
                          .take(2)
                          .join(),
                      style: const TextStyle(
                        color: Colors.white,

                        fontWeight: DesignConstants.fontWeightSemiBold,
                        fontSize: DesignConstants.fontSizeLarge,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: DesignConstants.spacingMedium),
          Text(client!.name, style: DesignConstants.textStyleTitle),
          const SizedBox(height: DesignConstants.spacingTiny),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingSmall,
              vertical: DesignConstants.spacingTiny,
            ),
            decoration: BoxDecoration(
              color: DesignConstants.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
            ),
            child: Text(
              context
                  .l10n(
                    Provider.of<LocaleProvider>(context, listen: false).locale,
                  )
                  .t('profile.active_traveler'),
              style: DesignConstants.textStyleTiny.copyWith(
                color: DesignConstants.successColor,
                fontWeight: DesignConstants.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final l10n = context.l10n(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '${activeTrips.length}',
            l10n.t('profile.active_trips'),
            DesignConstants.primaryColor,
          ),
        ),
        const SizedBox(width: DesignConstants.spacingSmall),
        Expanded(
          child: _buildStatCard(
            '${activeTrips.expand((trip) => trip.days).length}',
            l10n.t('profile.days'),
            DesignConstants.secondaryColor,
          ),
        ),
        const SizedBox(width: DesignConstants.spacingSmall),
        Expanded(
          child: _buildStatCard(
            '${activeTrips.expand((trip) => trip.days).expand((day) => day.subFolders).length}',
            l10n.t('profile.folders'),
            DesignConstants.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(DesignConstants.spacingMedium),
      decoration: DesignConstants.cardDecoration,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: DesignConstants.fontSizeTitle,
              fontWeight: DesignConstants.fontWeightSemiBold,
              color: color,
            ),
          ),

          const SizedBox(height: DesignConstants.spacingMini),
          Text(
            label,

            style: DesignConstants.textStyleTiny.copyWith(
              color: DesignConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final l10n = context.l10n(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );
    return Container(
      padding: const EdgeInsets.all(DesignConstants.spacingLarge),
      decoration: DesignConstants.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations personnelles',
            style: DesignConstants.textStyleSubtitle,
          ),
          const SizedBox(height: DesignConstants.spacingMedium),
          _buildInfoRow(
            Icons.email_outlined,
            l10n.t('info.email'),
            client!.email,
            DesignConstants.primaryColor,
          ),
          const SizedBox(height: DesignConstants.spacingMedium),
          _buildInfoRow(
            Icons.phone_outlined,
            l10n.t('info.phone'),
            client!.phone,
            DesignConstants.secondaryColor,
          ),
          const SizedBox(height: DesignConstants.spacingMedium),
          _buildInfoRow(
            Icons.flight_takeoff_outlined,
            l10n.t('profile.last_active_trip'),
            activeTrips.isNotEmpty
                ? activeTrips.first.tripDestination
                : 'Aucun voyage actif',
            DesignConstants.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,

    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        DesignConstants.buildIconContainer(
          icon: icon,
          color: iconColor,
          size: DesignConstants.containerSizeTiny,
          iconSize: DesignConstants.iconSizeSmall,
        ),
        const SizedBox(width: DesignConstants.spacingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: DesignConstants.textStyleTiny.copyWith(
                  color: DesignConstants.textSecondary,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingMini),
              Text(value, style: DesignConstants.textStyleCaption),
            ],
          ),
        ),
      ],
    );
  }

}
