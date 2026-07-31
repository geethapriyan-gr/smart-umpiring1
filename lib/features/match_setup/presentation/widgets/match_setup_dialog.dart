import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/forms/app_form_validators.dart';
import '../../../../providers/video_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../../../utils/responsive_utils.dart';
import '../../application/match_details_form_mapper.dart';

const _dialogBase = Color(0xFF060818);
const _dialogSurface = Color(0xFF0E1230);
const _dialogSurfaceSoft = Color(0xFF141B43);
const _brandGlow = Color(0xFF8B6FFF);

class MatchSetupDialog extends StatefulWidget {
  const MatchSetupDialog({super.key});

  @override
  State<MatchSetupDialog> createState() => _MatchSetupDialogState();
}

class _MatchSetupDialogState extends State<MatchSetupDialog>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _matchNameController = TextEditingController();
  final _team1Controller = TextEditingController();
  final _team2Controller = TextEditingController();
  final _oversController = TextEditingController();
  final _cameraIpController = TextEditingController(text: '192.168.29.44');
  final _cameraUsernameController = TextEditingController();
  final _cameraPasswordController = TextEditingController();
  final _camera2IpController = TextEditingController();
  final _camera2UsernameController = TextEditingController();
  final _camera2PasswordController = TextEditingController();

  bool _showCamera2Section = false;
  bool _showPrimaryPassword = false;
  bool _showSecondaryPassword = false;
  bool _isSubmitting = false;

  // ── Only the fields that appear in the header summary chip ──────
  late final Listenable _summaryListenable;

  late final AnimationController _dialogController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Only merge the three controllers shown in the header chips.
    // Camera fields no longer trigger full header rebuilds.
    _summaryListenable = Listenable.merge([
      _matchNameController,
      _team1Controller,
      _team2Controller,
      _oversController,
    ]);

    _dialogController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _dialogController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _dialogController,
        curve: Curves.easeOutBack,
      ),
    );

    _dialogController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VideoProvider>();
      final existingDetails = provider.matchDetails;
      if (existingDetails == null || !mounted) return;

      setState(() {
        _matchNameController.text = existingDetails.matchName;
        _team1Controller.text = existingDetails.team1Name;
        _team2Controller.text = existingDetails.team2Name;
        _oversController.text = existingDetails.numberOfOvers.toString();
        _cameraIpController.text = existingDetails.cameraIp;
        _cameraUsernameController.text = existingDetails.cameraUsername;
        _cameraPasswordController.text = existingDetails.cameraPassword;
        _camera2IpController.text = existingDetails.camera2Ip;
        _camera2UsernameController.text = existingDetails.camera2Username;
        _camera2PasswordController.text = existingDetails.camera2Password;
        _showCamera2Section = existingDetails.camera2Ip.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _matchNameController.dispose();
    _team1Controller.dispose();
    _team2Controller.dispose();
    _oversController.dispose();
    _cameraIpController.dispose();
    _cameraUsernameController.dispose();
    _cameraPasswordController.dispose();
    _camera2IpController.dispose();
    _camera2UsernameController.dispose();
    _camera2PasswordController.dispose();
    _dialogController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _dialogSurfaceSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          side: BorderSide(
            color: AppTheme.accentColor.withValues(alpha: 0.32),
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    _dismissKeyboard();

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please complete the required fields.');
      return;
    }

    setState(() => _isSubmitting = true);

    final matchDetails = MatchDetailsFormMapper.fromForm(
      matchName: _matchNameController.text,
      team1Name: _team1Controller.text,
      team2Name: _team2Controller.text,
      oversText: _oversController.text,
      cameraIp: _cameraIpController.text,
      cameraUsername: _cameraUsernameController.text,
      cameraPassword: _cameraPasswordController.text,
      includeSecondaryCamera: _showCamera2Section,
      camera2Ip: _camera2IpController.text,
      camera2Username: _camera2UsernameController.text,
      camera2Password: _camera2PasswordController.text,
    );

    final provider = context.read<VideoProvider>();
    final success = await provider.saveMatchDetails(matchDetails);

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
    } else {
      _showErrorSnackBar(
        provider.error ?? 'Failed to update match details.',
      );
    }
  }

  // ── Cached decoration objects (avoid rebuilding on every keystroke) ──
  static const _fieldFillColor = Color(0x0DFFFFFF); // ~5% white
  static const _enabledBorderColor = Color(0x14FFFFFF); // ~8% white

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      // Use disabled to avoid re-validating (and rebuilding) on every keystroke.
      // Validation only runs on submit or field-submitted.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onTapOutside: (_) => _dismissKeyboard(),
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      cursorColor: AppTheme.secondaryColor,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: const Color(0xC2FFFFFF), // 76% white
        ),
        suffixIcon: suffixIcon,
        labelStyle: GoogleFonts.montserrat(
          color: const Color(0xB8FFFFFF), // 72% white
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.montserrat(
          color: const Color(0x57FFFFFF), // 34% white
          fontSize: 14,
        ),
        filled: true,
        fillColor: _fieldFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(
            color: _enabledBorderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: BorderSide(
            color: AppTheme.secondaryColor.withValues(alpha: 0.92),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: BorderSide(
            color: AppTheme.accentColor.withValues(alpha: 0.8),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(
            color: AppTheme.accentColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppTheme.spacingLG),
    Gradient? gradient,
    Color? borderColor,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0x80141B43), // 50% _dialogSurfaceSoft
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x14FFFFFF), // 8% white
                Color(0x05FFFFFF), // 2% white
              ],
            ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: borderColor ?? const Color(0x1FFFFFFF), // 12% white
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000), // 15% black
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeader(bool isEditing) {
    return _buildGlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.primaryColor.withValues(alpha: 0.26),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      borderColor: _brandGlow.withValues(alpha: 0.22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Static header icon – no animation to avoid jank ──
              RepaintBoundary(
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMD),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, _brandGlow],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.36),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    isEditing
                        ? Icons.edit_calendar_rounded
                        : Icons.sports_cricket,
                    color: Colors.white,
                    size: 26,
                  ),
                )
                    .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true))
                    .scaleXY(
                      begin: 0.97,
                      end: 1.04,
                      duration: 2200.ms,
                      curve: Curves.easeInOut,
                    ),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Edit Match Setup' : 'Match Setup',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a cleaner match flow with polished setup details and ready-to-go camera feeds.',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        height: 1.6,
                        color: const Color(0xB8FFFFFF), // 72% white
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xBCFFFFFF), // 74% white
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          // ── Summary chips isolated into own widget ──────────────
          // Only this subtree rebuilds on keystroke, not the whole header.
          _SummaryChips(
            listenable: _summaryListenable,
            matchNameController: _matchNameController,
            team1Controller: _team1Controller,
            team2Controller: _team2Controller,
            oversController: _oversController,
            showCamera2: _showCamera2Section,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget child,
    String? badge,
  }) {
    return _buildGlassCard(
      borderColor: accent.withValues(alpha: 0.18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.04),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Text(
                              badge,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xA8FFFFFF), // 66% white
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          child,
        ],
      ),
    );
  }

  Widget _buildMatchInfoSection() {
    return _buildSectionCard(
      title: 'Match Details',
      subtitle: 'Set the identity of the match before live review begins.',
      icon: Icons.emoji_events_rounded,
      accent: _brandGlow,
      badge: 'Step 1',
      child: Column(
        children: [
          _buildField(
            controller: _matchNameController,
            label: 'Match Name',
            hint: 'e.g. India vs Australia - Final',
            icon: Icons.event_rounded,
            validator: (value) => AppFormValidators.requiredText(
              value,
              'Please enter match name',
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildField(
            controller: _team1Controller,
            label: 'Team 1 Name',
            hint: 'e.g. India',
            icon: Icons.groups_rounded,
            validator: (value) => AppFormValidators.requiredText(
              value,
              'Please enter team 1 name',
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildField(
            controller: _team2Controller,
            label: 'Team 2 Name',
            hint: 'e.g. Australia',
            icon: Icons.groups_rounded,
            validator: (value) => AppFormValidators.requiredText(
              value,
              'Please enter team 2 name',
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildField(
            controller: _oversController,
            label: 'Number of Overs',
            hint: 'e.g. 20',
            icon: Icons.timer_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) => AppFormValidators.positiveInteger(
              value,
              emptyMessage: 'Please enter number of overs',
              invalidMessage: 'Please enter a valid number of overs',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCameraSection() {
    return _buildSectionCard(
      title: 'Primary Camera',
      subtitle: 'This is the main live feed used for review and match playback.',
      icon: Icons.videocam_rounded,
      accent: AppTheme.secondaryColor,
      badge: 'Step 2',
      child: Column(
        children: [
          _buildField(
            controller: _cameraIpController,
            label: 'Camera 1 IP Address',
            hint: 'e.g. 192.168.1.100',
            icon: Icons.wifi_tethering_rounded,
            validator: (value) => AppFormValidators.requiredText(
              value,
              'Please enter camera IP address',
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildField(
            controller: _cameraUsernameController,
            label: 'Camera 1 Username',
            hint: 'Enter camera username',
            icon: Icons.person_outline_rounded,
            validator: (value) => AppFormValidators.requiredText(
              value,
              'Please enter camera username',
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _buildField(
            controller: _cameraPasswordController,
            label: 'Camera 1 Password',
            hint: 'Enter camera password',
            icon: Icons.lock_outline_rounded,
            obscureText: !_showPrimaryPassword,
            validator: (value) => AppFormValidators.requiredText(
              value,
              'Please enter camera password',
            ),
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitForm(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _showPrimaryPassword = !_showPrimaryPassword);
              },
              icon: Icon(
                _showPrimaryPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: const Color(0xB8FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualCameraToggle() {
    return _buildGlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.secondaryColor.withValues(
            alpha: _showCamera2Section ? 0.16 : 0.08,
          ),
          Colors.white.withValues(alpha: 0.04),
        ],
      ),
      borderColor: AppTheme.secondaryColor.withValues(
        alpha: _showCamera2Section ? 0.28 : 0.14,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.secondaryColor.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              Icons.cameraswitch_rounded,
              color: AppTheme.secondaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Dual Camera',
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add a second angle for split capture and richer replay coverage.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    height: 1.5,
                    color: const Color(0xA8FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacingMD),
          Switch.adaptive(
            value: _showCamera2Section,
            activeThumbColor: AppTheme.secondaryColor,
            activeTrackColor: AppTheme.secondaryColor.withValues(alpha: 0.42),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            onChanged: (value) {
              setState(() => _showCamera2Section = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCameraSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
        );
      },
      child: !_showCamera2Section
          ? const SizedBox.shrink()
          : Container(
              key: const ValueKey('dual-camera-card'),
              margin: const EdgeInsets.only(top: AppTheme.spacingXL),
              child: _buildSectionCard(
                title: 'Second Camera',
                subtitle:
                    'Use a supporting angle for alternate coverage and cleaner review context.',
                icon: Icons.view_carousel_rounded,
                accent: AppTheme.warningColor,
                badge: 'Optional',
                child: Column(
                  children: [
                    _buildField(
                      controller: _camera2IpController,
                      label: 'Camera 2 IP Address',
                      hint: 'e.g. 192.168.1.101',
                      icon: Icons.wifi_tethering_rounded,
                      validator: (value) => _showCamera2Section
                          ? AppFormValidators.requiredText(
                              value,
                              'Please enter camera 2 IP address',
                            )
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    _buildField(
                      controller: _camera2UsernameController,
                      label: 'Camera 2 Username',
                      hint: 'Enter camera 2 username',
                      icon: Icons.person_outline_rounded,
                      validator: (value) => _showCamera2Section
                          ? AppFormValidators.requiredText(
                              value,
                              'Please enter camera 2 username',
                            )
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spacingMD),
                    _buildField(
                      controller: _camera2PasswordController,
                      label: 'Camera 2 Password',
                      hint: 'Enter camera 2 password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_showSecondaryPassword,
                      validator: (value) => _showCamera2Section
                          ? AppFormValidators.requiredText(
                              value,
                              'Please enter camera 2 password',
                            )
                          : null,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitForm(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () => _showSecondaryPassword =
                                !_showSecondaryPassword,
                          );
                        },
                        icon: Icon(
                          _showSecondaryPassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: const Color(0xB8FFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActions(bool isEditing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 420;
        final buttonChildren = <Widget>[
          SizedBox(
            width: stacked ? double.infinity : null,
            child: OutlinedButton.icon(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              label: Text(
                'Cancel',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
                side: const BorderSide(color: Color(0x29FFFFFF)),
                backgroundColor: const Color(0x0AFFFFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                ),
              ),
            ),
          ),
          SizedBox(
            width: stacked ? double.infinity : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, _brandGlow],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.34),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isEditing
                            ? Icons.save_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                label: Text(
                  _isSubmitting
                      ? 'Saving...'
                      : isEditing
                          ? 'Save Changes'
                          : 'Start Match',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ];

        if (stacked) {
          return Column(
            children: [
              buttonChildren[0],
              const SizedBox(height: AppTheme.spacingMD),
              buttonChildren[1],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: buttonChildren[0]),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(child: buttonChildren[1]),
          ],
        );
      },
    );
  }

  Widget _buildDialogBody(bool isEditing) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isEditing)
                .animate()
                .fadeIn(duration: 420.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: AppTheme.spacingXL),
            _buildMatchInfoSection()
                .animate()
                .fadeIn(delay: 80.ms, duration: 380.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: AppTheme.spacingXL),
            _buildPrimaryCameraSection()
                .animate()
                .fadeIn(delay: 150.ms, duration: 380.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: AppTheme.spacingXL),
            _buildDualCameraToggle()
                .animate()
                .fadeIn(delay: 210.ms, duration: 380.ms)
                .slideY(begin: 0.08, end: 0),
            _buildSecondaryCameraSection(),
            const SizedBox(height: AppTheme.spacingXL),
            _buildActions(isEditing)
                .animate()
                .fadeIn(delay: 270.ms, duration: 380.ms)
                .slideY(begin: 0.08, end: 0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use read() so provider changes don't rebuild the whole dialog.
    final isEditing =
        context.read<VideoProvider>().matchDetails != null;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: _dismissKeyboard,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.adaptiveContentWidth(
                  mobileFraction: 1,
                  tabletFraction: 0.84,
                  desktopFraction: 0.68,
                  maxWidth: 720,
                ),
                maxHeight: screenHeight * (context.isTablet ? 0.84 : 0.9),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // ── Static background gradient ─────────────────
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _dialogBase,
                            _dialogSurface,
                            Color(0xFF1A1240),
                            _dialogSurfaceSoft,
                          ],
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                    // ── Decorative orbs (isolated from text repaints) ──
                    Positioned(
                      top: -90,
                      right: -50,
                      child: RepaintBoundary(
                        child: _DialogOrb(
                          size: 220,
                          color: AppTheme.primaryColor.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 80,
                      left: -60,
                      child: RepaintBoundary(
                        child: _DialogOrb(
                          size: 180,
                          color:
                              AppTheme.secondaryColor.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    // ── Scrollable form content ───────────────────────
                    RepaintBoundary(
                      child: _buildDialogBody(isEditing),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary chips isolated into their own widget ───────────────────────────
// Only this widget rebuilds on keystroke — the parent header stays static.
class _SummaryChips extends StatelessWidget {
  const _SummaryChips({
    required this.listenable,
    required this.matchNameController,
    required this.team1Controller,
    required this.team2Controller,
    required this.oversController,
    required this.showCamera2,
  });

  final Listenable listenable;
  final TextEditingController matchNameController;
  final TextEditingController team1Controller;
  final TextEditingController team2Controller;
  final TextEditingController oversController;
  final bool showCamera2;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final summaryTitle = matchNameController.text.trim().isEmpty
            ? 'New match'
            : matchNameController.text.trim();
        final teamLabel =
            '${team1Controller.text.trim().isEmpty ? 'Team 1' : team1Controller.text.trim()} vs '
            '${team2Controller.text.trim().isEmpty ? 'Team 2' : team2Controller.text.trim()}';
        final oversLabel = oversController.text.trim().isEmpty
            ? 'Overs not set'
            : '${oversController.text.trim()} overs';

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SetupChip(
              icon: Icons.flag_rounded,
              label: summaryTitle,
              accent: _brandGlow,
            ),
            _SetupChip(
              icon: Icons.groups_2_rounded,
              label: teamLabel,
              accent: AppTheme.secondaryColor,
            ),
            _SetupChip(
              icon: Icons.timer_outlined,
              label: oversLabel,
              accent: AppTheme.warningColor,
            ),
            _SetupChip(
              icon: showCamera2
                  ? Icons.view_carousel_rounded
                  : Icons.videocam_rounded,
              label: showCamera2 ? 'Dual camera mode' : 'Single camera',
              accent: Colors.white,
            ),
          ],
        );
      },
    );
  }
}

// ── Floating orb (RepaintBoundary keeps animation off the text layer) ──────
class _DialogOrb extends StatefulWidget {
  const _DialogOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  State<_DialogOrb> createState() => _DialogOrbState();
}

class _DialogOrbState extends State<_DialogOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.94 + (_controller.value * 0.14),
          child: child,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [widget.color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _SetupChip extends StatelessWidget {
  const _SetupChip({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: accent == Colors.white ? Colors.white : accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
