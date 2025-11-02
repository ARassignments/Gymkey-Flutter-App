import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../forgot_password_screen.dart';
import '../otp_verification_screen.dart';
import '../signup_screen.dart';
import '../../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contactController = TextEditingController();

  bool _isFormValid = false;
  bool _isLoading = false;
  bool _rememberMe = true;
  bool get _isFormDisabled => _isLoading || !_isFormValid;
  CountryCode _selectedCountryCode = CountryCode.fromCountryCode('IN');
  final String _previousCountryCode = '+1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_formKey.currentState == null) {
        debugPrint('Warning: Form key not attached to any Form widget');
      }
    });

    _contactController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    final allFieldsFilled = _contactController.text.isNotEmpty;

    setState(() {
      _isFormValid = isValid && allFieldsFilled;
    });

    return _isFormValid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: ListView(children: [_buildLoginForm()]));
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      onChanged:
          _validateForm, // This will trigger validation on any form change
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppTheme.appLogo(context), height: 100, width: 100),
            SizedBox(height: 40),
            Text(
              "Login to Yet To Explore",
              style: AppTheme.textTitle(context),
              textAlign: TextAlign.start,
            ),

            SizedBox(height: 20),
            TextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              controller: _contactController,
              style: AppInputDecoration.inputTextStyle(context),
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number*',
                hintText: 'e.g. 1234567890',
                counter: const SizedBox.shrink(),
                prefixIcon: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountryCodePicker(
                        onChanged: (country) {
                          setState(() {
                            _selectedCountryCode = country;
                          });
                        },
                        builder: (country) =>
                            AppInputDecoration.buildCountryCodeButton(
                              context,
                              country,
                            ),
                        padding: EdgeInsets.zero,
                        boxDecoration: AppTheme.dialogBg(context),
                        flagDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        flagWidth: 30,
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        initialSelection: 'IN',
                        favorite: ['US', 'GB', 'IN'],
                        alignLeft: false,
                        showFlag: true,
                        showFlagDialog: true,
                        searchStyle: AppInputDecoration.inputTextStyle(context),
                        textStyle: AppInputDecoration.inputTextStyle(context),
                        dialogTextStyle: AppInputDecoration.inputTextStyle(
                          context,
                        ),
                        dialogBackgroundColor: AppTheme.screenBg(context),
                        headerTextStyle: AppTheme.textTitle(context),
                        headerText: 'Select Country/Region',
                        dialogSize: Size(
                          MediaQuery.of(context).size.width * 0.9,
                          400,
                        ),
                      ),
                      Container(height: 20, width: 1, color: Colors.grey),
                    ],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Only digits allowed';
                } else if (value.length < 8) {
                  return 'Phone Number too short';
                }
                return null;
              },
              maxLength: 15,
            ),

            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: AppTheme.checkBox(context),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                        // You can add additional logic here
                      },
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Text(
                        'Remember Me',
                        style: AppTheme.textLabel(context),
                      ),
                    ),
                  ],
                ),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTheme.textLabel(context),
                    children: [
                      TextSpan(
                        text: 'Forgot Password?',
                        style: AppTheme.textLink(context),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  ForgotPasswordScreen(),
                              transitionsBuilder: (_, a, __, c) =>
                                  FadeTransition(opacity: a, child: c),
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTheme.textLabel(context).copyWith(fontSize: 12),
                children: [
                  TextSpan(text: 'By register, you agree to our '),
                  TextSpan(
                    text: 'Terms & Condition, ',
                    style: AppTheme.textLink(context).copyWith(fontSize: 12),
                  ),
                  TextSpan(
                    text: 'Data Policy ',
                    style: AppTheme.textLink(context).copyWith(fontSize: 12),
                  ),
                  TextSpan(text: 'and '),
                  TextSpan(
                    text: 'Cookies Policy.',
                    style: AppTheme.textLink(context).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              "We'll call or text you to confirm your number. Standard message and data rates may apply.",
              style: AppTheme.textLabel(context).copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            FlatButton(
              text: 'Continue',
              disabled: !_isFormValid || _isLoading,
              onPressed: (_isFormValid && !_isLoading)
                  ? () async {
                      if (!_validateForm()) return; // Use validation method
                      await _submitLoginForm();
                    }
                  : null,
              loading: _isLoading,
            ),
            // SizedBox(height: 20),
            // RichText(
            //   textAlign: TextAlign.center,
            //   text: TextSpan(
            //     style: AppTheme.textLabel(context),
            //     children: [
            //       TextSpan(text: 'Don’t have an account? '),
            //       TextSpan(
            //         text: 'Register',
            //         style: AppTheme.textLink(context),
            //         recognizer: TapGestureRecognizer()
            //           ..onTap = () => Navigator.of(context).push(
            //             PageRouteBuilder(
            //               pageBuilder: (_, __, ___) => SignupScreen(),
            //               transitionsBuilder: (_, a, __, c) =>
            //                   FadeTransition(opacity: a, child: c),
            //             ),
            //           ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLoginForm() async {
    if (_contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Combine all form data
      final formData = {
        'phone':
            '${_selectedCountryCode.dialCode ?? ''}${_contactController.text.trim()}',
      };

      // Call your API here
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder:
        //         (_) => OTPVerificationScreen(
        //           phoneNumber: _contactController.text.trim(),
        //           countryCode: _selectedCountryCode.dialCode ?? '',
        //         ),
        //   ),
        // );
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SignupScreen(
              phoneNumber: _contactController.text.trim(),
              countryCode: _selectedCountryCode.dialCode ?? '',
            ),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
