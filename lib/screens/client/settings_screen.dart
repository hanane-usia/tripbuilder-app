import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/design_constants.dart';
import '../../providers/locale_provider.dart';
import '../../services/localization.dart';
import '../../services/client_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'fr';

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    _selectedLanguage = localeProvider.locale.languageCode;
    final l10n = context.l10n(localeProvider.locale);
    return Container(
      color: DesignConstants.backgroundSecondary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignConstants.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignConstants.spacingTiny),
            _buildSection(l10n.t('settings.preferences'), [
              _buildLanguageCard(),
            ]),
            const SizedBox(height: DesignConstants.spacingLarge),
            _buildSection(l10n.t('settings.application'), [
              _buildSettingsCard(
                Icons.security,
                l10n.t('settings.security'),
                l10n.t('settings.security_desc'),
                DesignConstants.accentColor,
                onTap: () => _showChangePasswordModal(context),
              ),
            ]),
            const SizedBox(height: DesignConstants.spacingLarge),
            _buildSection(l10n.t('settings.support'), [
              _buildSettingsCard(
                Icons.help,
                l10n.t('settings.help'),
                l10n.t('settings.help_desc'),
                DesignConstants.warningColor,
              ),
              _buildSettingsCard(
                Icons.info,
                l10n.t('settings.about'),
                l10n.t('settings.about_desc'),
                DesignConstants.errorColor,
              ),
            ]),
            const SizedBox(height: DesignConstants.spacingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DesignConstants.textStyleSubtitle),
        const SizedBox(height: DesignConstants.spacingSmall),
        ...children,
      ],
    );
  }

  Widget _buildSettingsCard(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingSmall),
      child: InkWell(
        onTap:
            onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title sélectionné'),
                  backgroundColor: DesignConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      DesignConstants.radiusTiny,
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
        borderRadius: BorderRadius.circular(DesignConstants.radiusSmall),
        child: Container(
          padding: const EdgeInsets.all(DesignConstants.spacingMedium),
          decoration: DesignConstants.cardDecoration,
          child: Row(
            children: [
              DesignConstants.buildIconContainer(
                icon: icon,
                color: iconColor,
                size: DesignConstants.containerSizeMini,
                iconSize: DesignConstants.iconSizeTiny,
              ),
              const SizedBox(width: DesignConstants.spacingSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: DesignConstants.textStyleCaption.copyWith(
                        fontWeight: DesignConstants.fontWeightMedium,
                      ),
                    ),
                    const SizedBox(height: DesignConstants.spacingMini),
                    Text(
                      subtitle,
                      style: DesignConstants.textStyleTiny.copyWith(
                        color: DesignConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: DesignConstants.iconSizeTiny,
                color: DesignConstants.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignConstants.spacingSmall),
      padding: const EdgeInsets.all(DesignConstants.spacingMedium),
      decoration: DesignConstants.cardDecoration,
      child: Row(
        children: [
          DesignConstants.buildIconContainer(
            icon: Icons.language,
            color: DesignConstants.primaryColor,
            size: DesignConstants.containerSizeMini,
            iconSize: DesignConstants.iconSizeTiny,
          ),
          const SizedBox(width: DesignConstants.spacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context
                      .l10n(
                        Provider.of<LocaleProvider>(
                          context,
                          listen: false,
                        ).locale,
                      )
                      .t('settings.language'),
                  style: DesignConstants.textStyleCaption.copyWith(
                    fontWeight: DesignConstants.fontWeightMedium,
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
                      .t('settings.change_language'),
                  style: DesignConstants.textStyleTiny.copyWith(
                    color: DesignConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignConstants.spacingTiny,
              vertical: DesignConstants.spacingMini,
            ),
            decoration: BoxDecoration(
              color: DesignConstants.backgroundSecondary,
              borderRadius: BorderRadius.circular(DesignConstants.radiusTiny),
            ),
            child: DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              isDense: true,
              style: DesignConstants.textStyleTiny.copyWith(
                color: DesignConstants.textPrimary,
              ),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('FR')),
                DropdownMenuItem(value: 'en', child: Text('EN')),
              ],
              onChanged: (String? value) async {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                  final provider = Provider.of<LocaleProvider>(
                    context,
                    listen: false,
                  );
                  await provider.setLocale(Locale(value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value == 'fr'
                            ? 'Langue changée en Français'
                            : 'Language changed to English',
                      ),
                      backgroundColor: DesignConstants.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignConstants.radiusTiny,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context) {
    final l10n = context.l10n(
      Provider.of<LocaleProvider>(context, listen: false).locale,
    );
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignConstants.radiusLarge),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: DesignConstants.spacingLarge,
                right: DesignConstants.spacingLarge,
                top: DesignConstants.spacingLarge,
                bottom:
                    MediaQuery.of(ctx).viewInsets.bottom +
                    DesignConstants.spacingLarge,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: DesignConstants.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.t('password.change_title'),
                            style: DesignConstants.textStyleSubtitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignConstants.spacingLarge),

                      Text(
                        l10n.t('password.current'),
                        style: DesignConstants.textStyleCaption,
                      ),
                      const SizedBox(height: DesignConstants.spacingTiny),
                      TextFormField(
                        controller: currentCtrl,
                        obscureText: obscureCurrent,
                        decoration: InputDecoration(
                          hintText: l10n.t('password.current_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                () => setState(
                                  () => obscureCurrent = !obscureCurrent,
                                ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignConstants.radiusMedium,
                            ),
                          ),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.isEmpty)
                                    ? l10n.t('password.error_current_required')
                                    : null,
                      ),

                      const SizedBox(height: DesignConstants.spacingMedium),

                      Text(
                        l10n.t('password.new'),
                        style: DesignConstants.textStyleCaption,
                      ),
                      const SizedBox(height: DesignConstants.spacingTiny),
                      TextFormField(
                        controller: newCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          hintText: l10n.t('password.new_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                () => setState(() => obscureNew = !obscureNew),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignConstants.radiusMedium,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return l10n.t('password.error_new_required');
                          if (v.length < 6)
                            return l10n.t('password.error_min_length');
                          return null;
                        },
                      ),

                      const SizedBox(height: DesignConstants.spacingMedium),

                      Text(
                        l10n.t('password.confirm'),
                        style: DesignConstants.textStyleCaption,
                      ),
                      const SizedBox(height: DesignConstants.spacingTiny),
                      TextFormField(
                        controller: confirmCtrl,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          hintText: l10n.t('password.confirm_hint'),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed:
                                () => setState(
                                  () => obscureConfirm = !obscureConfirm,
                                ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignConstants.radiusMedium,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return l10n.t('password.error_confirm_required');
                          if (v != newCtrl.text)
                            return l10n.t('password.error_mismatch');
                          return null;
                        },
                      ),

                      const SizedBox(height: DesignConstants.spacingLarge),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon:
                              isLoading
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                  ),
                          label: Text(
                            isLoading
                                ? l10n.t('password.changing')
                                : l10n.t('password.confirm_change'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignConstants.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DesignConstants.radiusMedium,
                              ),
                            ),
                            elevation: 0,
                          ),
                          onPressed:
                              isLoading
                                  ? null
                                  : () async {
                                    if (!formKey.currentState!.validate())
                                      return;
                                    setState(() => isLoading = true);
                                    try {
                                      await ClientApiService.changePassword(
                                        currentCtrl.text,
                                        newCtrl.text,
                                      );
                                      if (ctx.mounted) {
                                        Navigator.of(ctx).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.t(
                                                'password.changed_success',
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${l10n.t('error.generic')}: ${e.toString().replaceFirst('Exception: ', '')}',
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    } finally {
                                      setState(() => isLoading = false);
                                    }
                                  },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
