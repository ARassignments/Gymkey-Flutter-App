import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '../../screens/login_screen.dart';
import '../../screens/otp_verification_screen.dart';
import '../../theme/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  bool _isFormValid = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureCPassword = true;
  bool get _isFormDisabled => _isLoading || !_isFormValid;
  CountryCode _selectedCountryCode = CountryCode.fromCountryCode('IN');

  int _currentStep = 0; // 0 = personal info, 1 = location
  int _previousStep = 0;
  String _selectedCountry = '';
  String _selectedState = '';
  String _selectedCity = '';
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];
  bool _isLoadingCountries = true;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _contactController.addListener(_validateForm);
    _fetchCountries();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _fetchCountries() async {
    final response = await http.get(
      Uri.parse('https://countriesnow.space/api/v0.1/countries/positions'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _countries = List<String>.from(data['data'].map((e) => e['name']));
        _isLoadingCountries = false;
        _validateForm();
      });
    }
  }

  Future<void> _fetchStates(String country) async {
    setState(() {
      _isLoadingStates = true;
    });

    final response = await http.post(
      Uri.parse('https://countriesnow.space/api/v0.1/countries/states'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'country': country}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _states = List<String>.from(
          data['data']['states'].map((e) => e['name']),
        );
        _isLoadingStates = false;
        _validateForm();
      });
    }
  }

  Future<void> _fetchCities(String country, String state) async {
    setState(() {
      _isLoadingCities = true;
    });

    final response = await http.post(
      Uri.parse('https://countriesnow.space/api/v0.1/countries/state/cities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'country': country, 'state': state}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _cities = List<String>.from(data['data']);
        _isLoadingCities = false;
        _validateForm();
      });
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      // Validate only name field for step 0
      final isNameValid =
          _nameController.text.isNotEmpty &&
          _nameController.text.length >= 3 &&
          RegExp(r'^[a-zA-Z ]+$').hasMatch(_nameController.text);

      final isEmailValid =
          _emailController.text.isNotEmpty &&
          _emailController.text.length >= 5 &&
          RegExp(
            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
          ).hasMatch(_emailController.text);

      final isPasswordValid =
          _passwordController.text.isNotEmpty &&
          _passwordController.text.length >= 8;

      final isConfirmPasswordValid =
          _confirmPasswordController.text == _passwordController.text;

      return isNameValid &&
          isEmailValid &&
          isPasswordValid &&
          isConfirmPasswordValid;
    } else if (_currentStep == 1) {
      // Validate location fields for step 1
      return _contactController.text.isNotEmpty &&
          _contactController.text.length >= 8 &&
          RegExp(r'^[0-9]+$').hasMatch(_contactController.text);
    } else {
      // Validate location fields for step 2
      return _selectedCountry.isNotEmpty &&
          _selectedState.isNotEmpty &&
          _selectedCity.isNotEmpty;
    }
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _validateCurrentStep();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            final isForward = _currentStep >= _previousStep;

            final offsetAnimation = Tween<Offset>(
              begin: isForward
                  ? const Offset(1.0, 0.0)
                  : const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(animation);

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(animation);

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: SingleChildScrollView(
            key: ValueKey(_currentStep), // important for AnimatedSwitcher
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentStep == 0) _buildPersonalInfoForm(),
                  if (_currentStep == 1) _buildContactForm(),
                  if (_currentStep == 2) _buildLocationForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoForm() {
    return Form(
      key: _formKey,
      onChanged: _validateForm,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppTheme.appLogo(context), height: 100, width: 100),
            const SizedBox(height: 40),
            Text(
              "Personal Information",
              style: AppTheme.textTitle(context),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Full Name*',
                hintText: 'e.g. David Smith',
                counter: const SizedBox.shrink(),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Icon(HugeIconsSolid.user03),
                ),
                suffixIcon: _isLoading
                    ? null
                    : _nameController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: Icon(HugeIconsStroke.cancel02),
                          onPressed: () {
                            _nameController.clear(); // Clear the text field
                          },
                        ),
                      )
                    : null,
              ),
              style: AppInputDecoration.inputTextStyle(context),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                } else if (value.length < 3) {
                  return 'Name must be at least 3 characters long';
                } else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
                  return 'Name must contain only letters';
                }
                return null;
              },
              maxLength: 20,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Email Address*',
                hintText: 'e.g. david@example.com',
                counter: const SizedBox.shrink(),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Icon(HugeIconsSolid.mail02),
                ),
                suffixIcon: _isLoading
                    ? null
                    : _emailController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: Icon(HugeIconsStroke.cancel02),
                          onPressed: () {
                            _emailController.clear(); // Clear the text field
                          },
                        ),
                      )
                    : null,
              ),
              style: AppInputDecoration.inputTextStyle(context),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email address';
                } else if (value.length < 5) {
                  return 'Email Address must be at least 5 characters long';
                } else if (!RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
              maxLength: 40,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Password*',
                hintText: 'e.g. dav*****',
                counter: const SizedBox.shrink(),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Icon(HugeIconsSolid.lockKey),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? HugeIconsSolid.viewOff
                          : HugeIconsSolid.eye,
                    ),
                    splashRadius: 20, // Smaller tap area
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              style: AppInputDecoration.inputTextStyle(context),
              obscureText: _obscurePassword,
              obscuringCharacter: '•',
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                } else if (value.length < 8) {
                  return 'Password must be at least 8 characters long';
                }
                return null;
              },
              maxLength: 20,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Confirm Password*',
                hintText: 'e.g. dav*****',
                counter: const SizedBox.shrink(),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Icon(HugeIconsSolid.lockKey),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: Icon(
                      _obscureCPassword
                          ? HugeIconsSolid.viewOff
                          : HugeIconsSolid.eye,
                    ),
                    splashRadius: 20, // Smaller tap area
                    onPressed: () {
                      setState(() => _obscureCPassword = !_obscureCPassword);
                    },
                  ),
                ),
              ),
              style: AppInputDecoration.inputTextStyle(context),
              obscureText: _obscureCPassword,
              obscuringCharacter: '•',
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your confirm password';
                } else if (value.length < 8) {
                  return 'Confirm Password must be at least 8 characters long';
                } else if (value != _passwordController.text) {
                  return 'Confirm Passwords do not match';
                }
                return null;
              },
              maxLength: 20,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                Expanded(
                  flex: 1,
                  child: OutlineButton(
                    text: 'Cancel',
                    disabled: _isLoading,
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: FlatButton(
                    text: 'Next',
                    disabled: !_isFormValid || _isLoading,
                    onPressed: (_isFormValid && !_isLoading)
                        ? () {
                            if (_validateCurrentStep()) {
                              setState(() {
                                _previousStep = _currentStep;
                                _currentStep = 1;
                              });
                            }
                          }
                        : null,
                    loading: _isLoading,
                    icon: Icons.arrow_forward_ios_rounded,
                    iconLeft: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Form(
      key: _formKey,
      onChanged: _validateForm,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppTheme.appLogo(context), height: 100, width: 100),
            const SizedBox(height: 40),
            Text(
              "Contact Number",
              style: AppTheme.textTitle(context),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
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
                suffixIcon: _isLoading
                    ? null
                    : _contactController.text.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: Icon(HugeIconsStroke.cancel02),
                          onPressed: () {
                            _contactController.clear(); // Clear the text field
                          },
                        ),
                      )
                    : null,
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
            const SizedBox(height: 16),
            Text(
              "We'll call or text you to confirm your number. Standard message and data rates may apply.",
              style: AppTheme.textLabel(context).copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                Expanded(
                  flex: 1,
                  child: OutlineButton(
                    text: 'Back',
                    disabled: _isLoading,
                    onPressed: () {
                      setState(() {
                        _previousStep = _currentStep;
                        _currentStep = 0;
                        _validateForm();
                      });
                    },
                    icon: Icons.arrow_back_ios_rounded,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: FlatButton(
                    text: 'Next',
                    disabled: !_isFormValid || _isLoading,
                    onPressed: (_isFormValid && !_isLoading)
                        ? () {
                            if (_validateCurrentStep()) {
                              setState(() {
                                _previousStep = _currentStep;
                                _currentStep = 2;
                              });
                            }
                          }
                        : null,
                    loading: _isLoading,
                    icon: Icons.arrow_forward_ios_rounded,
                    iconLeft: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationForm() {
    return Form(
      key: _formKey,
      onChanged: _validateForm,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppTheme.appLogo(context), height: 100, width: 100),
            const SizedBox(height: 40),
            Text(
              "Where are you located?",
              style: AppTheme.textTitle(context),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry.isEmpty ? null : _selectedCountry,
              decoration: InputDecoration(
                labelText: 'Country*',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Icon(HugeIconsSolid.globe),
                ),
              ),
              items: _isLoadingCountries
                  ? [
                      DropdownMenuItem(
                        value: null,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppTheme.inputProgress(context),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : _countries.map((String country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountry = newValue ?? '';
                  _selectedState = '';
                  _selectedCity = '';
                  _states = [];
                  _cities = [];
                });
                _validateForm();
                if (_selectedCountry.isNotEmpty) {
                  _fetchStates(_selectedCountry);
                }
              },
              validator: (value) =>
                  value == null ? 'Please select a country' : null,
              icon: const Icon(Icons.arrow_drop_down_rounded),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedState.isEmpty ? null : _selectedState,
              decoration: InputDecoration(
                labelText: 'State*',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Icon(HugeIconsSolid.location02),
                ),
              ),
              items: _isLoadingStates
                  ? [
                      DropdownMenuItem(
                        value: null,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppTheme.inputProgress(context),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : _states.map((String state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(state),
                      );
                    }).toList(),
              onChanged: _selectedCountry.isEmpty
                  ? null
                  : (String? newValue) {
                      setState(() {
                        _selectedState = newValue ?? '';
                        _selectedCity = '';
                        _cities = [];
                      });
                      _validateForm();
                      if (_selectedState.isNotEmpty) {
                        _fetchCities(_selectedCountry, _selectedState);
                      }
                    },
              validator: (value) =>
                  value == null ? 'Please select a state' : null,
              icon: const Icon(Icons.arrow_drop_down_rounded),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity.isEmpty ? null : _selectedCity,
              decoration: InputDecoration(
                labelText: 'City*',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                  child: Icon(HugeIconsSolid.building02),
                ),
              ),
              items: _isLoadingCities
                  ? [
                      DropdownMenuItem(
                        value: null,
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppTheme.inputProgress(context),
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : _cities.map((String city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
              onChanged: _selectedState.isEmpty
                  ? null
                  : (String? newValue) {
                      setState(() {
                        _selectedCity = newValue ?? '';
                      });
                      _validateForm();
                    },
              validator: (value) =>
                  value == null ? 'Please select a city' : null,
              icon: const Icon(Icons.arrow_drop_down_rounded),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTheme.textLabel(context).copyWith(fontSize: 12),
                children: [
                  TextSpan(text: 'By register, you agree to our '),
                  TextSpan(
                    text: 'Terms & Condition, ',
                    style: AppTheme.textLink(context).copyWith(fontSize: 12),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        debugPrint("Terms & Condition clicked");
                      },
                  ),
                  TextSpan(
                    text: 'Data Policy ',
                    style: AppTheme.textLink(context).copyWith(fontSize: 12),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        debugPrint("Data Policy clicked");
                      },
                  ),
                  TextSpan(text: 'and '),
                  TextSpan(
                    text: 'Cookies Policy.',
                    style: AppTheme.textLink(context).copyWith(fontSize: 12),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        debugPrint("Cookies Policy clicked");
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                Expanded(
                  flex: 1,
                  child: OutlineButton(
                    text: 'Back',
                    disabled: _isLoading,
                    onPressed: () {
                      setState(() {
                        _previousStep = _currentStep;
                        _currentStep = 1;
                        _validateForm();
                      });
                    },
                    icon: Icons.arrow_back_ios_rounded,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: FlatButton(
                    text: 'Register',
                    disabled: !_isFormValid || _isLoading,
                    onPressed: (_isFormValid && !_isLoading)
                        ? () async {
                            if (!_validateCurrentStep()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please complete all fields'),
                                ),
                              );
                              return;
                            }
                            await _submitCompleteForm();
                          }
                        : null,
                    loading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCompleteForm() async {
    if (!_validateCurrentStep()) return;
    setState(() => _isLoading = true);

    try {
      final formData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'pwd': _passwordController.text.trim(),
        'contact': _contactController.text.trim(),
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
      };

      // Call your API here
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (_) => const LoginScreen()),
        // );
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder:
        //         (_) => OTPVerificationScreen(
        //           phoneNumber: widget.phoneNumber,
        //           countryCode: widget.countryCode ?? '',
        //         ),
        //   ),
        // );
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
