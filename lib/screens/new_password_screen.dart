import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../theme/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isFormValid = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureCPassword = true;
  bool get _isFormDisabled => _isLoading || !_isFormValid;
  CountryCode _selectedCountryCode = CountryCode.fromCountryCode('IN');

  int _currentStep = 0; // 0 = personal info, 1 = location
  String _selectedCountry = ''; // Remove the nullable type and initialize
  String _selectedState = '';
  String _selectedCity = '';
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];
  bool _isLoadingCountries = true;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;

  // final Map<String, List<String>> _countryStates = {
  //   'India': ['Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu'],
  //   'USA': ['California', 'Texas', 'New York', 'Florida'],
  //   'UK': ['England', 'Scotland', 'Wales', 'Northern Ireland'],
  // };

  // final Map<String, List<String>> _stateCities = {
  //   'Maharashtra': ['Mumbai', 'Pune', 'Nagpur'],
  //   'Delhi': ['New Delhi', 'Noida', 'Gurgaon'],
  //   'Karnataka': ['Bangalore', 'Mysore', 'Hubli'],
  //   'California': ['Los Angeles', 'San Francisco', 'San Diego'],
  //   'Texas': ['Houston', 'Austin', 'Dallas'],
  //   'England': ['London', 'Manchester', 'Birmingham'],
  // };

  Future<void> _fetchCountries() async {
    final response = await http.get(
      Uri.parse('https://countriesnow.space/api/v0.1/countries/positions'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _countries = List<String>.from(data['data'].map((e) => e['name']));
        _isLoadingCountries = false;
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
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_formKey.currentState == null) {
        debugPrint('Warning: Form key not attached to any Form widget');
      }
    });

    // Existing listeners
    _nameController.addListener(_validateForm);
    _contactController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
    _fetchCountries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    final allFieldsFilled =
        _nameController.text.isNotEmpty &&
        _contactController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;

    setState(() {
      _isFormValid = isValid && allFieldsFilled;
    });

    return _isFormValid;
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
      onChanged:
          _validateForm, // This will trigger validation on any form change
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppTheme.appLogo(context), height: 100, width: 100),
            SizedBox(height: 40),
            Text("Register", style: AppTheme.textTitle(context)),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Full Name*',
                hintText: 'e.g. David Smith',
                // helperText: 'Enter Your Full Name',
                counter: const SizedBox.shrink(),
              ),
              style: AppInputDecoration.inputTextStyle(context),
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                } else if (value.length < 3) {
                  return 'Name must be at least 3 characters long';
                } else if (!RegExp(r'[A-Za-z]$').hasMatch(value)) {
                  return 'Name must contain only letters';
                }
                return null;
              },
              maxLength: 20,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CountryCodePicker(
                    onChanged: (country) {
                      setState(() {
                        _selectedCountryCode = country;
                      });
                    },
                    builder:
                        (country) => AppInputDecoration.buildCountryCodeButton(
                          context,
                          country,
                        ),
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    boxDecoration: AppTheme.dialogBg(context),
                    flagWidth: 30,
                    flagDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    searchStyle: AppInputDecoration.inputTextStyle(context),
                    textStyle: AppInputDecoration.inputTextStyle(context),
                    dialogTextStyle: AppInputDecoration.inputTextStyle(context),
                    dialogBackgroundColor: AppTheme.screenBg(context),
                    headerTextStyle: AppTheme.textTitle(context),
                    initialSelection: 'IN',
                    favorite: ['US', 'GB', 'IN'],
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    alignLeft: false,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: _contactController,
                    style: AppInputDecoration.inputTextStyle(context),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Contact No*',
                      hintText: 'e.g. 1234567890',
                      // helperText: 'Enter Your Valid Contact No',
                      counter: const SizedBox.shrink(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your contact number';
                      } else if (!RegExp(r'[0-9]$').hasMatch(value)) {
                        return 'Contact No must contain only digits';
                      } else if (value.length < 10) {
                        return 'Contact No must be at least 10 digits long';
                      }
                      return null;
                    },
                    maxLength: 15,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Email Address (Optional)',
                hintText: 'e.g. david@example.com',
                // helperText: 'Enter if you want to receive email notifications',
                counter: const SizedBox.shrink(),
              ),
              style: AppInputDecoration.inputTextStyle(context),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                }
                return null;
              },
              maxLength: 40,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Password*',
                hintText: 'e.g. pass*******',
                // helperText: 'Enter Your Valid Password',
                counter: const SizedBox.shrink(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  splashRadius: 20, // Smaller tap area
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              style: AppInputDecoration.inputTextStyle(context),
              keyboardType: TextInputType.visiblePassword,
              obscureText: _obscurePassword,
              obscuringCharacter: '•',
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
            SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Confirm Password*',
                hintText: 'e.g. pass*******',
                // helperText: 'Enter Your Valid Confirm Password',
                counter: const SizedBox.shrink(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  splashRadius: 20, // Smaller tap area
                  onPressed: () {
                    setState(() => _obscureCPassword = !_obscureCPassword);
                  },
                ),
              ),
              style: AppInputDecoration.inputTextStyle(context),
              keyboardType: TextInputType.visiblePassword,
              obscureText: _obscureCPassword,
              obscuringCharacter: '•',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                } else if (value.length < 8) {
                  return 'Confirm Password must be at least 8 characters long';
                } else if (value != _passwordController.text) {
                  return 'Confirm Passwords do not match';
                }
                return null;
              },
              maxLength: 20,
            ),
            SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: AppTheme.textLabel(context),
                children: [
                  TextSpan(text: 'By signing up, you agree to our '),
                  TextSpan(
                    text: 'Terms & Condition, ',
                    style: AppTheme.textLink(context),
                  ),
                  TextSpan(text: 'Data Policy ', style: AppTheme.textLink(context)),
                  TextSpan(text: 'and '),
                  TextSpan(text: 'Cookies Policy.', style: AppTheme.textLink(context)),
                ],
              ),
            ),
            SizedBox(height: 20),
            FlatButton(
              text: 'Continue',
              disabled: !_isFormValid || _isLoading,
              onPressed:
                  (_isFormValid && !_isLoading)
                      ? () {
                        if (_validateForm()) {
                          // Use the validation method
                          setState(() => _currentStep = 1);
                        }
                      }
                      : null,
              loading: _isLoading,
            ),
            SizedBox(height: 16),
            OutlineButton(
              text: 'Cancel',
              disabled: _isLoading,
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        // Navigator.pop(context);
                      },
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
            SizedBox(height: 40),
            Text("Where are you located?", style: AppTheme.textTitle(context)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCountry.isEmpty ? null : _selectedCountry,
              decoration: InputDecoration(labelText: 'Country*'),
              items:
                  _countries.map((String country) {
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
                if (_selectedCountry.isNotEmpty) {
                  _fetchStates(_selectedCountry);
                }
              },
              validator:
                  (value) => value == null ? 'Please select a country' : null,
            ),

            const SizedBox(height: 16),

            // State Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedState.isEmpty ? null : _selectedState,
              decoration: InputDecoration(labelText: 'State*'),
              items:
                  _states.map((String state) {
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
                        if (_selectedState.isNotEmpty) {
                          _fetchCities(_selectedCountry, _selectedState);
                        }
                      },
              validator:
                  (value) => value == null ? 'Please select a state' : null,
            ),

            const SizedBox(height: 16),

            // City Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCity.isEmpty ? null : _selectedCity,
              decoration: InputDecoration(labelText: 'City*'),
              items:
                  _cities.map((String city) {
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
                      },
              validator:
                  (value) => value == null ? 'Please select a city' : null,
            ),

            const SizedBox(height: 20),
            FlatButton(
              text: 'Complete Registration',
              disabled: !_isFormValid || _isLoading,
              onPressed:
                  (_isFormValid && !_isLoading)
                      ? () async {
                        if (!_validateForm()) return; // Use validation method
                        await _submitCompleteForm();
                      }
                      : null,
              loading: _isLoading,
            ),
            SizedBox(height: 16),
            OutlineButton(
              text: 'Back',
              disabled: _isLoading,
              onPressed: () {
                setState(() => _currentStep = 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitCompleteForm() async {
    if (_nameController.text.isEmpty ||
        _contactController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedCountry.isEmpty ||
        _selectedState.isEmpty ||
        _selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Combine all form data
      final formData = {
        'name': _nameController.text.trim(),
        'phone':
            '${_selectedCountryCode.dialCode ?? ''}${_contactController.text.trim()}',
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
      };

      // Call your API here
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
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
