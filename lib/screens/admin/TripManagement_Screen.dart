import 'package:flutter/material.dart';
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
import 'DocumentManagement_Screen.dart';
import 'client_edit_screen.dart';

class TripManagementScreen extends StatefulWidget {
  final Trip trip;
  TripManagementScreen({required this.trip});

  @override
  _TripManagementScreenState createState() => _TripManagementScreenState();
}

class _TripManagementScreenState extends State<TripManagementScreen>
    with SingleTickerProviderStateMixin {
  late Trip _trip;
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
    _tabController = TabController(length: 3, vsync: this);
    _loadTripDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTripDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final tripDetails = await ApiService.getTripDetails(_trip.id);

      setState(() {
        _trip = tripDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: themeProvider.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF7B68EE),
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Chargement des détails...',
                style: TextStyle(color: themeProvider.subTextColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: RefreshIndicator(
        color: Color(0xFF7B68EE),
        onRefresh: _loadTripDetails,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildSliverAppBar(),
            _buildQuickStats(),
            _buildTabBar(),
            _buildTabContent(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: themeProvider.cardColor,
      elevation: 0,
      centerTitle: false,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _trip.client?.name ?? 'Client inconnu',
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _trip.tripDestination ?? 'Voyage',
            style: TextStyle(
              color: themeProvider.subTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
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
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_outlined,
              size: 20,
              color: themeProvider.textColor,
            ),
          ),
          onPressed: _editClient,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Provider.of<ThemeProvider>(context).cardColor,
                Provider.of<ThemeProvider>(context).backgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildQuickStats() {
    final totalDays = _trip.days?.length ?? 0;
    final totalSubFolders = _trip.totalSubFolders;
    final totalDocuments = _trip.totalDocuments;

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        height: 100,
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jours',
                '$totalDays',
                Icons.calendar_today,
                Color(0xFF00D7B0),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Dossiers',
                '$totalSubFolders',
                Icons.folder,
                Color(0xFFFF6B9D),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Documents',
                '$totalDocuments',
                Icons.description,
                Color(0xFFFFAA00),
              ),
            ),
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
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: EdgeInsets.all(16),
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeProvider.textColor,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: themeProvider.subTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  SliverPersistentHeader _buildTabBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        Container(
          color: themeProvider.backgroundColor,
          child: Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeProvider.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(color: Color(0xFF7B68EE)),
              labelColor: Colors.white,
              unselectedLabelColor: themeProvider.subTextColor,
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Itinéraire'),
                Tab(text: 'Documents'),
                Tab(text: 'Informations'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverFillRemaining _buildTabContent() {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [_buildItineraryTab(), _buildDocumentsTab(), _buildInfoTab()],
      ),
    );
  }

  Widget _buildItineraryTab() {
    if (_trip.days == null || _trip.days!.isEmpty) {
      return _buildEmptyState(
        Icons.calendar_view_day_outlined,
        'Aucun jour planifié',
        'Commencez par ajouter votre premier jour',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: _trip.days!.length,
      itemBuilder: (context, index) => _buildDayCard(_trip.days![index], index),
    );
  }

  Widget _buildDayCard(TripDay day, int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = [
      Color(0xFF7B68EE),
      Color(0xFF00D7B0),
      Color(0xFFFF6B9D),
      Color(0xFFFFAA00),
      Color(0xFF4ECDC4),
    ];
    final cardColor = colors[index % colors.length];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.05),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                        day.dayTitle ?? 'Jour ${index + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        day.date ?? 'Date non définie',
                        style: TextStyle(
                          color: themeProvider.subTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: themeProvider.subTextColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Modifier'),
                            ],
                          ),
                          onTap: () => _editDay(day, index),
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
                          onTap: () => _confirmDeleteDay(index),
                        ),
                      ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                if (day.subFolders != null && day.subFolders!.isNotEmpty) ...[
                  ...day.subFolders!
                      .map((sf) => _buildSubFolderCard(sf, day))
                      .toList(),
                  SizedBox(height: 12),
                ],
                InkWell(
                  onTap: () => _addSubFolder(day),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: cardColor.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: cardColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ajouter un sous-dossier',
                          style: TextStyle(
                            color: cardColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
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

  Widget _buildSubFolderCard(SubFolder subFolder, TripDay day) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: themeProvider.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (subFolder.color ?? Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            subFolder.icon ?? Icons.folder,
            color: subFolder.color ?? Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          subFolder.name ?? 'Dossier sans nom',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: themeProvider.textColor,
          ),
        ),
        subtitle: Text(
          '${subFolder.documentCount} document(s)',
          style: TextStyle(color: themeProvider.subTextColor, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.folder_open, size: 18, color: Color(0xFF7B68EE)),
              onPressed: () => _openSubFolder(subFolder, day),
            ),
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: themeProvider.subTextColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Renommer'),
                        ],
                      ),
                      onTap: () => _renameSubFolder(subFolder, day),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                      onTap: () => _deleteSubFolder(subFolder, day),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    Document document,
    TripDay day,
    int dayIndex,
    SubFolder subFolder,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = [
      Color(0xFF7B68EE),
      Color(0xFF00D7B0),
      Color(0xFFFF6B9D),
      Color(0xFFFFAA00),
      Color(0xFF4ECDC4),
    ];
    final dayColor = colors[dayIndex % colors.length];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: dayColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getDocumentIcon(document.type),
            color: dayColor,
            size: 24,
          ),
        ),
        title: Text(
          document.name ?? 'Document sans nom',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: themeProvider.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: dayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Jour ${dayIndex + 1}',
                    style: TextStyle(
                      color: dayColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (subFolder.color ?? Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subFolder.name ?? 'Dossier',
                    style: TextStyle(
                      color: subFolder.color ?? Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '${document.uploadDate ?? 'Date inconnue'}',
              style: TextStyle(color: themeProvider.subTextColor, fontSize: 12),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: themeProvider.subTextColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Télécharger'),
                    ],
                  ),
                  onTap: () => _downloadDocument(document),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Partager'),
                    ],
                  ),
                  onTap: () => _shareDocument(document),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () => _deleteDocument(document, day, subFolder),
                ),
              ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    List<Map<String, dynamic>> allDocuments = [];

    if (_trip.days != null) {
      for (int dayIndex = 0; dayIndex < _trip.days!.length; dayIndex++) {
        final day = _trip.days![dayIndex];
        if (day.subFolders != null) {
          for (final subFolder in day.subFolders!) {
            if (subFolder.documents != null) {
              for (final document in subFolder.documents!) {
                allDocuments.add({
                  'document': document,
                  'day': day,
                  'dayIndex': dayIndex,
                  'subFolder': subFolder,
                });
              }
            }
          }
        }
      }
    }

    if (allDocuments.isEmpty) {
      return _buildEmptyState(
        Icons.description_outlined,
        'Aucun document',
        'Les documents apparaîtront ici une fois ajoutés',
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: allDocuments.length,
      itemBuilder: (context, index) {
        final item = allDocuments[index];
        final document = item['document'] as Document;
        final day = item['day'] as TripDay;
        final dayIndex = item['dayIndex'] as int;
        final subFolder = item['subFolder'] as SubFolder;

        return _buildDocumentCard(document, day, dayIndex, subFolder);
      },
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoCard(
            'Détails du voyage',
            Icons.info_outline,
            Color(0xFF7B68EE),
            [
              _buildInfoItem(
                'Destination',
                _trip.tripDestination ?? 'Non définie',
              ),
              _buildInfoItem(
                'Durée',
                '${_trip.endDate.difference(_trip.startDate).inDays + 1} jours',
              ),
              _buildInfoItem('Statut', _trip.status ?? 'En cours'),
              _buildInfoItem('ID du voyage', _trip.id),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoCard(
            'Informations client',
            Icons.person_outline,
            Color(0xFF00D7B0),
            [
              _buildInfoItem('Nom', _trip.client?.name ?? 'Non défini'),
              _buildInfoItem('Email', _trip.client?.email ?? 'Non défini'),
              _buildInfoItem('Téléphone', _trip.client?.phone ?? 'Non défini'),
              _buildInfoItem('ID client', _trip.client?.id ?? 'Non défini'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> items,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: EdgeInsets.all(20),
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: themeProvider.subTextColor, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: themeProvider.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: themeProvider.subTextColor),
          ),
          SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: themeProvider.subTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeProvider.subTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadTripDetails,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7B68EE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _addDay,
      backgroundColor: Color(0xFF7B68EE),
      child: Icon(Icons.add, color: Colors.white),
    );
  }

  void _editClient() async {
    final refreshDashboard = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (context) => ClientEditScreen(
              client: _trip.client,
              onUpdate: (updatedClient) async {
                try {
                  await ApiService.updateClient(
                    clientId: _trip.client.id,
                    name: updatedClient.name,
                    email: updatedClient.email,
                    phone: updatedClient.phone,
                  );

                  setState(() {
                    _trip.client.name = updatedClient.name;
                    _trip.client.email = updatedClient.email;
                    _trip.client.phone = updatedClient.phone;
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

  void _editDay(TripDay day, int index) {
    final titleController = TextEditingController(text: day.dayTitle);
    final descriptionController = TextEditingController(text: day.description);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Modifier le jour'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nom du jour',
                    hintText: 'Nom...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Ajouter une description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nouveauNom = titleController.text.trim();
                  final nouvelleDescription = descriptionController.text.trim();
                  if (nouveauNom.isNotEmpty) {
                    setState(() {
                      day.dayTitle = nouveauNom;
                      day.description = nouvelleDescription;
                    });
                    try {
                      await ApiService.updateDay(
                        tripId: _trip.id,
                        dayId: day.id,
                        dayTitle: nouveauNom,
                        description: nouvelleDescription,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Jour modifié avec succès'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Erreur lors de la modification du jour',
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(
                  'Enregistrer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteDay(int index) {
    final day = _trip.days![index];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Supprimer le jour'),
              ],
            ),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer "${day.dayTitle}" ? Cette action supprimera aussi tous les sous-dossiers et documents associés.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiService.deleteDay(tripId: _trip.id, dayId: day.id);

                    Navigator.pop(context);
                    await _loadTripDetails();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Jour supprimé avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
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

  void _addSubFolder(TripDay day) {
    _showSubFolderDialog(day);
  }

  void _showSubFolderDialog(TripDay day) {
    final nameController = TextEditingController();
    String selectedFolderName = '';

    final predefinedFolders = [
      {'name': 'Vols', 'icon': Icons.flight, 'color': Colors.blue},
      {'name': 'Hébergement', 'icon': Icons.hotel, 'color': Colors.green},
      {
        'name': 'Transport',
        'icon': Icons.directions_car,
        'color': Colors.orange,
      },
      {'name': 'Activités', 'icon': Icons.tour, 'color': Colors.purple},
      {'name': 'Restaurants', 'icon': Icons.restaurant, 'color': Colors.red},
      {'name': 'Documents', 'icon': Icons.description, 'color': Colors.teal},
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('Nouveau sous-dossier'),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxHeight: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du dossier',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedFolderName = value;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Ou choisir un modèle prédéfini :',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: predefinedFolders.length,
                        itemBuilder: (context, index) {
                          final folder = predefinedFolders[index];
                          final isSelected =
                              selectedFolderName == folder['name'];

                          return Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  nameController.text =
                                      folder['name'] as String;
                                  selectedFolderName = folder['name'] as String;
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? (folder['color'] as Color)
                                              .withOpacity(0.2)
                                          : (folder['color'] as Color)
                                              .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? folder['color'] as Color
                                            : (folder['color'] as Color)
                                                .withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      folder['icon'] as IconData,
                                      color: folder['color'] as Color,
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      folder['name'] as String,
                                      style: TextStyle(
                                        color: folder['color'] as Color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      IconData selectedIcon = Icons.folder;
                      Color selectedColor = Colors.grey;

                      for (var folder in predefinedFolders) {
                        if (nameController.text == folder['name']) {
                          selectedIcon = folder['icon'] as IconData;
                          selectedColor = folder['color'] as Color;
                          break;
                        }
                      }

                      try {
                        await ApiService.addSubFolderToDay(
                          tripId: _trip.id,
                          dayId: day.id,
                          name: nameController.text,
                          icon: _getIconName(selectedIcon),
                          color: _getColorName(selectedColor),
                        );

                        await _loadTripDetails();

                        Navigator.pop(context);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sous-dossier "${nameController.text}" ajouté avec succès',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de l\'ajout: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openSubFolder(SubFolder subFolder, TripDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DocumentManagementScreen(
              trip: _trip,
              subFolder: subFolder,
              tripDay: day,
              onUpdate: () => _loadTripDetails(),
            ),
      ),
    );
  }

  void _renameSubFolder(SubFolder subFolder, TripDay day) {
    final TextEditingController controller = TextEditingController(
      text: subFolder.name,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Renommer le dossier'),
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
                  if (newName.isNotEmpty && newName != subFolder.name) {
                    Navigator.pop(context);
                    await _performRenameSubFolder(subFolder, day, newName);
                  } else if (newName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le nom ne peut pas être vide'),
                        backgroundColor: Colors.red,
                      ),
                    );
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

  Future<void> _performRenameSubFolder(
    SubFolder subFolder,
    TripDay day,
    String newName,
  ) async {
    try {
      await ApiService.renameSubFolder(
        tripId: _trip.id,
        dayId: day.id,
        folderId: subFolder.id,
        newName: newName,
      );

      setState(() {
        subFolder.name = newName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dossier renommé en "$newName"'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du renommage: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deleteSubFolder(SubFolder subFolder, TripDay day) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Supprimer le dossier'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Êtes-vous sûr de vouloir supprimer "${subFolder.name}" ?',
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cette action supprimera aussi tous les ${subFolder.documentCount} document(s) du dossier.',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiService.deleteSubFolder(
                      tripId: _trip.id,
                      dayId: day.id,
                      folderId: subFolder.id,
                    );

                    Navigator.pop(context);
                    await _loadTripDetails();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dossier supprimé avec succès'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
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

  void _addDay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final titleController = TextEditingController();
        final descriptionController = TextEditingController();
        DateTime selectedDate = DateTime.now();

        return StatefulBuilder(
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
                      Icons.add_circle_outline,
                      color: Color(0xFF7B68EE),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Ajouter un jour'),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Titre du jour',
                        prefixIcon: Icon(Icons.title, color: Color(0xFF7B68EE)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Color(0xFFF0EFF4),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(
                          Icons.description,
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
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
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
                            selectedDate = picked;
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
                              DateFormat('dd/MM/yyyy').format(selectedDate),
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
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
                    if (titleController.text.isNotEmpty) {
                      try {
                        await ApiService.addDayToTrip(
                          tripId: _trip.id,
                          dayTitle: titleController.text,
                          description: descriptionController.text,
                          date: DateFormat('yyyy-MM-dd').format(selectedDate),
                        );

                        Navigator.pop(context);
                        await _loadTripDetails();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Jour ajouté avec succès'),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7B68EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Ajouter', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getIconName(IconData icon) {
    if (icon == Icons.flight) return 'flight';
    if (icon == Icons.hotel) return 'hotel';
    if (icon == Icons.directions_car) return 'directions_car';
    if (icon == Icons.tour) return 'tour';
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.description) return 'description';
    return 'folder';
  }

  String _getColorName(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.red) return 'red';
    if (color == Colors.teal) return 'teal';
    return 'blue';
  }

  IconData _getDocumentIcon(String? fileType) {
    if (fileType == null) return Icons.description;

    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.description;
    }
  }

  String _formatFileSize(int? fileSize) {
    if (fileSize == null) return 'Taille inconnue';

    if (fileSize < 1024) {
      return '${fileSize} B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _downloadDocument(Document document) async {
    String? downloadUrl;
    String? fileName;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.download, color: Colors.white),
              SizedBox(width: 8),
              Text('Préparation du téléchargement...'),
            ],
          ),
          backgroundColor: Color(0xFF00D7B0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      final downloadInfo = await ApiService.getDocumentDownloadUrl(document.id);
      downloadUrl = downloadInfo['downloadUrl'];
      fileName = downloadInfo['fileName'];

      Directory? downloadsDir = await _getDownloadsDirectory();

      if (downloadsDir == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'accéder au dossier de téléchargement'),
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
          SnackBar(
            content: Text('Tentative de téléchargement alternatif...'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _downloadViaShare(downloadUrl, fileName);
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

  void _shareDocument(Document document) async {
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

      final downloadInfo = await ApiService.getDocumentDownloadUrl(document.id);
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
          text: 'Document partagé: ${document.name}',
          subject: 'Partage de document - ${_trip.tripDestination}',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Document partagé avec succès'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        throw Exception('Fichier non trouvé après téléchargement');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur lors du partage: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _deleteDocument(Document document, TripDay day, SubFolder subFolder) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Supprimer le document'),
              ],
            ),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer "${document.name}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiService.deleteDocument(document.id);

                    Navigator.pop(context);
                    await _loadTripDetails();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Document supprimé avec succès'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
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

  void _deleteTrip() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: Colors.red),
                ),
                SizedBox(width: 12),
                Text('Supprimer le voyage'),
              ],
            ),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer ce voyage ? Cette action est irréversible et supprimera tous les documents associés.',
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
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Voyage supprimé'),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Supprimer', style: TextStyle(color: Colors.white)),
              ),
            ],
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
        subject: 'Fichier téléchargé - ${_trip.tripDestination}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fichier prêt pour le téléchargement'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du téléchargement alternatif: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'ouvrir le dossier tripbuilder'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate(this.child);

  @override
  double get minExtent => 88.0;
  @override
  double get maxExtent => 88.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
