import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../models/trip_models.dart';
import '../../constants/design_constants.dart';
import '../../services/client_api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/localization.dart';

class DossiersScreen extends StatefulWidget {
  const DossiersScreen({Key? key}) : super(key: key);

  @override
  _DossiersScreenState createState() => _DossiersScreenState();
}

class _DossiersScreenState extends State<DossiersScreen>
    with WidgetsBindingObserver {
  List<Trip> trips = [];
  List<TripDay> allDays = [];
  bool isLoading = true;
  String? error;
  int? expandedDayIndex;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  DateTime? selectedDate;
  final Set<String> _expandedFolderIds = {};
  Timer? _periodicRefreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
    _loadTrips();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicRefreshTimer?.cancel();
    searchController.dispose();
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

      final clientTrips = await ClientApiService.getClientTrips();

      setState(() {
        trips = clientTrips;
        allDays = clientTrips.expand((trip) => trip.days).toList();
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

      final clientTrips = await ClientApiService.getClientTrips();

      if (mounted) {
        setState(() {
          trips = clientTrips;
          allDays = clientTrips.expand((trip) => trip.days).toList();
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

  List<TripDay> get activeDays {
    return activeTrips.expand((trip) => trip.days).toList();
  }

  List<TripDay> get filteredDays {
    return activeDays.where((day) {
      bool matchesText =
          searchQuery.isEmpty ||
          day.dayTitle.toLowerCase().contains(searchQuery) ||
          day.subFolders.any(
            (folder) =>
                folder.name.toLowerCase().contains(searchQuery) ||
                folder.documents.any(
                  (doc) => doc.name.toLowerCase().contains(searchQuery),
                ),
          );

      bool matchesDate =
          selectedDate == null ||
          _parseDate(day.date).year == selectedDate!.year &&
              _parseDate(day.date).month == selectedDate!.month &&
              _parseDate(day.date).day == selectedDate!.day;

      return matchesText && matchesDate;
    }).toList();
  }

  DateTime _parseDate(String dateString) {
    try {
      Map<String, int> monthMap = {
        "janvier": 1,
        "février": 2,
        "mars": 3,
        "avril": 4,
        "mai": 5,
        "juin": 6,
        "juillet": 7,
        "août": 8,
        "septembre": 9,
        "octobre": 10,
        "novembre": 11,
        "décembre": 12,
      };
      List<String> parts = dateString.split(' ');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = monthMap[parts[1].toLowerCase()] ?? 0;
        int year = int.parse(parts[2]);
        if (month != 0) {
          return DateTime(year, month, day);
        }
      }
    } catch (e) {}
    return DateTime.now();
  }

  Future<void> _downloadDocument(Document document) async {
    String? downloadUrl;
    String? fileName;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
              const SizedBox(width: 12),
              Text(
                context
                    .l10n(
                      Provider.of<LocaleProvider>(
                        context,
                        listen: false,
                      ).locale,
                    )
                    .t('download.preparing'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7B68EE),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      final downloadInfo = await ClientApiService.getDocumentDownloadUrl(
        document.id,
      );
      downloadUrl = downloadInfo['downloadUrl'];
      fileName = downloadInfo['fileName'];

      final Directory? downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context
                  .l10n(
                    Provider.of<LocaleProvider>(context, listen: false).locale,
                  )
                  .t('download.unavailable'),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final String filePath = '${downloadsDir.path}/$fileName';
      final dio = Dio();
      await dio.download(downloadUrl!, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context
                .l10n(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                )
                .t('download.completed', params: {'file': fileName!}),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (Platform.isAndroid) {
        await _openDownloadsFolder();
      }
    } catch (e) {
      if (downloadUrl != null && fileName != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context
                  .l10n(
                    Provider.of<LocaleProvider>(context, listen: false).locale,
                  )
                  .t('download.alt_try'),
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _downloadViaShare(downloadUrl, fileName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.l10n(Provider.of<LocaleProvider>(context, listen: false).locale).t('error.generic')}: $e',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareDocument(Document document) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
              const SizedBox(width: 12),
              Text(
                context
                    .l10n(
                      Provider.of<LocaleProvider>(
                        context,
                        listen: false,
                      ).locale,
                    )
                    .t('share.preparing'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF7B68EE),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      final downloadInfo = await ClientApiService.getDocumentDownloadUrl(
        document.id,
      );
      final String downloadUrl = downloadInfo['downloadUrl'];
      final String fileName = downloadInfo['fileName'];

      final String localFilePath = await ClientApiService.downloadFile(
        downloadUrl,
        fileName,
      );
      final File file = File(localFilePath);

      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(localFilePath)],
          text: 'Document partagé : ${document.name}',
          subject: 'Partage de document',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context
                  .l10n(
                    Provider.of<LocaleProvider>(context, listen: false).locale,
                  )
                  .t('share.success'),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('الملف غير موجود بعد التحميل');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context
                .l10n(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                )
                .t('share.error', params: {'error': e.toString()}),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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

    if (error != null) {
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

    final filteredList = filteredDays;

    return Container(
      color: DesignConstants.backgroundSecondary,
      child: RefreshIndicator(
        color: DesignConstants.primaryColor,
        backgroundColor: Colors.white,
        onRefresh: () async => _refreshTrips(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignConstants.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignConstants.spacingTiny),
              const SizedBox(height: DesignConstants.spacingLarge),
              _buildResultsHeader(filteredList.length, l10n),
              const SizedBox(height: DesignConstants.spacingMedium),
              ...filteredList.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: DesignConstants.spacingMedium,
                  ),
                  child: _buildDayCard(entry.value, entry.key),
                );
              }).toList(),
              const SizedBox(height: DesignConstants.spacingLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int count, AppLocalizations l10n) {
    return Row(
      children: [
        Text(
          l10n.t(
            'dossiers.results_days',
            params: {'count': '$count', 'plural': count > 1 ? 's' : ''},
          ),
          style: DesignConstants.textStyleBody,
        ),
        if (searchQuery.isNotEmpty || selectedDate != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingTiny,
              vertical: DesignConstants.spacingMini,
            ),
            decoration: BoxDecoration(
              color: DesignConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
            ),
            child: Text(
              l10n.t('dossiers.filtered'),
              style: DesignConstants.textStyleTiny.copyWith(
                color: DesignConstants.primaryColor,
                fontWeight: DesignConstants.fontWeightMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDayCard(TripDay day, int index) {
    bool isExpanded = expandedDayIndex == index;

    return Container(
      decoration: DesignConstants.cardDecoration,
      child: Column(
        children: [
          InkWell(
            onTap:
                () => setState(
                  () => expandedDayIndex = isExpanded ? null : index,
                ),
            borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(DesignConstants.spacingMedium),
              child: Row(
                children: [
                  DesignConstants.buildIconContainer(
                    icon: Icons.folder,
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
                          style: DesignConstants.textStyleBody,
                        ),
                        const SizedBox(height: DesignConstants.spacingMini),
                        Text(day.date, style: DesignConstants.textStyleCaption),

                        const SizedBox(height: DesignConstants.spacingMini),
                        Text(
                          '${context.l10n(Provider.of<LocaleProvider>(context, listen: false).locale).t('dossiers.id')}: ${index + 1}',
                          style: DesignConstants.textStyleTiny.copyWith(
                            color: DesignConstants.textLight,
                            fontFamily: 'monospace',
                          ),
                        ),
                        if (day.subFolders.isNotEmpty) ...[
                          const SizedBox(height: DesignConstants.spacingTiny),
                          Text(
                            context
                                .l10n(
                                  Provider.of<LocaleProvider>(
                                    context,
                                    listen: false,
                                  ).locale,
                                )
                                .t(
                                  'dossiers.subfolders_count',
                                  params: {
                                    'count': '${day.subFolders.length}',
                                    'plural':
                                        day.subFolders.length > 1 ? 's' : '',
                                  },
                                ),
                            style: DesignConstants.textStyleTiny.copyWith(
                              color: DesignConstants.primaryColor,
                              fontWeight: DesignConstants.fontWeightMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: DesignConstants.textLight,
                    size: DesignConstants.iconSizeMedium,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignConstants.spacingLarge,
                0,
                DesignConstants.spacingLarge,
                DesignConstants.spacingLarge,
              ),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: DesignConstants.spacingMedium),
                  ...day.subFolders
                      .map((subFolder) => _buildSubFolderCard(subFolder))
                      .toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubFolderCard(SubFolder subFolder) {
    final bool isExpanded = _expandedFolderIds.contains(subFolder.id);

    return Container(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingSmall),
      padding: const EdgeInsets.all(DesignConstants.spacingMedium),
      decoration: BoxDecoration(
        color: subFolder.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        border: Border.all(color: DesignConstants.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedFolderIds.remove(subFolder.id);
                } else {
                  _expandedFolderIds.add(subFolder.id);
                }
              });
            },
            child: Row(
              children: [
                DesignConstants.buildIconContainer(
                  icon: subFolder.icon,
                  color: subFolder.color,
                  size: DesignConstants.containerSizeTiny,
                  iconSize: DesignConstants.iconSizeSmall,
                ),
                const SizedBox(width: DesignConstants.spacingSmall),
                Expanded(
                  child: Text(
                    subFolder.name,
                    style: DesignConstants.textStyleCaption.copyWith(
                      fontSize: DesignConstants.fontSizeMedium,
                      fontWeight: DesignConstants.fontWeightMedium,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignConstants.spacingTiny,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: subFolder.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${subFolder.documentCount} ${context.l10n(Provider.of<LocaleProvider>(context, listen: false).locale).t('dossiers.docs_suffix')}',
                    style: DesignConstants.textStyleTiny.copyWith(
                      color: subFolder.color,
                      fontWeight: DesignConstants.fontWeightMedium,
                    ),
                  ),
                ),
                const SizedBox(width: DesignConstants.spacingSmall),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: DesignConstants.textLight,
                  size: DesignConstants.iconSizeMedium,
                ),
              ],
            ),
          ),

          if (isExpanded && subFolder.documents.isNotEmpty) ...[
            const SizedBox(height: DesignConstants.spacingMedium),
            const Divider(height: 1),
            const SizedBox(height: DesignConstants.spacingSmall),
            ...subFolder.documents
                .map((document) => _buildDocumentCard(document))
                .expand((w) => [w, const Divider(height: 1)])
                .toList()
                .take(
                  subFolder.documents.isEmpty
                      ? 0
                      : subFolder.documents.length * 2 - 1,
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Document document) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingTiny),
      padding: const EdgeInsets.all(DesignConstants.spacingSmall),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        border: Border.all(color: DesignConstants.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            _getDocumentIcon(document.type),
            color: DesignConstants.primaryColor,
            size: DesignConstants.iconSizeSmall,
          ),
          const SizedBox(width: DesignConstants.spacingSmall),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: DesignConstants.textStyleBody.copyWith(
                    fontSize: DesignConstants.fontSizeSmall,
                    fontWeight: DesignConstants.fontWeightMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignConstants.spacingMini),
                Row(
                  children: [
                    Text(
                      document.fileSize,
                      style: DesignConstants.textStyleTiny.copyWith(
                        color: DesignConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingSmall),
                    Text(
                      '•',
                      style: DesignConstants.textStyleTiny.copyWith(
                        color: DesignConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(width: DesignConstants.spacingSmall),
                    Text(
                      document.type.toUpperCase(),
                      style: DesignConstants.textStyleTiny.copyWith(
                        color: DesignConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _downloadDocument(document),
                icon: const Icon(Icons.download_rounded),
                iconSize: DesignConstants.iconSizeSmall,
                color: DesignConstants.primaryColor,
                tooltip: 'Télécharger',
              ),

              IconButton(
                onPressed: () => _shareDocument(document),
                icon: const Icon(Icons.share_rounded),
                iconSize: DesignConstants.iconSizeSmall,
                color: DesignConstants.secondaryColor,
                tooltip: 'Partager',
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'mp4':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<Directory?> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        final downloadsDir = Directory(
          '/storage/emulated/0/Download/tripbuilder',
        );
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      } else {
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _openDownloadsFolder() async {
    try {
      if (Platform.isAndroid) {
        const String tripbuilderPath =
            '/storage/emulated/0/Download/tripbuilder';
        final Uri uri = Uri.parse(
          'content://com.android.externalstorage.documents/document/primary%3ADownload%2Ftripbuilder',
        );

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          final Uri fallbackUri = Uri.parse('file://$tripbuilderPath');
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context
                .l10n(
                  Provider.of<LocaleProvider>(context, listen: false).locale,
                )
                .t('download.open_folder_fail'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadViaShare(String downloadUrl, String fileName) async {
    try {
      await Share.share(
        downloadUrl,
        subject: 'Télécharger le fichier : $fileName',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في المشاركة البديلة: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
