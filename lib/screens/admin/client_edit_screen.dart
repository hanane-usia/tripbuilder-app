import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/trip_models_admin.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';

class ClientEditScreen extends StatefulWidget {
  final Client client;
  final Function(Client) onUpdate;

  const ClientEditScreen({
    Key? key,
    required this.client,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ClientEditScreenState createState() => _ClientEditScreenState();
}

class _ClientEditScreenState extends State<ClientEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client.name);
    _emailController = TextEditingController(text: widget.client.email);
    _phoneController = TextEditingController(text: widget.client.phone);
    _passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientHeader(),
              SizedBox(height: 24),
              _buildPersonalInfoSection(),
              SizedBox(height: 24),
              _buildSecuritySection(),
              SizedBox(height: 24),
              _buildDangerZone(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: themeProvider.cardColor,
          boxShadow: [
            BoxShadow(
              color:
                  themeProvider.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: themeProvider.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: themeProvider.subTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7B68EE),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          'Sauvegarder',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
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
                widget.client.name.split(' ').map((e) => e[0]).take(2).join(),
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
                  'Informations Client',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ID: ${widget.client.id}',
                  style: TextStyle(
                    color: themeProvider.subTextColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF7B68EE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_rounded, color: Color(0xFF7B68EE), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.person_outline_rounded,
                  color: Color(0xFF00D7B0),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Informations Personnelles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: 'Nom et Prénom',
            icon: Icons.person_outline_rounded,
            validator:
                (value) => value?.isEmpty == true ? 'Le nom est requis' : null,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Adresse Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty == true) return 'L\'email est requis';
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value!)) {
                return 'Format d\'email invalide';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Numéro de Téléphone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator:
                (value) =>
                    value?.isEmpty == true ? 'Le téléphone est requis' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
                  Icons.security_rounded,
                  color: Color(0xFFFF6B9D),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Sécurité et Accès',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            decoration: InputDecoration(
              labelText: 'Nouveau mot de passe (optionnel)',
              hintText: 'Laisser vide pour ne pas modifier',
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF7B68EE),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Color(0xFF9FA5C0),
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFF0EFF4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFF0EFF4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF7B68EE)),
              ),
              filled: true,
              fillColor: Color(0xFFF0EFF4),
            ),
            validator: (value) {
              if (value?.isNotEmpty == true && value!.length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF7B68EE).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF7B68EE).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF7B68EE)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réinitialisation du mot de passe',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3142),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Le client recevra un email avec le nouveau mot de passe',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9FA5C0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone() {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFFF6B9D).withOpacity(0.3)),
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
                  Icons.warning_rounded,
                  color: Color(0xFFFF6B9D),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Zone Dangereuse',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Actions irréversibles qui affecteront définitivement ce client.',
            style: TextStyle(color: themeProvider.subTextColor),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFFFF6B9D).withOpacity(0.3),
                    ),
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _deleteClient,
                    icon: Icon(
                      Icons.delete_forever_rounded,
                      color: Color(0xFFFF6B9D),
                    ),
                    label: Text(
                      'Supprimer',
                      style: TextStyle(color: Color(0xFFFF6B9D)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
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
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF7B68EE)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeProvider.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: themeProvider.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF7B68EE)),
        ),
        filled: true,
        fillColor: themeProvider.backgroundColor,
      ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await ApiService.updateClient(
          clientId: widget.client.id,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password:
              _passwordController.text.trim().isNotEmpty
                  ? _passwordController.text
                  : null,
        );

        final updatedClient = Client(
          id: widget.client.id,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
        );

        widget.onUpdate(updatedClient);

        String message = 'Informations client mises à jour avec succès';
        if (result['updatedFields']?['passwordUpdated'] == true) {
          message += '\nLe mot de passe a été mis à jour';
        }

        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Color(0xFF00D7B0),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Erreur: ${e.toString()}')),
              ],
            ),
            backgroundColor: Color(0xFFFF6B9D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteClient() {
    final rootContext = context;
    showDialog(
      context: rootContext,
      builder:
          (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B9D).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFFF6B9D),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text('Supprimer le client'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B9D).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFFFF6B9D).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Color(0xFFFF6B9D),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ATTENTION: Cette action est irréversible !',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text('La suppression du client entraînera :'),
                SizedBox(height: 8),
                Text('• Suppression de tous ses voyages'),
                Text('• Suppression de tous ses documents'),
                Text('• Perte définitive de toutes les données'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(
                  'Annuler',
                  style: TextStyle(color: Color(0xFF9FA5C0)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  try {
                    await ApiService.deleteClient(widget.client.id);
                    if (!mounted) return;
                    final messenger = ScaffoldMessenger.of(rootContext);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Client supprimé avec succès'),
                            ),
                          ],
                        ),
                        backgroundColor: Color(0xFF00D7B0),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    await Future.delayed(Duration(milliseconds: 300));
                    if (!mounted) return;
                    Navigator.of(rootContext).pop(true);
                  } catch (e) {
                    _showErrorMessage(
                      'Erreur lors de la suppression: ${e.toString()}',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B9D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Supprimer Définitivement',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFFFF6B9D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 5),
      ),
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
        'Modifier le Client',
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
                color: Color(0xFF7B68EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.save_rounded, size: 20, color: Colors.white),
            ),
            onPressed: _isLoading ? null : _saveChanges,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
