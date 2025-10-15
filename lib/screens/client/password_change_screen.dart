import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/design_constants.dart';
import '../../services/client_api_service.dart';
import '../login_screen.dart';
import '../../providers/locale_provider.dart';
import '../../services/localization.dart';

class PasswordChangeScreen extends StatefulWidget {
  const PasswordChangeScreen({Key? key}) : super(key: key);

  @override
  _PasswordChangeScreenState createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ClientApiService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        final l10n = context.l10n(
          Provider.of<LocaleProvider>(context, listen: false).locale,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.t('password.changed_success', params: {})),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = context.l10n(
          Provider.of<LocaleProvider>(context, listen: false).locale,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.t('error.generic')}: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: true).locale;
    final l10n = context.l10n(locale);
    return Scaffold(
      backgroundColor: DesignConstants.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignConstants.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: DesignConstants.spacingLarge),

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            DesignConstants.primaryColor,
                            DesignConstants.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: DesignConstants.primaryColor.withOpacity(
                              0.3,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingLarge),

                    Text(
                      l10n.t('password.screen_title'),
                      style: DesignConstants.textStyleTitle.copyWith(
                        fontSize: DesignConstants.fontSizeLarge + 4,
                        fontWeight: DesignConstants.fontWeightBold,
                        color: DesignConstants.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignConstants.spacingSmall),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignConstants.spacingMedium,
                        vertical: DesignConstants.spacingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: DesignConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          DesignConstants.radiusSmall,
                        ),
                        border: Border.all(
                          color: DesignConstants.primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        l10n.t('password.security_tip'),
                        style: DesignConstants.textStyleCaption.copyWith(
                          color: DesignConstants.primaryColor,
                          fontWeight: DesignConstants.fontWeightMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignConstants.spacingLarge * 2),

              Container(
                padding: const EdgeInsets.all(DesignConstants.spacingMedium),
                decoration: BoxDecoration(
                  color: DesignConstants.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(
                    DesignConstants.radiusMedium,
                  ),
                  border: Border.all(
                    color: DesignConstants.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: DesignConstants.primaryColor,
                      size: DesignConstants.iconSizeSmall,
                    ),
                    const SizedBox(width: DesignConstants.spacingSmall),
                    Expanded(
                      child: Text(
                        'Conseil de sécurité: Utilisez un mot de passe fort avec au moins 8 caractères, incluant des lettres, chiffres et symboles.',
                        style: DesignConstants.textStyleTiny.copyWith(
                          color: DesignConstants.primaryColor,
                          fontWeight: DesignConstants.fontWeightMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: DesignConstants.spacingLarge),

              Container(
                padding: const EdgeInsets.all(DesignConstants.spacingLarge),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    DesignConstants.radiusLarge,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: DesignConstants.borderColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: DesignConstants.primaryColor,
                            size: DesignConstants.iconSizeMedium,
                          ),
                          const SizedBox(width: DesignConstants.spacingSmall),
                          Text(
                            l10n.t('password.change_title'),
                            style: DesignConstants.textStyleSubtitle.copyWith(
                              fontWeight: DesignConstants.fontWeightSemiBold,
                              color: DesignConstants.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignConstants.spacingLarge),

                      _buildPasswordField(
                        controller: _currentPasswordController,
                        label: l10n.t('password.current'),
                        hint: l10n.t('password.current_hint'),
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureCurrentPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.t('password.error_current_required');
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: DesignConstants.spacingLarge),

                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: l10n.t('password.new'),
                        hint: l10n.t('password.new_hint'),
                        icon: Icons.lock_reset_rounded,
                        obscureText: _obscureNewPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.t('password.error_new_required');
                          }
                          if (value.length < 6) {
                            return l10n.t('password.error_min_length');
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: DesignConstants.spacingLarge),

                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: l10n.t('password.confirm'),
                        hint: l10n.t('password.confirm_hint'),
                        icon: Icons.verified_user_rounded,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.t('password.error_confirm_required');
                          }
                          if (value != _newPasswordController.text) {
                            return l10n.t('password.error_mismatch');
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: DesignConstants.spacingLarge * 2),

                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DesignConstants.primaryColor,
                              DesignConstants.secondaryColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            DesignConstants.radiusMedium,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DesignConstants.primaryColor.withOpacity(
                                0.3,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignConstants.radiusMedium,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isLoading
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: DesignConstants.spacingSmall,
                                      ),
                                      Text(
                                        l10n.t('password.changing'),
                                        style: DesignConstants.textStyleBody
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight:
                                                  DesignConstants
                                                      .fontWeightMedium,
                                            ),
                                      ),
                                    ],
                                  )
                                  : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(
                                        width: DesignConstants.spacingSmall,
                                      ),
                                      Text(
                                        l10n.t('password.confirm_change'),
                                        style: DesignConstants.textStyleBody
                                            .copyWith(
                                              color: Colors.white,
                                              fontWeight:
                                                  DesignConstants
                                                      .fontWeightSemiBold,
                                              fontSize:
                                                  DesignConstants
                                                      .fontSizeMedium,
                                            ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: DesignConstants.primaryColor,
              size: DesignConstants.iconSizeSmall,
            ),
            const SizedBox(width: DesignConstants.spacingSmall),
            Text(
              label,
              style: DesignConstants.textStyleCaption.copyWith(
                fontWeight: DesignConstants.fontWeightSemiBold,
                color: DesignConstants.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignConstants.spacingSmall),

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignConstants.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            style: DesignConstants.textStyleBody.copyWith(
              fontWeight: DesignConstants.fontWeightMedium,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: DesignConstants.textStyleCaption.copyWith(
                color: DesignConstants.textSecondary,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: DesignConstants.primaryColor,
                  size: 18,
                ),
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: DesignConstants.textSecondary,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                  style: IconButton.styleFrom(
                    backgroundColor: DesignConstants.backgroundSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  DesignConstants.radiusMedium,
                ),
                borderSide: BorderSide(
                  color: DesignConstants.borderColor,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  DesignConstants.radiusMedium,
                ),
                borderSide: BorderSide(
                  color: DesignConstants.borderColor,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  DesignConstants.radiusMedium,
                ),
                borderSide: BorderSide(
                  color: DesignConstants.primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  DesignConstants.radiusMedium,
                ),
                borderSide: BorderSide(
                  color: DesignConstants.errorColor,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  DesignConstants.radiusMedium,
                ),
                borderSide: BorderSide(
                  color: DesignConstants.errorColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignConstants.spacingMedium,
                vertical: DesignConstants.spacingMedium,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
