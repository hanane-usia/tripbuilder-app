import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../models/trip_models_admin.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';

class DocumentManagementScreen extends StatefulWidget {
  final Trip trip;
  final SubFolder subFolder;
  final TripDay tripDay;
  final VoidCallback onUpdate;

  const DocumentManagementScreen({
    Key? key,
    required this.trip,
    required this.subFolder,
    required this.tripDay,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _DocumentManagementScreenState createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<void> _handleFileUpload(PlatformFile file) async {
    try {
      setState(() => _isUploading = true);
      final uploadResult = await ApiService.uploadDocument(
        tripId: widget.trip.id,
        dayId: widget.tripDay.id,
        folderId: widget.subFolder.id,
        file: file,
      );

      final String newDocId =
          uploadResult['document']?['documentId'] ??
          uploadResult['documentId'] ??
          uploadResult['id'] ??
          'unknown';

      _addDocumentLocallyWithId(
        newDocId,
        file.name,
        file.extension ?? 'unknown',
        file.size,
      );
      _showSuccessSnackBar('Document ajouté avec succès !');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'upload : ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      await _handleFileUpload(result.files.first);
    }
  }

  Future<void> _takePicture() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      final file = await _xFileToPlatformFile(image);
      await _handleFileUpload(file);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null) {
      final file = await _xFileToPlatformFile(image);
      await _handleFileUpload(file);
    }
  }

  void _addDocumentLocallyWithId(
    String id,
    String fileName,
    String extension,
    int sizeBytes,
  ) {
    setState(() {
      widget.subFolder.documents.add(
        Document(
          id: id,
          name: fileName,
          type: extension.toLowerCase(),
          path: '/documents/$fileName',
          uploadDate: DateTime.now(),
          size: _formatFileSize(sizeBytes),
        ),
      );
    });
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subFolder.name,
              style: TextStyle(color: themeProvider.textColor),
            ),
            Text(
              widget.tripDay.dayTitle,
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.subTextColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: themeProvider.cardColor,
        elevation: 1,
        shadowColor:
            themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
        iconTheme: IconThemeData(color: themeProvider.textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.sort, color: themeProvider.textColor),
            onPressed: _isUploading ? null : _showSortOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildUploadArea(),
              Expanded(
                child:
                    widget.subFolder.documents.isEmpty
                        ? _buildEmptyState()
                        : _buildDocumentList(),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Envoi en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _showAddDocumentOptions,
        backgroundColor: _isUploading ? Colors.grey : const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUploadArea() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                themeProvider.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Color(0xFF6366F1),
          ),
          const SizedBox(height: 12),
          const Text(
            'Glissez-déposez vos fichiers ici',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ou cliquez pour parcourir vos fichiers',
            style: TextStyle(color: themeProvider.subTextColor),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickUploadButton(Icons.file_present, 'Fichier', _pickFile),
              _buildQuickUploadButton(Icons.camera_alt, 'Caméra', _takePicture),
              _buildQuickUploadButton(
                Icons.photo_library,
                'Galerie',
                _pickImage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickUploadButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: _isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6366F1), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: widget.subFolder.documents.length,
      itemBuilder:
          (context, index) =>
              _buildDocumentCard(widget.subFolder.documents[index], index),
    );
  }

