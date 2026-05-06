import 'package:citesched_flutter/main.dart'; // Import for client access
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/widgets/password_reset_dialog.dart';
import 'package:citesched_flutter/core/utils/session_context.dart';
import 'package:citesched_flutter/core/widgets/theme_mode_toggle.dart';
import 'package:citesched_client/citesched_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const List<String> _allowedCourses = ['BSIT', 'BSEMC'];
  static const _googleDeclinedNoticeStoragePrefix = 'google_declined_notice:';
  static const _facultyIdLabel = 'Faculty ID';
  static const _studentIdLabel = 'Student ID';
  static const _enterFacultyIdHint = 'Enter Faculty ID';
  static const _enterStudentIdHint = 'Enter Student ID';
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  late final GoogleAuthController _googleAuthController;
  static const _googleRoleStoragePrefix = 'google_role:';

  String _describeGoogleError(Object error) {
    try {
      final dynamic dynamicError = error;
      final message = dynamicError.message;
      final originalException = dynamicError.originalException;
      if (message is String && originalException != null) {
        return '$message\n$originalException';
      }
    } catch (_) {
      // Fall through to the generic string conversion below.
    }
    return error.toString();
  }

  bool _isFaculty = true; // Toggle state
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  String get _loginTitle => _isFaculty ? 'Faculty Login' : 'Student Login';
  String get _idLabel => _isFaculty ? _facultyIdLabel : _studentIdLabel;
  String get _idHint => _isFaculty ? _enterFacultyIdHint : _enterStudentIdHint;

  String _employmentStatusText(EmploymentStatus status) {
    if (status == EmploymentStatus.fullTime) {
      return 'Full-Time';
    }
    return 'Part-Time';
  }

  // Design Constants - Light Mode Theme Colors
  static const _facultyColorLight = Color(0xFF4F003B);
  static const _studentColorLight = Color(0xFF004085);

  // Dark Mode Theme Colors
  static const _facultyColorDark = Color(0xFFa21caf);
  static const _studentColorDark = Color(0xFF3b82f6);

  // Light Mode Colors
  static const _bgBodyLight = Color(0xFFEEF1F6);
  static const _bgRightLight = Color(
    0xFFF7F9FC,
  ); // Used for right side background if distinct
  static const _cardBgLight = Colors.white;

  // Dark Mode Colors
  static const _bgBodyDark = Color(0xFF0F172A);
  static const _bgRightDark = Color(
    0xFF1E293B,
  ); // Used for right side background if distinct
  static const _cardBgDark = Color(0xFF1E293B);

  Future<void> _login() async => _loginImpl();

  Future<void> _loginImpl() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final id = _idController.text.trim();
      final password = _passwordController.text.trim();

      if (id.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter ID and password';
          _isLoading = false;
        });
        return;
      }

      // Use dynamic access to bypass static analysis issues
      final dynamicClient = client as dynamic;
      // Call the custom auth endpoint
      final result = await dynamicClient.customAuth.loginWithId(
        id: id,
        password: password,
        role: _isFaculty ? 'faculty' : 'student',
      );

      if (result.success &&
          result.userInfo != null &&
          result.keyId != null &&
          result.key != null) {
        // Register the session with Serverpod's SessionManager
        // This is CRITICAL for subsequent requests to be authenticated
        debugPrint('Login successful. KeyID: ${result.keyId}');
        debugPrint('UserInfo: ${result.userInfo}');

        // Create a syntactically valid RFC4122 UUID from the integer keyId so
        // the auth session can be serialized safely on web.
        var fakeUuid = UuidValue.fromString(
          "00000000-0000-4000-8000-${result.keyId.toString().padLeft(12, '0')}",
        );

        // Serverpod typically expects "keyId:key" as the token for integer-based IDs
        String formattedToken = '${result.keyId}:${result.key}';

        var authSuccess = AuthSuccess(
          authUserId: fakeUuid,
          token: formattedToken,
          scopeNames: result.userInfo!.scopeNames.toSet(),
          authStrategy: 'session',
        );
        debugPrint('Updating signed in user with AuthSuccess: $authSuccess');
        await client.auth.updateSignedInUser(authSuccess);

        // Update the auth provider (though the listener might handle it now)
        final authNotifier = ref.read(authProvider.notifier);
        authNotifier.updateUserInfo(result.userInfo);
        final scopes = result.userInfo!.scopeNames;
        if (scopes.contains('admin')) {
          authNotifier.setSelectedRole('admin');
        } else {
          authNotifier.setSelectedRole(_isFaculty ? 'faculty' : 'student');
        }

        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
          // Navigation will happen automatically via RootScreen watching authProvider
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid credentials';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleGoogleAuthenticated() async {
    final authNotifier = ref.read(authProvider.notifier);
    try {
      authNotifier.updateUserInfo(null);
      authNotifier.setSelectedRole(null);

      final sessionContext = await fetchSessionContext();
      final email = sessionContext.email?.trim();
      final displayName = sessionContext.userName;
      final fallbackRole =
          sessionContext.resolvedRole ?? await _resolveExistingGoogleRole(null);

      if (email == null || email.isEmpty) {
        if (fallbackRole != null) {
          if (fallbackRole == 'faculty_pending') {
            await _showAccountStatusModal(
              title: 'Faculty Approval Pending',
              message:
                  'Your faculty registration is waiting for admin approval. You can sign in after approval.',
            );
            await authNotifier.signOut();
            return;
          }

          await authNotifier.refreshCurrentUser();
          authNotifier.setSelectedRole(fallbackRole);
          return;
        }

        throw Exception(
          'Unable to resolve Google account email. Please try again or continue with ID/password sign-in.',
        );
      }

      final userInfo = await _loadUserInfoByEmail(email);

      final selectedRole = await _resolveGoogleRoleSelection(
        userInfo: userInfo,
        email: email,
        displayName: displayName,
        authNotifier: authNotifier,
      );
      if (selectedRole == null) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Unable to resolve account role for this Google sign-in.';
          });
        }
        return;
      }
      if (selectedRole == 'faculty_pending') {
        await _showAccountStatusModal(
          title: 'Faculty Approval Pending',
          message:
              'Your faculty registration is waiting for admin approval. You can sign in after approval.',
        );
        await authNotifier.signOut();
        return;
      }

      await authNotifier.refreshCurrentUser();
      authNotifier.setSelectedRole(selectedRole);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _completeGoogleProfile(
    String role, {
    String? email,
    String? displayName,
  }) async {
    final details = await _showRoleDetailsDialog(
      role,
      email: email,
      displayName: displayName,
    );
    if (details == null) return false;

    final name = details['name'] ?? displayName ?? '';
    final effectiveEmail = details['email'] ?? email ?? '';
    final studentId = details['studentId'];
    final facultyId = details['facultyId'];
    final course = details['course'];
    final section = details['section'];
    final maxLoad = int.tryParse(details['maxLoad'] ?? '');
    final employmentStatus = details['employmentStatus'];
    final shiftPreference = details['shiftPreference'];
    final program = details['program'];
    final accountPassword = details['password'] ?? '';
    final availabilityPayload = details['availability'];

    if (name.trim().isEmpty ||
        effectiveEmail.trim().isEmpty ||
        accountPassword.trim().isEmpty) {
      return false;
    }

    final created = await client.setup.createAccount(
      userName: name.trim(),
      email: effectiveEmail.trim(),
      password: accountPassword,
      role: role,
      studentId: studentId?.trim().isEmpty == true ? null : studentId?.trim(),
      facultyId: facultyId?.trim().isEmpty == true ? null : facultyId?.trim(),
      course: role == 'student' ? course?.trim().toUpperCase() : null,
      section: section?.trim().isEmpty == true ? null : section?.trim(),
      maxLoad: role == 'faculty' ? maxLoad : null,
      employmentStatus: role == 'faculty' ? employmentStatus : null,
      shiftPreference: role == 'faculty' ? shiftPreference : null,
      program: role == 'faculty' ? program : null,
    );

    if (!created) return false;

    if (role == 'faculty') {
      final availabilityEntries = _deserializeAvailabilityEntries(
        availabilityPayload,
      );
      if (availabilityEntries.isNotEmpty) {
        await _saveFacultyAvailability(
          effectiveEmail.trim(),
          availabilityEntries,
        );
      }
    }

    return true;
  }

  Future<void> _showAccountStatusModal({
    required String title,
    required String message,
    bool showWaitingLoader = false,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF720045).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      showWaitingLoader
                          ? Icons.hourglass_top_rounded
                          : Icons.info_outline_rounded,
                      color: const Color(0xFF720045),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (showWaitingLoader) ...[
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Waiting for admin decision...',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFacultyDeclinedNotice() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF720045), Color(0xFFB5179E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faculty Request Declined',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your previous faculty request was not approved. You can choose a different role or submit a new faculty request.',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF720045).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF720045).withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.rule_folder_outlined,
                            color: Color(0xFF720045),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'After closing this message, you will return to role selection so you can continue as a student or submit a new faculty request.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF64748B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF720045),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Choose Role Again',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeSectionCode(String input) {
    final match = RegExp(
      r'^\s*(\d+)\s*([A-Za-z][A-Za-z0-9]*)\s*$',
    ).firstMatch(input);
    if (match == null) return input.trim().toUpperCase();
    final year = match.group(1)!;
    final suffix = match.group(2)!.toUpperCase();
    return '$year$suffix';
  }

  int? _extractYearLevelFromSection(String input) {
    final match = RegExp(
      r'^\s*(\d+)\s*[A-Za-z][A-Za-z0-9]*\s*$',
    ).firstMatch(input);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  Future<Map<String, String>?> _showRoleDetailsDialog(
    String role, {
    String? email,
    String? displayName,
  }) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: displayName ?? '');
    final emailController = TextEditingController(text: email ?? '');
    final idController = TextEditingController();
    final sectionController = TextEditingController();
    final maxLoadController = TextEditingController(text: '21');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isStudent = role == 'student';
        final primaryPurple = isStudent
            ? const Color(0xFF720045)
            : _facultyColorLight;
        const bgBody = Color(0xFFEEF1F6);
        const textPrimary = Color(0xFF333333);
        const textMuted = Color(0xFF666666);
        String selectedCourse = _allowedCourses.first;
        EmploymentStatus selectedEmploymentStatus = EmploymentStatus.fullTime;
        FacultyShiftPreference selectedShiftPreference =
            FacultyShiftPreference.any;
        Program selectedProgram = Program.it;
        DayOfWeek selectedDay = DayOfWeek.mon;
        TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
        TimeOfDay endTime = const TimeOfDay(hour: 12, minute: 0);
        final availabilities = <_AvailabilityEntry>[];
        bool obscurePassword = true;
        bool obscureConfirmPassword = true;

        InputDecoration fieldDecoration(String hint) {
          return InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: textMuted.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: bgBody,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryPurple, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryPurple,
                                isStudent
                                    ? const Color(0xFFb5179e)
                                    : const Color(0xFF7C3AED),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(19),
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isStudent
                                      ? Icons.school_rounded
                                      : Icons.badge_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _roleDetailsTitle(role),
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isStudent
                                          ? 'Complete your student profile once so future Google sign-ins go straight in.'
                                          : 'Complete your faculty profile once so future Google sign-ins go straight in.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isStudent) ...[
                                _buildModalLabel(
                                  'Student Number',
                                  Icons.badge_rounded,
                                ),
                                TextFormField(
                                  controller: idController,
                                  decoration: fieldDecoration('107690'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: textPrimary,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                              ],
                              _buildModalLabel(
                                'Full Name',
                                Icons.person_outline_rounded,
                              ),
                              TextFormField(
                                controller: nameController,
                                decoration: fieldDecoration('Nash Andrew'),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: textPrimary,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              _buildModalLabel(
                                'JMC Account or Any Email',
                                Icons.email_outlined,
                              ),
                              TextFormField(
                                controller: emailController,
                                decoration: fieldDecoration(
                                  'nash.cabillon@jmc.edu.ph',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: textPrimary,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Invalid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildModalLabel(
                                'CITESched Password',
                                Icons.lock_outline_rounded,
                              ),
                              TextFormField(
                                controller: passwordController,
                                decoration:
                                    fieldDecoration(
                                      'Create an app password',
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setModalState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                obscureText: obscurePassword,
                                obscuringCharacter: '\u2022',
                                autocorrect: false,
                                enableSuggestions: false,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: textPrimary,
                                ),
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.isEmpty) {
                                    return 'Required';
                                  }
                                  if (trimmed.length < 8) {
                                    return 'Use at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Google does not share the user\'s Gmail password with the app, so create a separate CITESched password for Faculty/Student login.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildModalLabel(
                                'Confirm Password',
                                Icons.lock_reset_rounded,
                              ),
                              TextFormField(
                                controller: confirmPasswordController,
                                decoration:
                                    fieldDecoration(
                                      'Re-enter your app password',
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setModalState(() {
                                            obscureConfirmPassword =
                                                !obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          obscureConfirmPassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                obscureText: obscureConfirmPassword,
                                obscuringCharacter: '\u2022',
                                autocorrect: false,
                                enableSuggestions: false,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: textPrimary,
                                ),
                                validator: (value) {
                                  if ((value?.trim() ?? '').isEmpty) {
                                    return 'Required';
                                  }
                                  if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              if (isStudent) ...[
                                const SizedBox(height: 20),
                                _buildModalLabel(
                                  'Course',
                                  Icons.school_outlined,
                                ),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedCourse,
                                  decoration: fieldDecoration('Select program'),
                                  items: _allowedCourses
                                      .map(
                                        (course) => DropdownMenuItem<String>(
                                          value: course,
                                          child: Text(
                                            course,
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setModalState(() {
                                      selectedCourse = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                _buildModalLabel(
                                  'Year & Section',
                                  Icons.group_rounded,
                                ),
                                TextFormField(
                                  controller: sectionController,
                                  decoration: fieldDecoration(
                                    'e.g. 3A, 3B, 2A, 2B',
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: textPrimary,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final normalized = _normalizeSectionCode(
                                      value,
                                    );
                                    if (_extractYearLevelFromSection(
                                          normalized,
                                        ) ==
                                        null) {
                                      return 'Use format like 3A, 3B, 2A, 2B';
                                    }
                                    return null;
                                  },
                                ),
                              ] else ...[
                                const SizedBox(height: 20),
                                _buildModalLabel(
                                  _facultyIdLabel,
                                  Icons.badge_rounded,
                                ),
                                TextFormField(
                                  controller: idController,
                                  decoration: fieldDecoration(_facultyIdLabel),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: textPrimary,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                _buildModalLabel(
                                  'Max Loads (hours)',
                                  Icons.access_time_rounded,
                                ),
                                TextFormField(
                                  controller: maxLoadController,
                                  decoration: fieldDecoration('21'),
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    color: textPrimary,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value.trim()) == null) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                _buildModalLabel(
                                  'Employment Status',
                                  Icons.work_outline_rounded,
                                ),
                                DropdownButtonFormField<EmploymentStatus>(
                                  initialValue: selectedEmploymentStatus,
                                  decoration: fieldDecoration('Select Status'),
                                  items: EmploymentStatus.values
                                      .map(
                                        (
                                          status,
                                        ) => DropdownMenuItem<EmploymentStatus>(
                                          value: status,
                                          child: Text(
                                            _employmentStatusText(status),
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setModalState(() {
                                      selectedEmploymentStatus = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? 'Required' : null,
                                ),
                                const SizedBox(height: 20),
                                _buildModalLabel(
                                  'Shift Preference',
                                  Icons.schedule_rounded,
                                ),
                                DropdownButtonFormField<FacultyShiftPreference>(
                                  initialValue: selectedShiftPreference,
                                  decoration: fieldDecoration('Select Shift'),
                                  items: FacultyShiftPreference.values
                                      .map(
                                        (
                                          pref,
                                        ) => DropdownMenuItem<FacultyShiftPreference>(
                                          value: pref,
                                          child: Text(
                                            switch (pref) {
                                              FacultyShiftPreference.any =>
                                                'Any Time (Flexible)',
                                              FacultyShiftPreference.morning =>
                                                'Morning (7:00 AM to 12:00 PM)',
                                              FacultyShiftPreference
                                                  .afternoon =>
                                                'Afternoon (1:00 PM to 6:00 PM)',
                                              FacultyShiftPreference.evening =>
                                                'Evening (6:00 PM to 9:00 PM)',
                                              FacultyShiftPreference.custom =>
                                                'Custom',
                                            },
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setModalState(() {
                                      selectedShiftPreference = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? 'Required' : null,
                                ),
                                const SizedBox(height: 24),
                                _buildModalLabel(
                                  'Program Assignment',
                                  Icons.school_outlined,
                                ),
                                DropdownButtonFormField<Program>(
                                  initialValue: selectedProgram,
                                  decoration: fieldDecoration('Select Program'),
                                  items: const [
                                    Program.it,
                                    Program.emc,
                                    Program.both,
                                  ]
                                      .map(
                                        (program) => DropdownMenuItem<Program>(
                                          value: program,
                                          child: Text(
                                            switch (program) {
                                              Program.it => 'BSIT',
                                              Program.emc => 'BSEMC',
                                              Program.both =>
                                                'Both BSIT and BSEMC',
                                            },
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setModalState(() {
                                      selectedProgram = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? 'Required' : null,
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 16,
                                      color: primaryPurple,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Preferred Teaching Days & Time',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      [
                                        DayOfWeek.mon,
                                        DayOfWeek.tue,
                                        DayOfWeek.wed,
                                        DayOfWeek.thu,
                                        DayOfWeek.fri,
                                        DayOfWeek.sat,
                                      ].map((day) {
                                        final isSelected = selectedDay == day;
                                        return GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              selectedDay = day;
                                              selectedShiftPreference =
                                                  FacultyShiftPreference.custom;
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? primaryPurple
                                                  : Colors.white,
                                              border: Border.all(
                                                color: isSelected
                                                    ? primaryPurple
                                                    : Colors.black,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: primaryPurple
                                                            .withValues(
                                                              alpha: 0.25,
                                                            ),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Text(
                                              _dayLabel(day),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: startTime,
                                            helpText: 'Select Start Time',
                                          );
                                          if (picked != null) {
                                            setModalState(() {
                                              startTime = picked;
                                              selectedShiftPreference =
                                                  FacultyShiftPreference.custom;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bgBody,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 16,
                                                color: primaryPurple,
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Start',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: textMuted,
                                                    ),
                                                  ),
                                                  Text(
                                                    startTime.format(context),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        '->',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: endTime,
                                            helpText: 'Select End Time',
                                          );
                                          if (picked != null) {
                                            setModalState(() {
                                              endTime = picked;
                                              selectedShiftPreference =
                                                  FacultyShiftPreference.custom;
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bgBody,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 16,
                                                color: primaryPurple,
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'End',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: textMuted,
                                                    ),
                                                  ),
                                                  Text(
                                                    endTime.format(context),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final startMinutes =
                                          startTime.hour * 60 +
                                          startTime.minute;
                                      final endMinutes =
                                          endTime.hour * 60 + endTime.minute;
                                      if (endMinutes <= startMinutes) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'End time must be later than start time.',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }

                                      for (final existing in availabilities) {
                                        if (existing.day == selectedDay) {
                                          final existingStart =
                                              existing.start.hour * 60 +
                                              existing.start.minute;
                                          final existingEnd =
                                              existing.end.hour * 60 +
                                              existing.end.minute;
                                          if (startMinutes < existingEnd &&
                                              existingStart < endMinutes) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Overlapping availability for the same day.',
                                                ),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }
                                        }
                                      }

                                      setModalState(() {
                                        availabilities.add(
                                          _AvailabilityEntry(
                                            day: selectedDay,
                                            start: startTime,
                                            end: endTime,
                                          ),
                                        );
                                        selectedShiftPreference =
                                            FacultyShiftPreference.custom;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Add Availability',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      side: BorderSide(
                                        color: primaryPurple,
                                        width: 1.5,
                                      ),
                                      foregroundColor: primaryPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                if (availabilities.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: primaryPurple.withValues(
                                        alpha: 0.04,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: primaryPurple.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Added Availability (${availabilities.length})',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: primaryPurple,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...availabilities.asMap().entries.map((
                                          entry,
                                        ) {
                                          final index = entry.key;
                                          final availability = entry.value;
                                          return Container(
                                            margin: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: primaryPurple.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${_dayLabel(availability.day)} • ${availability.start.format(context)} - ${availability.end.format(context)}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    setModalState(() {
                                                      availabilities.removeAt(
                                                        index,
                                                      );
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    size: 18,
                                                  ),
                                                  color: Colors.redAccent,
                                                  tooltip: 'Remove',
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        foregroundColor: textMuted,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          side: BorderSide(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        if (!isStudent &&
                                            availabilities.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Add at least one preferred teaching day and time.',
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }

                                        final normalizedSection = isStudent
                                            ? _normalizeSectionCode(
                                                sectionController.text,
                                              )
                                            : '';

                                        Navigator.pop(context, {
                                          'name': nameController.text.trim(),
                                          'email': emailController.text.trim(),
                                          'studentId': isStudent
                                              ? idController.text.trim()
                                              : '',
                                          'facultyId': isStudent
                                              ? ''
                                              : idController.text.trim(),
                                          'course': isStudent
                                              ? selectedCourse
                                              : '',
                                          'section': normalizedSection,
                                          'maxLoad': isStudent
                                              ? ''
                                              : maxLoadController.text.trim(),
                                          'employmentStatus': isStudent
                                              ? ''
                                              : selectedEmploymentStatus.name,
                                          'shiftPreference': isStudent
                                              ? ''
                                              : selectedShiftPreference.name,
                                          'program': isStudent
                                              ? ''
                                              : selectedProgram.name,
                                          'password': passwordController.text,
                                          'availability': isStudent
                                              ? ''
                                              : _serializeAvailabilityEntries(
                                                  availabilities,
                                                ),
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryPurple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        isStudent
                                            ? 'Complete Student Access'
                                            : 'Complete Faculty Access',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF333333).withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRoleSelectionDialog() {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          _facultyColorLight,
                          _studentColorLight,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose Your Access',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pick the role that matches your official account. Admin access is managed separately and is not available here.',
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 460;
                      final cards = [
                        _buildRoleChoiceCard(
                          role: 'student',
                          title: 'Student',
                          description:
                              'For enrolled students viewing schedules, sections, and personal timetable details.',
                          icon: Icons.school_rounded,
                          color: _studentColorLight,
                        ),
                        _buildRoleChoiceCard(
                          role: 'faculty',
                          title: 'Faculty',
                          description:
                              'For instructors managing teaching schedules, workload, and class assignments.',
                          icon: Icons.badge_rounded,
                          color: _facultyColorLight,
                        ),
                      ];

                      if (isCompact) {
                        return Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 14),
                            cards[1],
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 14),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel Google Sign-In',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmFacultyApprovalRequest() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _facultyColorLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: _facultyColorLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Faculty Approval Required',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Faculty access needs admin approval before you can use the faculty dashboard. Select Okay to continue with your request, or Cancel to choose a different role.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: const Color(0xFF475569),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _facultyColorLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Okay',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _buildRoleChoiceCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => Navigator.pop(context, role),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.12),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Continue as $title',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, color: color, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _resolveExistingGoogleRole(UserInfo? userInfo) async {
    if (userInfo?.scopeNames.contains('admin') ?? false) {
      return 'admin';
    }

    try {
      final studentProfile = await client.student.getMyProfile();
      if (studentProfile != null) {
        return 'student';
      }
    } catch (_) {}

    try {
      final facultyProfile = await client.faculty.getMyProfile();
      if (facultyProfile != null) {
        return 'faculty';
      }
    } catch (_) {}

    return null;
  }

  @override
  void initState() {
    super.initState();
    _googleAuthController = GoogleAuthController(
      client: client,
      onAuthenticated: _handleGoogleAuthenticated,
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = _describeGoogleError(error);
          _isLoading = false;
        });
      },
      // We only need the Google ID token for Serverpod sign-in.
      // Avoid requesting additional OAuth scopes on web, as that adds an
      // extra access-token authorization step that has been unreliable in the
      // deployed popup flow.
      scopes: const [],
    );
    _googleAuthController.addListener(_handleGoogleControllerChanged);
  }

  @override
  void dispose() {
    _googleAuthController.removeListener(_handleGoogleControllerChanged);
    _googleAuthController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildLoginScreen(context);

  Widget _buildLoginScreen(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final localeTag = Localizations.maybeLocaleOf(
      context,
    )?.toLanguageTag();
    final isDesktop = screenSize.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthBusy = _isLoading || _googleAuthController.isLoading;

    // --- 1. DYNAMIC THEME COLORS ---

    // Main Backgrounds
    final bgBody = isDark ? _bgBodyDark : _bgBodyLight;
    final bgRight = isDark ? _bgRightDark : _bgRightLight;
    final cardBg = isDark ? _cardBgDark : _cardBgLight;

    // Text Colors
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textMuted = isDark ? Colors.white60 : Colors.grey.shade600;

    // Input Fields
    final inputFillColor = isDark
        ? const Color(0xFF334155)
        : Colors.grey.shade200;
    final inputBorderColor = isDark ? Colors.transparent : Colors.transparent;
    final inputTextColor = isDark ? Colors.white : Colors.black87;

    // Active Brand Color (Purple/Pink)
    final activeThemeColor = _resolveActiveThemeColor(isDark: isDark);

    // Google Button Specifics
    final googleBtnBg = isDark ? Colors.transparent : Colors.white;
    final googleBtnBorder = isDark ? Colors.white54 : Colors.grey.shade300;
    // --- 2. INPUT FIELD BUILDER (Fixed: No active green outline) ---
    Widget buildCustomField({
      required TextEditingController controller,
      required String hintText,
      bool isPassword = false,
    }) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: inputFillColor,
          borderRadius: BorderRadius.circular(12),
          // We use a static border color (or transparent if you prefer no border)
          border: Border.all(color: inputBorderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          obscuringCharacter: '\u2022',
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: textPrimary, // Cursor matches text color
          style: GoogleFonts.poppins(
            color: inputTextColor, // Typing text color (White/Black)
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: false,
            fillColor: Colors.transparent,
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              color: textMuted,
              fontSize: 14,
            ),
            // Disable all default borders to prevent the green line
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: textMuted,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgBody,
      body: Row(
        children: [
          // Left Side (Desktop Image)
          if (isDesktop)
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/jmcbackground.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: activeThemeColor),
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.3)),
                  Padding(
                    padding: const EdgeInsets.all(80.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CITESched',
                          style: GoogleFonts.poppins(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Secure access to faculty loading and schedules.',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Right Side (Form)
          Expanded(
            flex: 1,
            child: Container(
              color: bgRight,
              child: Stack(
                children: [
                  // Login Form Center
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(40),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 50,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Image.asset(
                                  'assets/jmclogo.png',
                                  width: 90,
                                  errorBuilder: (ctx, err, stack) => Icon(
                                    Icons.school,
                                    size: 60,
                                    color: activeThemeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),

                              // HEADER TEXT (Fixed Color)
                              Text(
                                _loginTitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      textPrimary, // Uses White (Dark) or Black (Light)
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Welcome back! Please enter your details.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Role Switcher
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    _buildRoleBtn(
                                      'Faculty',
                                      true,
                                      cardBg,
                                      activeThemeColor,
                                      textMuted,
                                    ),
                                    _buildRoleBtn(
                                      'Student',
                                      false,
                                      cardBg,
                                      activeThemeColor,
                                      textMuted,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),

                              // Inputs
                              _buildLabel(_idLabel, textPrimary),
                              const SizedBox(height: 8),
                              buildCustomField(
                                controller: _idController,
                                hintText: _idHint,
                              ),

                              const SizedBox(height: 16),

                              _buildLabel('Password', textPrimary),
                              const SizedBox(height: 8),
                              buildCustomField(
                                controller: _passwordController,
                                hintText: '••••••••',
                                isPassword: true,
                              ),

                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: isAuthBusy
                                      ? null
                                      : () => showPasswordResetDialog(
                                          context,
                                          title: 'Forgot Password?',
                                          subtitle:
                                              'Use your email to recover your CITESched access and set a new password.',
                                        ),
                                  icon: const Icon(
                                    Icons.lock_reset_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: activeThemeColor,
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Login Button
                              ElevatedButton(
                                onPressed: isAuthBusy ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeThemeColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.all(14),
                                  textStyle: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isAuthBusy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('SIGN IN'),
                              ),

                              const SizedBox(height: 40),
                              Text(
                                'OR SIGN IN WITH',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Google Button (uses platform-safe widget)
                              IgnorePointer(
                                ignoring: isAuthBusy,
                                child: Opacity(
                                  opacity: isAuthBusy ? 0.7 : 1,
                                  child: GoogleSignInWidget(
                                    controller: _googleAuthController,
                                    theme: isDark
                                        ? GSIButtonTheme.filledBlack
                                        : GSIButtonTheme.outline,
                                    size: GSIButtonSize.large,
                                    text: GSIButtonText.continueWith,
                                    shape: GSIButtonShape.pill,
                                    logoAlignment:
                                        GSIButtonLogoAlignment.center,
                                    minimumWidth: 320,
                                    locale: localeTag ?? 'en',
                                    buttonWrapper:
                                        ({
                                          required GoogleSignInStyle style,
                                          required Widget child,
                                          required VoidCallback? onPressed,
                                        }) {
                                          return Container(
                                            height: 50,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: googleBtnBg,
                                              border: Border.all(
                                                color: googleBtnBorder,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: child,
                                          );
                                        },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Keep theme toggle above the login card layer
                  const Positioned(
                    top: 25,
                    right: 25,
                    child: SafeArea(child: ThemeModeToggle(compact: true)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBtn(
    String text,
    bool targetIsFaculty,
    Color cardBg,
    Color activeTheme,
    Color textMuted,
  ) {
    bool isActive = _isFaculty == targetIsFaculty;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isFaculty = targetIsFaculty;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        51,
                        51,
                        51,
                      ).withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isActive ? activeTheme : textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w500, // fw-medium
        color: color,
        fontSize: 16,
      ),
    );
  }

  Future<UserInfo?> _loadUserInfoByEmail(String? email) async {
    if (email == null || email.isEmpty) {
      return null;
    }
    return client.setup.getUserInfoByEmail(email: email);
  }

  Future<String?> _loadExistingRoleByEmail(String? email) async {
    final normalizedEmail = email?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return null;
    }

    final role = await client.setup.getExistingAccountRoleByEmail(
      email: normalizedEmail,
    );
    if (role == null) {
      return null;
    }

    final normalizedRole = role.trim().toLowerCase();
    if (normalizedRole == 'admin' ||
        normalizedRole == 'faculty' ||
        normalizedRole == 'student' ||
        normalizedRole == 'faculty_pending' ||
        normalizedRole == 'faculty_declined') {
      return normalizedRole;
    }

    return null;
  }

  String _dayLabel(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Mon';
      case DayOfWeek.tue:
        return 'Tue';
      case DayOfWeek.wed:
        return 'Wed';
      case DayOfWeek.thu:
        return 'Thu';
      case DayOfWeek.fri:
        return 'Fri';
      case DayOfWeek.sat:
        return 'Sat';
      case DayOfWeek.sun:
        return 'Sun';
    }
  }

  String _formatAvailabilityTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _serializeAvailabilityEntries(List<_AvailabilityEntry> entries) {
    return entries
        .map(
          (entry) =>
              '${entry.day.name}|${_formatAvailabilityTime(entry.start)}|${_formatAvailabilityTime(entry.end)}',
        )
        .join(';');
  }

  List<_AvailabilityEntry> _deserializeAvailabilityEntries(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return const [];
    }

    final entries = <_AvailabilityEntry>[];
    for (final rawEntry in payload.split(';')) {
      final trimmed = rawEntry.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.split('|');
      if (parts.length != 3) continue;
      entries.add(
        _AvailabilityEntry(
          day: DayOfWeek.fromJson(parts[0]),
          start: _timeOfDayFrom24Hour(parts[1]),
          end: _timeOfDayFrom24Hour(parts[2]),
        ),
      );
    }
    return entries;
  }

  TimeOfDay _timeOfDayFrom24Hour(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _timeOfDayToServer(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveFacultyAvailability(
    String email,
    List<_AvailabilityEntry> availabilities,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || availabilities.isEmpty) {
      return;
    }

    final inactiveFaculty = await client.admin.getAllFaculty(isActive: false);
    final activeFaculty = await client.admin.getAllFaculty(isActive: true);
    final allFaculty = [...inactiveFaculty, ...activeFaculty];

    Faculty? targetFaculty;
    for (final faculty in allFaculty) {
      if (faculty.email.trim().toLowerCase() == normalizedEmail) {
        targetFaculty = faculty;
        break;
      }
    }

    if (targetFaculty?.id == null) {
      throw Exception('Unable to find the created faculty profile.');
    }
    final resolvedFaculty = targetFaculty!;

    final now = DateTime.now();
    final payload = availabilities
        .map(
          (entry) => FacultyAvailability(
            facultyId: resolvedFaculty.id!,
            dayOfWeek: entry.day,
            startTime: _timeOfDayToServer(entry.start),
            endTime: _timeOfDayToServer(entry.end),
            isPreferred: true,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();

    await client.admin.setFacultyAvailability(resolvedFaculty.id!, payload);
  }

  Future<String?> _adoptExistingGoogleAccount(String? email) async {
    final normalizedEmail = email?.trim();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return null;
    }

    try {
      return await client.setup.adoptExistingAccountByEmail(
        email: normalizedEmail,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _rememberGoogleRole(String? email, String role) async {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return;
    }

    try {
      await _secureStorage.write(
        key: '$_googleRoleStoragePrefix$normalizedEmail',
        value: role,
      );
    } catch (_) {}
  }

  Future<bool> _shouldShowFacultyDeclinedNotice(String? email) async {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return true;
    }

    try {
      final stored = await _secureStorage.read(
        key: '$_googleDeclinedNoticeStoragePrefix$normalizedEmail',
      );
      return stored != 'shown';
    } catch (_) {
      return true;
    }
  }

  Future<void> _markFacultyDeclinedNoticeShown(String? email) async {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return;
    }

    try {
      await _secureStorage.write(
        key: '$_googleDeclinedNoticeStoragePrefix$normalizedEmail',
        value: 'shown',
      );
    } catch (_) {}
  }

  Future<void> _clearFacultyDeclinedNoticeState(String? email) async {
    final normalizedEmail = email?.trim().toLowerCase();
    if (normalizedEmail == null || normalizedEmail.isEmpty) {
      return;
    }

    try {
      await _secureStorage.delete(
        key: '$_googleDeclinedNoticeStoragePrefix$normalizedEmail',
      );
    } catch (_) {}
  }

  Future<String> _finalizeResolvedGoogleRole(
    String resolvedRole, {
    required UserInfo? userInfo,
    required String? email,
    required AuthNotifier authNotifier,
  }) async {
    final resolvedUserInfo = userInfo ?? await _loadUserInfoByEmail(email);
    if (resolvedUserInfo != null) {
      authNotifier.updateUserInfo(resolvedUserInfo);
    }
    await _rememberGoogleRole(email, resolvedRole);
    if (resolvedRole != 'faculty_declined') {
      await _clearFacultyDeclinedNoticeState(email);
    }
    return resolvedRole;
  }

  Future<String?> _resolveGoogleRoleSelection({
    required UserInfo? userInfo,
    required String? email,
    required String? displayName,
    required AuthNotifier authNotifier,
  }) async => _resolveGoogleRoleSelectionImpl(
    userInfo: userInfo,
    email: email,
    displayName: displayName,
    authNotifier: authNotifier,
  );

  Future<String?> _resolveGoogleRoleSelectionImpl({
    required UserInfo? userInfo,
    required String? email,
    required String? displayName,
    required AuthNotifier authNotifier,
  }) async {
    final adoptedRole = await _adoptExistingGoogleAccount(email);
    final roleFromEmail = adoptedRole ?? await _loadExistingRoleByEmail(email);
    if (roleFromEmail == 'faculty_pending') {
      return roleFromEmail;
    }
    if (roleFromEmail == 'faculty_declined') {
      if (await _shouldShowFacultyDeclinedNotice(email)) {
        await _showFacultyDeclinedNotice();
        await _markFacultyDeclinedNoticeShown(email);
      }
    }
    final existingRole = roleFromEmail == 'faculty_declined'
        ? null
        : roleFromEmail ?? await _resolveExistingGoogleRole(userInfo);

    if (existingRole == 'admin' ||
        existingRole == 'faculty' ||
        existingRole == 'student') {
      return _finalizeResolvedGoogleRole(
        existingRole!,
        userInfo: userInfo,
        email: email,
        authNotifier: authNotifier,
      );
    }

    while (true) {
      final selectedRole = await _showRoleSelectionDialog();
      if (selectedRole == null) {
        return null;
      }

      if (selectedRole == 'faculty') {
        final confirmed = await _confirmFacultyApprovalRequest();
        if (!confirmed) {
          continue;
        }
        await _clearFacultyDeclinedNoticeState(email);
      }

      final completed = await _completeGoogleProfile(
        selectedRole,
        email: email,
        displayName: displayName,
      );
      if (!completed) {
        throw Exception('Failed to set up account details.');
      }

      final resolvedEmail = email?.trim();
      if (resolvedEmail == null || resolvedEmail.isEmpty) {
        throw Exception('Missing email from Google profile.');
      }

      if (selectedRole == 'faculty') return 'faculty_pending';

      final refreshedInfo = await client.setup.getUserInfoByEmail(
        email: resolvedEmail,
      );
      if (refreshedInfo == null) {
        throw Exception('Unable to refresh user info after setup.');
      }
      await _adoptExistingGoogleAccount(resolvedEmail);
      await _rememberGoogleRole(resolvedEmail, selectedRole);
      authNotifier.updateUserInfo(refreshedInfo);
      return selectedRole;
    }
  }

  String _roleDetailsTitle(String role) {
    if (role == 'student') {
      return 'Complete Student Access';
    }
    if (role == 'faculty') {
      return 'Complete Faculty Access';
    }
    return 'Administrator';
  }

  Color _resolveActiveThemeColor({required bool isDark}) {
    if (isDark) {
      return _isFaculty ? _facultyColorDark : _studentColorDark;
    }
    return _isFaculty ? _facultyColorLight : _studentColorLight;
  }
}
//testing

class _AvailabilityEntry {
  final DayOfWeek day;
  final TimeOfDay start;
  final TimeOfDay end;

  const _AvailabilityEntry({
    required this.day,
    required this.start,
    required this.end,
  });
}
