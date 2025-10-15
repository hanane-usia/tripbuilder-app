import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/trip_models.dart';

import '../../constants/design_constants.dart';
import '../../services/client_api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/localization.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  List<Trip> trips = [];
  bool isLoading = true;
  String? error;
  Timer? _periodicRefreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTrips();
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

  Future<void> _loadTrips() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print('🔄 Chargement des voyages du client...');
      final clientTrips = await ClientApiService.getClientTrips();
      print('📊 Reçu ${clientTrips.length} voyages');

      for (int i = 0; i < clientTrips.length; i++) {
        final trip = clientTrips[i];
        print('Voyage $i: ${trip.tripDestination}');
        print('  - Client: ${trip.client.name}');
        print('  - Jours: ${trip.days.length}');
      }

      setState(() {
        trips = clientTrips;
        isLoading = false;
        _lastRefreshTime = DateTime.now();
      });
    } catch (e) {
      print('❌ Erreur lors du chargement des voyages: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _refreshTrips() {
    setState(() {
      _lastRefreshTime = DateTime.now();
    });
    _loadTrips();
    HapticFeedback.lightImpact();
  }

  Future<void> _refreshTripsSilently() async {
    try {
      setState(() {
        _lastRefreshTime = DateTime.now();
      });

      print('🔄 Silent refresh - Chargement des voyages du client...');
      final clientTrips = await ClientApiService.getClientTrips();
      print('📊 Silent refresh - Reçu ${clientTrips.length} voyages');

      if (mounted) {
        setState(() {
          trips = clientTrips;
        });
      }
    } catch (e) {
      print('❌ Silent refresh - Erreur lors du chargement des voyages: $e');
    }
  }

  void _autoRefreshData() {
    if (_lastRefreshTime == null ||
        DateTime.now().difference(_lastRefreshTime!).inSeconds > 5) {
      _refreshTripsSilently();
    }
  }

  void _startPeriodicRefresh() {
    _periodicRefreshTimer?.cancel();
    _periodicRefreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshTripsSilently();
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
        color: DesignConstants.backgroundPrimary,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Container(
        color: DesignConstants.backgroundPrimary,
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
                error!,
                style: DesignConstants.textStyleCaption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTrips,
                child: Text(l10n.t('common.retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (activeTrips.isEmpty) {
      return Container(
        color: DesignConstants.backgroundPrimary,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flight_takeoff,
                size: 64,
                color: DesignConstants.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.t('dashboard.no_active_title'),
                style: DesignConstants.textStyleTitle,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('dashboard.no_active_subtitle'),
                style: DesignConstants.textStyleCaption,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: DesignConstants.backgroundPrimary,
      child: RefreshIndicator(
        color: DesignConstants.primaryColor,
        backgroundColor: Colors.white,
        onRefresh: () async => _refreshTrips(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignConstants.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTripsList(),
              const SizedBox(height: DesignConstants.spacingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mes voyages",
          style: DesignConstants.textStyleTitle.copyWith(
            fontSize: DesignConstants.fontSizeLarge,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingMedium),
        ...activeTrips
            .map(
              (trip) => Padding(
                padding: const EdgeInsets.only(
                  bottom: DesignConstants.spacingMedium,
                ),
                child: _buildTripCard(trip),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildTripCard(Trip trip) {
    return Container(
      padding: const EdgeInsets.all(DesignConstants.spacingMedium),
      decoration: DesignConstants.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(DesignConstants.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: DesignConstants.containerSizeSmall,
                height: DesignConstants.containerSizeSmall,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      DesignConstants.primaryColor,
                      DesignConstants.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    DesignConstants.radiusMedium,
                  ),
                ),
                child: const Icon(
                  Icons.flight_takeoff_rounded,
                  color: Colors.white,
                  size: DesignConstants.iconSizeMedium,
                ),
              ),
              const SizedBox(width: DesignConstants.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.tripDestination,
                      style: DesignConstants.textStyleTitle.copyWith(
                        fontSize: DesignConstants.fontSizeMedium,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingMini),
                    Text(
                      context
                          .l10n(
                            Provider.of<LocaleProvider>(
                              context,
                              listen: false,
                            ).locale,
                          )
                          .t('dashboard.trip_type'),
                      style: DesignConstants.textStyleCaption.copyWith(
                        fontSize: DesignConstants.fontSizeSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingMedium),
          const Divider(height: 1),
          const SizedBox(height: DesignConstants.spacingMedium),
          _buildInfoRow(
            Icons.person_outline_rounded,
            context
                .l10n(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                )
                .t('info.client'),
            trip.client.name,
            DesignConstants.primaryColor,
          ),
          const SizedBox(height: DesignConstants.spacingMedium),
          _buildInfoRow(
            Icons.email_outlined,
            context
                .l10n(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                )
                .t('info.email'),
            trip.client.email,
            DesignConstants.secondaryColor,
          ),
          const SizedBox(height: DesignConstants.spacingMedium),
          _buildInfoRow(
            Icons.phone_outlined,
            context
                .l10n(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                )
                .t('info.phone'),
            trip.client.phone,
            DesignConstants.accentColor,
          ),
          if (trip.days.isNotEmpty) ...[
            const SizedBox(height: DesignConstants.spacingMedium),
            _buildTimelineSection(trip),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineSection(Trip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Programme du voyage",
          style: DesignConstants.textStyleTitle.copyWith(
            fontSize: DesignConstants.fontSizeMedium,
          ),
        ),
        const SizedBox(height: DesignConstants.spacingSmall),
        ...trip.days.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(
              bottom: DesignConstants.spacingSmall,
            ),
            child: _buildDayCard(
              entry.value,
              entry.key == trip.days.length - 1,
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDayCard(TripDay day, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(DesignConstants.spacingMedium),
      decoration: DesignConstants.cardDecoration.copyWith(
        borderRadius: BorderRadius.circular(DesignConstants.radiusLarge),
      ),
      child: Column(
        children: [
          Row(
            children: [
              DesignConstants.buildIconContainer(
                icon: Icons.calendar_today_rounded,
                color: DesignConstants.primaryColor,
                size: DesignConstants.containerSizeSmall,
                iconSize: DesignConstants.iconSizeMedium,
              ),
              const SizedBox(width: DesignConstants.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.dayTitle,
                      style: DesignConstants.textStyleBody.copyWith(
                        fontWeight: DesignConstants.fontWeightSemiBold,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingMini),
                    Text(day.date, style: DesignConstants.textStyleCaption),
                    if (day.description.isNotEmpty) ...[
                      const SizedBox(height: DesignConstants.spacingMini),
                      Text(
                        day.description,
                        style: DesignConstants.textStyleCaption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingMedium),
          ...day.events
              .map((event) => _buildEventItem(event))
              .expand((w) => [w, const Divider(height: 1)])
              .toList()
              .take(day.events.isEmpty ? 0 : day.events.length * 2 - 1)
              .toList(),
        ],
      ),
    );
  }

  Widget _buildEventItem(TripEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingSmall),
      padding: const EdgeInsets.all(DesignConstants.spacingSmall),
      decoration: BoxDecoration(
        color: DesignConstants.backgroundPrimary,
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        border: Border.all(color: DesignConstants.borderColor, width: 1),
      ),
      child: Row(
        children: [
          DesignConstants.buildIconContainer(
            icon: event.icon,
            color: event.color,
            size: DesignConstants.containerSizeTiny,
            iconSize: DesignConstants.iconSizeSmall,
          ),
          const SizedBox(width: DesignConstants.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: DesignConstants.textStyleBody),
                const SizedBox(height: DesignConstants.spacingMini),
                Text(event.location, style: DesignConstants.textStyleCaption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String? value,
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
                title,
                style: DesignConstants.textStyleCaption.copyWith(
                  fontSize: DesignConstants.fontSizeTiny,
                ),
              ),
              const SizedBox(height: DesignConstants.spacingMini),
              Text(value ?? '', style: DesignConstants.textStyleBody),
            ],
          ),
        ),
      ],
    );
  }
}
