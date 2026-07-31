import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/forms/app_form_validators.dart';
import '../../../../theme/app_theme.dart';
import '../../application/camera_config_form_mapper.dart';
import '../../application/camera_config_service.dart';

/// Screen for configuring camera connection settings.
///
/// Allows users to input camera IP address, username, and password
/// which are then used to construct the RTSP URL for video streaming.
class CameraSettingsScreen extends StatefulWidget {
  const CameraSettingsScreen({super.key});

  @override
  State<CameraSettingsScreen> createState() => _CameraSettingsScreenState();
}

class _CameraSettingsScreenState extends State<CameraSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController =
      TextEditingController(text: AppFormValidators.parsePort(null).toString());

  final _ip2Controller = TextEditingController();
  final _username2Controller = TextEditingController();
  final _password2Controller = TextEditingController();
  final _port2Controller =
      TextEditingController(text: AppFormValidators.parsePort(null).toString());

  late final Listenable _previewListenable;
  final CameraConfigService _cameraConfigService = CameraConfigService();

  bool _obscurePassword = true;
  bool _obscurePassword2 = true;
  bool _isSaving = false;
  bool _showCamera2Section = false;

  @override
  void initState() {
    super.initState();
    _previewListenable = Listenable.merge([
      _ipController,
      _usernameController,
      _passwordController,
      _portController,
      _ip2Controller,
      _username2Controller,
      _password2Controller,
      _port2Controller,
    ]);
    _loadSavedConfig();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    _ip2Controller.dispose();
    _username2Controller.dispose();
    _password2Controller.dispose();
    _port2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final (config1, config2) = await _cameraConfigService.loadDualConfig();
    if (!mounted) return;

    setState(() {
      _ipController.text = config1.ip;
      _usernameController.text = config1.username;
      _passwordController.text = config1.password;
      _portController.text = config1.port.toString();

      _ip2Controller.text = config2.ip;
      _username2Controller.text = config2.username;
      _password2Controller.text = config2.password;
      _port2Controller.text = config2.port.toString();

      _showCamera2Section = config2.isValid;
    });
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _showSnackBar(
    String message, {
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveConfig() async {
    _dismissKeyboard();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final config1 = CameraConfigFormMapper.fromForm(
        ip: _ipController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        portText: _portController.text,
      );

      await _cameraConfigService.saveConfig(config1);

      if (_showCamera2Section) {
        final config2 = CameraConfigFormMapper.fromForm(
          ip: _ip2Controller.text,
          username: _username2Controller.text,
          password: _password2Controller.text,
          portText: _port2Controller.text,
        );
        await _cameraConfigService.saveCamera2Config(config2);
      } else {
        await _cameraConfigService.clearCamera2Config();
      }

      if (!mounted) return;
      _showSnackBar(
        _showCamera2Section
            ? 'Dual camera configuration saved.'
            : 'Camera configuration saved.',
        backgroundColor: Colors.green,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Error saving configuration: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showUrlsPreview() {
    _dismissKeyboard();
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        'Please fix the highlighted fields before testing.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final primaryConfig = CameraConfigFormMapper.fromForm(
      ip: _ipController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      portText: _portController.text,
    );

    final configs = <String>[
      'Camera 1: ${primaryConfig.rtspUrl}',
    ];

    if (_showCamera2Section) {
      final secondaryConfig = CameraConfigFormMapper.fromForm(
        ip: _ip2Controller.text,
        username: _username2Controller.text,
        password: _password2Controller.text,
        portText: _port2Controller.text,
      );
      configs.add('Camera 2: ${secondaryConfig.rtspUrl}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: configs
              .map(
                (url) => Text(
                  url,
                  style: GoogleFonts.montserrat(fontSize: 12),
                ),
              )
              .toList(),
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _fieldDecoration(
        labelText: label,
        hintText: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onFieldSubmitted: onFieldSubmitted,
      onTapOutside: (_) => _dismissKeyboard(),
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
    );
  }

  Widget _buildSectionTitle(
    String title, {
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: AppTheme.spacingSM),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildUrlPreview({
    required String title,
    required String username,
    required String ip,
    required String port,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: AppTheme.spacingMD),
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, size: 20, color: accent),
              const SizedBox(width: AppTheme.spacingSM),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingSM),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: SelectableText(
              'rtsp://$username:*******@$ip:$port/',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Camera Settings',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLG),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.primaryColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMD),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RTSP Camera Setup',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your camera credentials with a cleaner, faster setup flow.',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                _buildSectionTitle(
                  'Camera 1 (Primary)',
                  icon: Icons.videocam,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                _buildField(
                  controller: _ipController,
                  label: 'Camera 1 IP Address',
                  hint: 'e.g., 192.168.1.100',
                  icon: Icons.dns,
                  validator: (value) => AppFormValidators.requiredText(
                    value,
                    'Please enter camera IP address',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                _buildField(
                  controller: _portController,
                  label: 'RTSP Port',
                  hint: 'e.g., 5554',
                  icon: Icons.settings_input_antenna,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      AppFormValidators.port(value, requiredField: true),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                _buildField(
                  controller: _usernameController,
                  label: 'Camera 1 Username',
                  hint: 'Enter authentication username',
                  icon: Icons.person,
                  validator: (value) => AppFormValidators.requiredText(
                    value,
                    'Please enter camera username',
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                _buildField(
                  controller: _passwordController,
                  label: 'Camera 1 Password',
                  hint: 'Enter authentication password',
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  validator: (value) => AppFormValidators.requiredText(
                    value,
                    'Please enter camera password',
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saveConfig(),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                Row(
                  children: [
                    Switch(
                      value: _showCamera2Section,
                      onChanged: (value) {
                        setState(() {
                          _showCamera2Section = value;
                        });
                      },
                      activeThumbColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    Expanded(
                      child: Text(
                        'Add Second Camera',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: !_showCamera2Section
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildSectionTitle(
                              'Camera 2 (Secondary)',
                              icon: Icons.videocam,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: AppTheme.spacingMD),
                            _buildField(
                              controller: _ip2Controller,
                              label: 'Camera 2 IP Address',
                              hint: 'e.g., 192.168.1.101',
                              icon: Icons.dns,
                              validator: (value) => _showCamera2Section
                                  ? AppFormValidators.requiredText(
                                      value,
                                      'Please enter camera 2 IP address',
                                    )
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildField(
                              controller: _port2Controller,
                              label: 'Camera 2 RTSP Port',
                              hint: 'e.g., 5554',
                              icon: Icons.settings_input_antenna,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) => AppFormValidators.port(
                                value,
                                requiredField: _showCamera2Section,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildField(
                              controller: _username2Controller,
                              label: 'Camera 2 Username',
                              hint: 'Enter camera 2 username',
                              icon: Icons.person,
                              validator: (value) => _showCamera2Section
                                  ? AppFormValidators.requiredText(
                                      value,
                                      'Please enter camera 2 username',
                                    )
                                  : null,
                            ),
                            const SizedBox(height: AppTheme.spacingLG),
                            _buildField(
                              controller: _password2Controller,
                              label: 'Camera 2 Password',
                              hint: 'Enter camera 2 password',
                              icon: Icons.lock,
                              obscureText: _obscurePassword2,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword2
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword2 = !_obscurePassword2;
                                  });
                                },
                              ),
                              validator: (value) => _showCamera2Section
                                  ? AppFormValidators.requiredText(
                                      value,
                                      'Please enter camera 2 password',
                                    )
                                  : null,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _saveConfig(),
                            ),
                          ],
                        ),
                ),
                ListenableBuilder(
                  listenable: _previewListenable,
                  builder: (context, _) {
                    final showCamera1Preview =
                        _ipController.text.trim().isNotEmpty &&
                            _usernameController.text.trim().isNotEmpty &&
                            _passwordController.text.trim().isNotEmpty;
                    final showCamera2Preview = _showCamera2Section &&
                        _ip2Controller.text.trim().isNotEmpty &&
                        _username2Controller.text.trim().isNotEmpty &&
                        _password2Controller.text.trim().isNotEmpty;

                    if (!showCamera1Preview && !showCamera2Preview) {
                      return const SizedBox(height: AppTheme.spacingXL);
                    }

                    return Column(
                      children: [
                        const SizedBox(height: AppTheme.spacingXL),
                        if (showCamera1Preview)
                          _buildUrlPreview(
                            title: 'Camera 1 RTSP URL Preview',
                            username: _usernameController.text.trim(),
                            ip: _ipController.text.trim(),
                            port: _portController.text.trim(),
                            accent: AppTheme.primaryColor,
                          ),
                        if (showCamera2Preview)
                          _buildUrlPreview(
                            title: 'Camera 2 RTSP URL Preview',
                            username: _username2Controller.text.trim(),
                            ip: _ip2Controller.text.trim(),
                            port: _port2Controller.text.trim(),
                            accent: Colors.orange,
                          ),
                        const SizedBox(height: AppTheme.spacingXL),
                      ],
                    );
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveConfig,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Configuration',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXL,
                        vertical: AppTheme.spacingMD,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _showUrlsPreview,
                    icon: const Icon(Icons.link),
                    label: Text(
                      'Test URLs',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXL,
                        vertical: AppTheme.spacingMD,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
