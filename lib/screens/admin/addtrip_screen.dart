import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/trip_models_admin.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';
import 'trip_planning_screen.dart';

class CreateTripScreen extends StatefulWidget {
  final Client? client;
  const CreateTripScreen({Key? key, this.client}) : super(key: key);

  @override
  _CreateTripScreenState createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _clientPasswordCtrl = TextEditingController();
  final _tripDestinationCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool get _isExistingClient => widget.client != null;

  @override
  void initState() {
    super.initState();
    if (_isExistingClient) {
      _clientNameCtrl.text = widget.client!.name;
      _clientEmailCtrl.text = widget.client!.email;
      _clientPhoneCtrl.text = widget.client!.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                SizedBox(height: 24),
                _buildClientInfoSection(),
                if (!_isExistingClient) ...[
                  SizedBox(height: 20),
                  _buildPasswordField(),
                ],
                SizedBox(height: 32),
                _buildTripDetailsSection(),
                SizedBox(height: 100),
              ],
            ),
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
        _isExistingClient ? 'Nouveau Voyage' : 'Créer Client & Voyage',
        style: TextStyle(
          color: themeProvider.textColor,
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
                color: themeProvider.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: 20,
                color: themeProvider.textColor,
              ),
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B68EE), Color(0xFF9D88F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isExistingClient
                  ? Icons.flight_takeoff_rounded
                  : Icons.person_add_rounded,
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
                  _isExistingClient
                      ? 'Créer un nouveau voyage'
                      : 'Nouveau client et voyage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _isExistingClient
                      ? 'Pour ${widget.client!.name}'
                      : 'Remplissez les informations ci-dessous',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoSection() {
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
                  color: Color(0xFF7B68EE).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: Color(0xFF7B68EE),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Informations Client',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _clientNameCtrl,
            label: 'Nom et Prénom',
            icon: Icons.badge_outlined,
            enabled: !_isExistingClient,
            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _clientEmailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            enabled: !_isExistingClient,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _clientPhoneCtrl,
            label: 'Téléphone',
            icon: Icons.phone_outlined,
            enabled: !_isExistingClient,
            keyboardType: TextInputType.phone,
            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
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
                  color: Color(0xFFFF6B9D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Color(0xFFFF6B9D),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Sécurité',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _clientPasswordCtrl,
            obscureText: !_isPasswordVisible,
            validator:
                (v) =>
                    v == null || v.length < 6
                        ? 'Le mot de passe doit contenir au moins 6 caractères'
                        : null,
            decoration: InputDecoration(
              labelText: 'Mot de passe initial',
              prefixIcon: Icon(Icons.key_outlined, color: Color(0xFFFF6B9D)),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Color(0xFF9FA5C0),
                ),
                onPressed:
                    () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Color(0xFFF0EFF4),
              floatingLabelStyle: TextStyle(color: Color(0xFFFF6B9D)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Color(0xFFFF6B9D), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsSection() {
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
                  color: Color(0xFF00D7B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.flight_takeoff,
                  color: Color(0xFF00D7B0),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Détails du Voyage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _tripDestinationCtrl,
            label: 'Titre/Destination du voyage',
            icon: Icons.location_on_outlined,
            validator: (v) => v!.isEmpty ? 'Champ requis' : null,
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  'Date de début',
                  _startDate,
                  (date) => setState(() => _startDate = date),
                  Icons.calendar_today,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  'Date de fin',
                  _endDate,
                  (date) => setState(() => _endDate = date),
                  Icons.event,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      style: TextStyle(
        color: enabled ? themeProvider.textColor : themeProvider.subTextColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: enabled ? Color(0xFF7B68EE) : themeProvider.subTextColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor:
            enabled
                ? themeProvider.backgroundColor
                : themeProvider.dividerColor,
        floatingLabelStyle: TextStyle(color: Color(0xFF7B68EE)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF7B68EE), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? date,
    Function(DateTime) onDateSelected,
    IconData icon,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF7B68EE),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF2D3142),
                ),
                dialogBackgroundColor: Colors.white,
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) onDateSelected(pickedDate);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: themeProvider.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: date != null ? Color(0xFF7B68EE) : Colors.transparent,
            width: date != null ? 2 : 0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  date != null ? Color(0xFF7B68EE) : themeProvider.subTextColor,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.subTextColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date)
                        : 'Sélectionner',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          date != null
                              ? themeProvider.textColor
                              : themeProvider.subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: themeProvider.subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        boxShadow: [
          BoxShadow(
            color:
                themeProvider.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
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
                          'Annuler',
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
                        onPressed: _handleContinue,
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
                            Text(
                              'Continuer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
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

  void _handleContinue() async {
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('La date de fin doit être après la date de début'),
              ],
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        String tripId;
        String clientId;

        print('=== CRÉATION TRIP ===');
        print('Client existant: $_isExistingClient');

        if (_isExistingClient) {
          print('Données client existant:');
          print('- ID: ${widget.client!.id}');
          print('- Nom: ${widget.client!.name}');
          print('- Email: ${widget.client!.email}');

          final result = await ApiService.createTripForExistingClient(
            clientId: widget.client!.id,
            tripDestination: _tripDestinationCtrl.text,
            startDate: _startDate!,
            endDate: _endDate!,
          );
          tripId = result['tripId']!;
          clientId = widget.client!.id;
        } else {
          final result = await ApiService.initiateTrip(
            clientName: _clientNameCtrl.text,
            clientEmail: _clientEmailCtrl.text,
            clientPhone: _clientPhoneCtrl.text,
            clientPassword: _clientPasswordCtrl.text,
            tripDestination: _tripDestinationCtrl.text,
            startDate: _startDate!,
            endDate: _endDate!,
          );
          tripId = result['tripId']!;
          clientId = result['clientId']!;
        }

        final clientForTrip = Client(
          id: clientId,
          name: _isExistingClient ? widget.client!.name : _clientNameCtrl.text,
          email:
              _isExistingClient ? widget.client!.email : _clientEmailCtrl.text,
          phone:
              _isExistingClient ? widget.client!.phone : _clientPhoneCtrl.text,
        );

        final newTrip = Trip(
          id: tripId,
          client: clientForTrip,
          tripDestination: _tripDestinationCtrl.text,
          startDate: _startDate!,
          endDate: _endDate!,
          status: 'Draft',
          days: [],
        );

        print('=== TRIP CRÉÉ ===');
        print('Trip ID: ${newTrip.id}');
        print('Client: ${newTrip.client.name}');
        print('Email: ${newTrip.client.email}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Voyage créé avec succès!'),
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

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TripPlanningScreen(trip: newTrip),
            ),
          );
        }
      } catch (e) {
        print('Erreur: $e');
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Veuillez remplir tous les champs requis'),
            ],
          ),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _clientPasswordCtrl.dispose();
    _tripDestinationCtrl.dispose();
    super.dispose();
  }
}
