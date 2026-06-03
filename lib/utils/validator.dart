class Validator{

  static String? validateEmail(String? value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(pattern);
    if (value == null || value.isEmpty) {
      return "Please Enter Email ID";
    } else if (!regExp.hasMatch(value)) {
      return "Invalid Email ID";
    } else {
      return null;
    }
  }

  static String validateAccountNo(String value) {
    String pattern = r'(^[a-zA-Z0-9]*$)';
    RegExp regExp =  RegExp(pattern);
    if (value.isEmpty) {
      return "Please Enter Account No";
    } else if (!regExp.hasMatch(value)) {
      return "Please Enter Valid Account No";
    } else {
      return '';
    }
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please Enter Password';
    } else if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  static String validateConfirmPassword(String value, String value2) {

    String pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regex =  RegExp(pattern);
    print(value);
    if (value.isEmpty) {
      return 'Please Enter Confirm Password';
    } else if (value.length < 7) {
      return "Password must be at least 8 characters";
    } else if (!regex.hasMatch(value)) {
        return 'Please Enter Valid Confirm Password';
    }else if(value != value2){
      return 'Password and Confirm Password do not match';
    }else {
        return '';
      }
  }

  static String validateMobile(String value) {
    String patttern = r'(^[0-9]*$)';
    RegExp regExp =  RegExp(patttern);
    if (value.length == 0) {
      return "Please Enter Phone Number";
    } else if (value.length != 9) {
      return "Please Enter Valid Phone Number";
    } else if (!regExp.hasMatch(value)) {
      return "Phone Number must contain only digits";
    }
    return '';
  }

  static String validateName(String value) {
    String patttern = r'(^[a-zA-Z 0-9.,_-]*$)';
    RegExp regExp =  RegExp(patttern);
    if (value.length <= 3) {
      return "Please Enter Name";
    } else if (!regExp.hasMatch(value)) {
      return "Please Enter Valid Name";
    }
    return '';
  }

  static String validateMeetUpName(String value) {
    if (value.length <= 3) {
      return "Please Enter Name";
    }
    return '';
  }

  static String validateDescription(String value) {
    if (value.length <= 3) {
      return "Please Enter Description";
    }
    return '';
  }
}