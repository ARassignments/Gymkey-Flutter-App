import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/location_screen.dart';
import '../theme/theme.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResendLoading = false;
  int _resendTimeout = 30;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _resendTimeout > 0) {
        setState(() => _resendTimeout--);
        _startResendTimer();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  bool get _isOTPComplete {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  Future<void> _verifyOTP() async {
    if (!_isOTPComplete) return;
    setState(() => _isLoading = true);
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter complete OTP')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Call your OTP verification API here
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        // Navigate to home screen on success
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   PageRouteBuilder(
        //     pageBuilder: (_, __, ___) => LocationScreen(),
        //     transitionsBuilder:
        //         (_, a, __, c) => FadeTransition(opacity: a, child: c),
        //   ),
        //   (route) => false,
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

  Future<void> _resendOTP() async {
    setState(() {
      _isResendLoading = true;
      _resendTimeout = 30;
      for (int i = 0; i < _otpControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 50), () {
          if (mounted) {
            _otpControllers[i].clear();
            if (i == 0) _focusNodes[0].requestFocus();
          }
        });
      }
    });

    try {
      // Call your OTP resend API here
      await Future.delayed(const Duration(seconds: 1));
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New OTP sent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResendLoading = false);
      }
    }
  }

  void _handleOTPInput(String value, int index) {
    // Allow only numbers
    if (value.isNotEmpty && !RegExp(r'^[0-9]$').hasMatch(value)) {
      _otpControllers[index].text = '';
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {}); // Update button state
  }

  void _handleBackspace(String value, int index) {
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {}); // Update button state
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(30),
        children: [
          Image.asset(AppTheme.appLogo(context), height: 100, width: 100),
          const SizedBox(height: 40),
          Text(
            "Confirm Your Number",
            style: AppTheme.textTitle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTheme.textLabel(context),
              children: [
                TextSpan(text: "Enter the code we sent over SMS to "),
                TextSpan(
                  text: "${widget.countryCode} ${widget.phoneNumber}",
                  style: AppTheme.textLink(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // OTP Input Fields
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 45,
                child: TextFormField(
                  controller: _otpControllers[index],
                  focusNode: _focusNodes[index],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: AppInputDecoration.inputTextStyle(context),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(counter: const SizedBox.shrink()),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      _handleBackspace(value, index);
                    } else {
                      _handleOTPInput(value, index);
                    }
                  },
                  onEditingComplete: () {
                    if (index < 5 && _otpControllers[index].text.isNotEmpty) {
                      _focusNodes[index + 1].requestFocus();
                    }
                  },
                  onTap: () {
                    _otpControllers[index].selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _otpControllers[index].text.length,
                    );
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  textInputAction:
                      index == 5 ? TextInputAction.done : TextInputAction.next,
                  onFieldSubmitted: (value) {
                    if (index == 5 && _isOTPComplete) {
                      _verifyOTP();
                    }
                  },
                  enabled: !_isResendLoading,
                ),
              );
            }),
          ),
          const SizedBox(height: 30),

          FlatButton(
            text: 'Continue',
            disabled: !_isOTPComplete || _isLoading,
            onPressed: _isOTPComplete ? _verifyOTP : null,
            loading: _isLoading,
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Didn't get a code?", style: AppTheme.textLabel(context)),
              const SizedBox(width: 8),
              _resendTimeout > 0
                  ? Text(
                    "Resend in $_resendTimeout" "s",
                    style: AppTheme.textLink(context),
                  )
                  : TextButton(
                    onPressed: _isResendLoading ? null : _resendOTP,
                    child:
                        _isResendLoading
                            ? CircularProgressIndicator()
                            : Text(
                              "Resend Code",
                              style: AppTheme.textLink(context),
                            ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
