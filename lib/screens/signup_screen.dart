import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../theme/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SignupScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  const SignupScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  bool _isFormValid = false;
  bool _isLoading = false;
  bool get _isFormDisabled => _isLoading || !_isFormValid;

  int _currentStep = 0; // 0 = personal info, 1 = location
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
    _fetchCountries();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      return _nameController.text.isNotEmpty &&
          _nameController.text.length >= 3 &&
          RegExp(r'^[a-zA-Z ]+$').hasMatch(_nameController.text);
    } else {
      // Validate location fields for step 1
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
      body: ListView(
        children: [
          if (_currentStep == 0) _buildPersonalInfoForm(),
          if (_currentStep == 1) _buildLocationForm(),
        ],
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
              "Confirm Your Name",
              style: AppTheme.textTitle(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Full Name*',
                hintText: 'e.g. David Smith',
                counter: const SizedBox.shrink(),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                Expanded(
                  flex: 1,
                  child: OutlineButton(
                    text: 'Cancel',
                    disabled: _isLoading,
                    onPressed:
                        _isLoading
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
                    onPressed:
                        (_isFormValid && !_isLoading)
                            ? () {
                              if (_validateCurrentStep()) {
                                setState(() => _currentStep = 1);
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry.isEmpty ? null : _selectedCountry,
              decoration: InputDecoration(labelText: 'Country*'),
              items:
                  _isLoadingCountries
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
              validator:
                  (value) => value == null ? 'Please select a country' : null,
              icon: const Icon(Icons.arrow_drop_down_rounded),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedState.isEmpty ? null : _selectedState,
              decoration: InputDecoration(labelText: 'State*'),
              items:
                  _isLoadingStates
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
              onChanged:
                  _selectedCountry.isEmpty
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
              validator:
                  (value) => value == null ? 'Please select a state' : null,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity.isEmpty ? null : _selectedCity,
              decoration: InputDecoration(labelText: 'City*'),
              items:
                  _isLoadingCities
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
              onChanged:
                  _selectedState.isEmpty
                      ? null
                      : (String? newValue) {
                        setState(() {
                          _selectedCity = newValue ?? '';
                        });
                        _validateForm();
                      },
              validator:
                  (value) => value == null ? 'Please select a city' : null,
                  icon: const Icon(Icons.arrow_drop_down_rounded),
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
                    text: 'Register',
                    disabled: !_isFormValid || _isLoading,
                    onPressed:
                        (_isFormValid && !_isLoading)
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => OTPVerificationScreen(
                  phoneNumber: widget.phoneNumber,
                  countryCode: widget.countryCode ?? '',
                ),
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