  Widget _buildDocumentCard(Document doc, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor:
          themeProvider.isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
      color: themeProvider.cardColor,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getFileTypeIcon(doc.type),
                  color: _getFileTypeColor(doc.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: themeProvider.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doc.type.toUpperCase()} • ${doc.size} • ${DateFormat('dd/MM/yy').format(doc.uploadDate)}',
                      style: TextStyle(
                        color: themeProvider.subTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_vert, color: themeProvider.subTextColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder:
                    (context) => <PopupMenuEntry>[
                      PopupMenuItem(
                        onTap: () => _previewDocument(doc),
                        child: const ListTile(
                          leading: Icon(Icons.visibility_outlined, size: 20),
                          title: Text('Aperçu'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () => _renameDocument(doc),
                        child: const ListTile(
                          leading: Icon(Icons.edit_outlined, size: 20),
                          title: Text('Renommer'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () => _downloadDocument(doc),
                        child: const ListTile(
                          leading: Icon(Icons.download_outlined, size: 20),
                          title: Text('Télécharger'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () => _shareDocument(doc),
                        child: const ListTile(
                          leading: Icon(Icons.share_outlined, size: 20),
                          title: Text('Partager'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        onTap: () => _deleteDocument(index),
                        child: const ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          title: Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 80,
            color: themeProvider.subTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun document ici',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez votre premier document',
            style: TextStyle(color: themeProvider.subTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddDocumentOptions,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDocumentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.upload_file,
                    color: Color(0xFF6366F1),
                  ),
                  title: const Text('Uploader un fichier'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF6366F1),
                  ),
                  title: const Text('Prendre une photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF6366F1),
                  ),
                  title: const Text('Choisir depuis la galerie'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _previewDocument(Document doc) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Aperçu du document'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFileTypeIcon(doc.type),
                  size: 64,
                  color: _getFileTypeColor(doc.type),
                ),
                const SizedBox(height: 16),
                Text(
                  doc.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Type: ${doc.type.toUpperCase()}'),
                Text('Taille: ${doc.size}'),
                Text(
                  'Ajouté le: ${DateFormat('dd/MM/yyyy à HH:mm').format(doc.uploadDate)}',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _downloadDocument(Document doc) async {
    String? downloadUrl;
    String? fileName;

    try {
      setState(() => _isUploading = true);
      _showSuccessSnackBar('Préparation du téléchargement...');

      final downloadInfo = await ApiService.getDocumentDownloadUrl(doc.id);
      downloadUrl = downloadInfo['downloadUrl'];
      fileName = downloadInfo['fileName'];

      Directory? downloadsDir = await _getDownloadsDirectory();

      if (downloadsDir == null) {
        _showErrorSnackBar(
          'Impossible d\'accéder au dossier de téléchargement',
        );
        return;
      }

      final String filePath = '${downloadsDir.path}/$fileName';

      final dio = Dio();
      await dio.download(downloadUrl!, filePath);

      _showSuccessSnackBar('Fichier téléchargé: $fileName');

      if (Platform.isAndroid) {
        await _openDownloadsFolder();
      }
    } catch (e) {
      if (downloadUrl != null && fileName != null) {
        _showErrorSnackBar('Tentative de téléchargement alternatif...');
        await _downloadViaShare(downloadUrl, fileName);
      } else {
        _showErrorSnackBar('Erreur lors du téléchargement : ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _deleteDocument(int index) {
    final doc = widget.subFolder.documents[index];
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer le document'),
            content: Text('Êtes-vous sûr de vouloir supprimer "${doc.name}" ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _performDeleteDocument(doc, index);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _performDeleteDocument(Document doc, int index) async {
    try {
      setState(() => _isUploading = true);
      await ApiService.deleteDocument(doc.id);

      setState(() {
        widget.subFolder.documents.removeAt(index);
      });
      widget.onUpdate();
      _showSuccessSnackBar('Document supprimé avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression : ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _renameDocument(Document doc) {
    final TextEditingController controller = TextEditingController(
      text: doc.name,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Renommer le document'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nouveau nom',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty && newName != doc.name) {
                    Navigator.pop(context);
                    await _performRenameDocument(doc, newName);
                  } else if (newName.isEmpty) {
                    _showErrorSnackBar('Le nom ne peut pas être vide');
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Renommer'),
              ),
            ],
          ),
    );
  }

  Future<void> _performRenameDocument(Document doc, String newName) async {
    try {
      setState(() => _isUploading = true);
      await ApiService.renameDocument(doc.id, newName);

      setState(() {
        doc.name = newName;
      });
      widget.onUpdate();
      _showSuccessSnackBar('Document renommé avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors du renommage : ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSortOptions() {}

  Future<PlatformFile> _xFileToPlatformFile(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    return PlatformFile(
      name: xFile.name,
      bytes: bytes,
      size: await xFile.length(),
      path: xFile.path,
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red.shade400;
      case 'doc':
      case 'docx':
        return Colors.blue.shade400;
      case 'xls':
      case 'xlsx':
        return Colors.green.shade400;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _downloadViaShare(String downloadUrl, String fileName) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = '${tempDir.path}/$fileName';

      final dio = Dio();
      await dio.download(downloadUrl, tempPath);

      await Share.shareXFiles(
        [XFile(tempPath)],
        text: 'Téléchargez ce fichier: $fileName',
        subject: 'Fichier téléchargé - ${widget.trip.tripDestination}',
      );

      _showSuccessSnackBar('Fichier prêt pour le téléchargement');
    } catch (e) {
      _showErrorSnackBar(
        'Erreur lors du téléchargement alternatif: ${e.toString()}',
      );
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
    } catch (e) {
      print('Error getting downloads directory: $e');

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
      } catch (e2) {
        print('Error with app directory fallback: $e2');
      }
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
    } catch (e) {
      _showErrorSnackBar('Impossible d\'ouvrir le dossier tripbuilder');
    }
  }

  void _shareDocument(Document doc) async {
    try {
      setState(() => _isUploading = true);
      _showSuccessSnackBar('Préparation du partage...');

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
          subject: 'Partage de document - ${widget.trip.tripDestination}',
        );

        _showSuccessSnackBar('Document partagé avec succès');
      } else {
        throw Exception('Fichier non trouvé après téléchargement');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du partage: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }
}
