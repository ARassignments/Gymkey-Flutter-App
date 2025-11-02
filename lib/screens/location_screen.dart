import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../theme/theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isFormValid = false;
  bool _isLoading = false;
  bool get _isFormDisabled => _isLoading || !_isFormValid;

  String _selectedCountry = '';
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
    _fetchCountries();
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _validateForm() {
    final isValid = _formKey.currentState?.validate() ?? false;
    final allFieldsFilled = _selectedCountry.isNotEmpty &&
          _selectedState.isNotEmpty &&
          _selectedCity.isNotEmpty;

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
          _buildLocationForm(),
        ],
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
          ],
        ),
      ),
    );
  }

  Future<void> _submitCompleteForm() async {
    if (_selectedCountry.isEmpty ||
        _selectedState.isEmpty ||
        _selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Combine all form data
      final formData = {
        'country': _selectedCountry,
        'state': _selectedState,
        'city': _selectedCity,
      };

      // Call your API here
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successfull!')),
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
