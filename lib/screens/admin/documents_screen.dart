import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/trip_models_admin.dart';
import '../../widgets/admin_navigation.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DocumentsScreen extends StatefulWidget {
  @override
  _DocumentsScreenState createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedFilter = 'Tous';

  final List<Document> _allDocuments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final trips = await ApiService.getAllTrips();
      final List<Document> aggregated = [];

      for (final trip in trips) {
        try {
          final detailedTrip = await ApiService.getTripDetails(trip.id);
          for (final day in detailedTrip.days) {
            for (final folder in day.subFolders) {
              for (final doc in folder.documents) {
                aggregated.add(
                  doc.copyWith(
                    type: _normalizeType(doc.type),

                    size: _formatSizeIfNeeded(doc.size),
                  ),
                );
              }
            }
          }
        } catch (e) {}
      }

      setState(() {
        _allDocuments
          ..clear()
          ..addAll(aggregated);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AdminAppBar(
        title: 'Gestion Documents',
        currentScreen: 'documents',
        showBackButton: false,
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          _buildTabBar(),
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildErrorState(_errorMessage!)
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllDocuments(),
                        _buildRecentDocuments(),
                        _buildByTypeView(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalDocs = _allDocuments.length;
    final recentCount =
        _allDocuments
            .where(
              (d) => d.uploadDate.isAfter(
                DateTime.now().subtract(Duration(days: 7)),
              ),
            )
            .length;
    final totalSizeBytes = _sumSizesBytes(_allDocuments);
    final totalSizeLabel = _formatBytes(totalSizeBytes);

    return Container(
      margin: EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total',
              '$totalDocs',
              Icons.description_outlined,
              Color(0xFF7B68EE),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: _buildStatCard(
              'Récents',
              '$recentCount',
              Icons.schedule_outlined,
              Color(0xFF00D7B0),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: _buildStatCard(
              'Taille',
              totalSizeLabel,
              Icons.storage_outlined,
              Color(0xFFFF6B9D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: EdgeInsets.all(18),
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
              color: color.withOpacity(0.1),
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
              child: Text('Tous'),
            ),
          ),
          Tab(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text('Récents'),
            ),
          ),
          Tab(
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Text('Par Type'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDocuments() {
    final filteredDocs = _getFilteredDocuments();

    return Container(
      padding: EdgeInsets.all(20),
      child:
          filteredDocs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadDocuments,
                child: ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder:
                      (context, index) =>
                          _buildDocumentCard(filteredDocs[index]),
                ),
              ),
    );
  }

  Widget _buildRecentDocuments() {
    final recentDocs =
        _allDocuments.where((doc) {
            return doc.uploadDate.isAfter(
              DateTime.now().subtract(Duration(days: 7)),
            );
          }).toList()
          ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate));

    return Container(
      padding: EdgeInsets.all(20),
      child:
          recentDocs.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadDocuments,
                child: ListView.builder(
                  itemCount: recentDocs.length,
                  itemBuilder:
                      (context, index) => _buildDocumentCard(recentDocs[index]),
                ),
              ),
    );
  }

  Widget _buildByTypeView() {
    final Map<String, List<Document>> docsByType = {};
    for (final doc in _allDocuments) {
      docsByType.putIfAbsent(doc.type, () => []).add(doc);
    }

    return Container(
      padding: EdgeInsets.all(20),
      child: ListView.builder(
        itemCount: docsByType.keys.length,
        itemBuilder: (context, index) {
          final type = docsByType.keys.elementAt(index);
          final docs = docsByType[type]!;

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ExpansionTile(
              leading: Icon(
                _getFileTypeIcon(type),
                color: _getFileTypeColor(type),
              ),
              title: Text('$type (${docs.length})'),
              children: docs.map((doc) => _buildDocumentTile(doc)).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(Document doc) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _previewDocument(doc),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileTypeColor(doc.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getFileTypeIcon(doc.type),
                    color: _getFileTypeColor(doc.type),
                    size: 24,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '${doc.type} • ${doc.size}',
                        style: TextStyle(
                          color: Color(0xFF9FA5C0),
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Ajouté le ${DateFormat('dd/MM/yyyy à HH:mm').format(doc.uploadDate)}',
                        style: TextStyle(
                          color: Color(0xFF9FA5C0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF9FA5C0),
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Voir'),
                            ],
                          ),
                          onTap: () => _previewDocument(doc),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.download_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Télécharger'),
                            ],
                          ),
                          onTap: () => _downloadDocument(doc),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Partager'),
                            ],
                          ),
                          onTap: () => _shareDocument(doc),
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Supprimer',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          onTap: () => _deleteDocument(doc),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile(Document doc) {
    return ListTile(
      leading: Icon(
        _getFileTypeIcon(doc.type),
        color: _getFileTypeColor(doc.type),
      ),
      title: Text(doc.name),
      subtitle: Text(doc.size),
      trailing: Icon(Icons.chevron_right),
      onTap: () => _previewDocument(doc),
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
              Icons.folder_off_outlined,
              size: 48,
              color: Color(0xFF9FA5C0),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Aucun document trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3142),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ajoutez votre premier document',
            style: TextStyle(color: Color(0xFF9FA5C0), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 12),
            ElevatedButton(onPressed: _loadDocuments, child: Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  List<Document> _getFilteredDocuments() {
    return _allDocuments.where((doc) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedFilter == 'Tous' || doc.type == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Icons.picture_as_pdf_outlined;
      case 'DOCX':
      case 'DOC':
        return Icons.description_outlined;
      case 'XLSX':
      case 'XLS':
        return Icons.table_chart_outlined;
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF':
        return Color(0xFFFF6B9D);
      case 'DOCX':
      case 'DOC':
        return Color(0xFF7B68EE);
      case 'XLSX':
      case 'XLS':
        return Color(0xFF00D7B0);
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        return Color(0xFFFFAA00);
      default:
        return Color(0xFF9FA5C0);
    }
  }

  String _normalizeType(String rawType) {
    final lower = rawType.toLowerCase();
    if (lower.contains('pdf')) return 'PDF';
    if (lower.contains('word') ||
        lower.endsWith('doc') ||
        lower.endsWith('docx'))
      return 'DOCX';
    if (lower.contains('excel') ||
        lower.endsWith('xls') ||
        lower.endsWith('xlsx'))
      return 'XLSX';
    if (lower.contains('png')) return 'PNG';
    if (lower.contains('jpeg')) return 'JPEG';
    if (lower.contains('jpg')) return 'JPG';
    return rawType.toUpperCase();
  }

  String _formatSizeIfNeeded(String sizeValue) {
    if (sizeValue.contains('MB') || sizeValue.contains('KB')) return sizeValue;
    final parsed = int.tryParse(sizeValue);
    if (parsed == null) return sizeValue;
    return _formatBytes(parsed);
  }

  int _sumSizesBytes(List<Document> docs) {
    int total = 0;
    for (final d in docs) {
      final s = d.size;
      final asInt = int.tryParse(s);
      if (asInt != null) {
        total += asInt;
      }
    }
    return total;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _previewDocument(Document doc) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Aperçu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFileTypeIcon(doc.type),
                  size: 64,
                  color: _getFileTypeColor(doc.type),
                ),
                SizedBox(height: 16),
                Text(doc.name, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${doc.type} • ${doc.size}'),
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

  void _downloadDocument(Document doc) async {
    String? downloadUrl;
    String? fileName;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 12),
              Text('Préparation du téléchargement...'),
            ],
          ),
          backgroundColor: const Color(0xFF7B68EE),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      final downloadInfo = await ApiService.getDocumentDownloadUrl(doc.id);
      downloadUrl = downloadInfo['downloadUrl'];
      fileName = downloadInfo['fileName'];

      final Directory? downloadsDir = await _getDownloadsDirectory();
      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'accéder au dossier de téléchargement"),
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
          content: Text('Fichier téléchargé: $fileName'),
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
          const SnackBar(
            content: Text('Tentative de téléchargement alternatif...'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        try {
          final String localFilePath = await ApiService.downloadFile(
            downloadUrl,
            fileName,
          );
          await Share.shareXFiles([
            XFile(localFilePath),
          ], text: 'Téléchargez ce fichier: $fileName');
        } catch (e2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du téléchargement: $e2'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<Directory?> _getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        final Directory downloadsDir = Directory(
          '/storage/emulated/0/Download/tripbuilder',
        );
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      } else {
        final Directory? documentsDir =
            await getApplicationDocumentsDirectory();
        if (documentsDir != null) {
          final Directory downloadsDir = Directory(
            '${documentsDir.path}/tripbuilder',
          );
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir;
        }
      }
    } catch (_) {
      try {
        final Directory? appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          final Directory appDownloadsDir = Directory(
            '${appDir.path}/tripbuilder',
          );
          if (!await appDownloadsDir.exists()) {
            await appDownloadsDir.create(recursive: true);
          }
          return appDownloadsDir;
        }
      } catch (_) {}
    }
    return null;
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
    } catch (_) {}
  }

  void _shareDocument(Document doc) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              SizedBox(width: 12),
              Text('Préparation du partage...'),
            ],
          ),
          backgroundColor: Color(0xFF7B68EE),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      final downloadInfo = await ApiService.getDocumentDownloadUrl(doc.id);
      final String downloadUrl = downloadInfo['downloadUrl'];
      final String fileName = downloadInfo['fileName'];

      final String localFilePath = await ApiService.downloadFile(
        downloadUrl,
        fileName,
      );
      final File file = File(localFilePath);

      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(localFilePath)],
          text: 'Document partagé: ${doc.name}',
          subject: 'Partage de document',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document partagé avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Fichier non trouvé après téléchargement');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteDocument(Document doc) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Supprimer le document'),
            content: Text('Êtes-vous sûr de vouloir supprimer "${doc.name}" ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                            SizedBox(width: 12),
                            Text('Suppression en cours...'),
                          ],
                        ),
                        backgroundColor: Color(0xFF7B68EE),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    await ApiService.deleteDocument(doc.id);

                    setState(() => _allDocuments.remove(doc));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Document supprimé avec succès'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la suppression: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Supprimer', style: TextStyle(color: Colors.white)),
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
