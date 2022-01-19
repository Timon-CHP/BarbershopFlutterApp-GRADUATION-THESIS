import 'package:flutter/material.dart';
import 'package:flutter_cahoi_barbershop/core/apis/auth_api.dart';
import 'package:flutter_cahoi_barbershop/service_locator.dart';
import 'package:flutter_cahoi_barbershop/ui/utils/constants.dart';
import 'package:flutter_cahoi_barbershop/ui/views/login/change_password_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class ForgotPasswordModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final phoneEditingController = TextEditingController();
  final _authAPI = locator<AuthAPI>();

  String currrentPhoneNumber = '';
  bool isValidatePhoneNumber = false;
  bool isSendOTP = false;
  String verificationId = '';

  String? validatePhoneNumber() {
    if (PhoneNumber.fromIsoCode(countryCode!, currrentPhoneNumber).validate()) {
      isValidatePhoneNumber = true;
      return null;
    } else {
      isValidatePhoneNumber = false;
      return 'Invalid phone number';
    }
  }

  void changeCurrentPhone() {
    currrentPhoneNumber = PhoneNumber.fromIsoCode(
            countryCode!, phoneEditingController.text.trim())
        .international;
    validatePhoneNumber();
    formKey.currentState?.validate();
    notifyListeners();
  }

  sendOTP() async {
    if (!PhoneNumber.fromIsoCode(countryCode!, currrentPhoneNumber)
        .validate()) {
      return;
    } else {
      bool isExitPassword = await _authAPI.checkUserExisis(currrentPhoneNumber);

      if (!isExitPassword) {
        Fluttertoast.showToast(msg: 'This user does not exist!');
        currrentPhoneNumber = '';
        phoneEditingController.text = '';
        notifyListeners();
        return;
      } else {
        _authAPI.verifyPhoneNumber(
            phoneNumber: currrentPhoneNumber,
            verificationCompleted: (phoneAuthCredential) async {
              // ANDROID ONLY!

              // Sign the user in (or link) with the auto-generated credential
              await _authAPI.firebaseAuth
                  .signInWithCredential(phoneAuthCredential);

              Navigator.of(scaffoldKey.currentContext!).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => ChangePasswordView(
                            phoneNumber: currrentPhoneNumber,
                          )),
                  (route) => route.isFirst);
            },
            verificationFailed: (error) {
              debugPrint(error.message);
            },
            codeSent: (verifiId, forceResendingToken) {
              verificationId = verifiId;
              isSendOTP = true;
              notifyListeners();
            },
            codeAutoRetrievalTimeout: (verificationId) {});
      }
    }
  }
}