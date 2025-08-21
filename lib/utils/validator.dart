class Validator{

  static String validateEmail(String value) {
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp =  RegExp(pattern);
    if (value.isEmpty) {
      return "Email is Required";
    } else if (!regExp.hasMatch(value)) {
      return "Invalid Email ID";
    } else {
      return '';
    }
  }

  static String validateAccountNo(String value) {
    String pattern = r'(^[a-zA-Z0-9]*$)';
    RegExp regExp =  RegExp(pattern);
    if (value.isEmpty) {
      return "No is Required";
    } else if (!regExp.hasMatch(value)) {
      return "Please enter valid No";
    } else {
      return '';
    }
  }

  static String validatePassword(String value) {
    /*
    * r'^
  (?=.*[A-Z])       // should contain at least one upper case
  (?=.*[a-z])       // should contain at least one lower case
  (?=.*?[0-9])          // should contain at least one digit
 (?=.*?[!@#\$&*~]).{8,}  // should contain at least one Special character
$
* */

    //  Jan9ua@ry

    String pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regex =  RegExp(pattern);
    print(value);
    if (value.isEmpty) {
      return 'Please enter password';
    } else if (value.length < 7) {
      return "You need at least 8 charecter";
    } else {
      if (!regex.hasMatch(value)) {
        /*  showDialog(context: context,
            builder: (BuildContext context) =>
                CustomDialog("Check Net connected"));*/

       return 'Please enter valid password';
       // 'Password required \nAt least one upper case, \nAt least one lower case character, \nAt least one digit and \nAt least one Special character.\nEx.(Jan9ua@ry)';
      //  return null;
      }else {
        return '';
      }
    }
  }

  static String validateConfirmPassword(String value, String value2) {

    String pattern = r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$';
    RegExp regex =  RegExp(pattern);
    print(value);
    if (value.isEmpty) {
      return 'Enter confirm password';
    } else if (value.length < 7) {
      return "You need at least 8 charecter";
    } else if (!regex.hasMatch(value)) {
        return 'Enter valid confirm password';
        // 'Password required \nAt least one upper case, \nAt least one lower case character, \nAt least one digit and \nAt least one Special character.\nEx.(Jan9ua@ry)';

    }else if(value != value2){
      return 'Password and Confirm Password does not match';
    }else {
        return '';
      }
  }

  static String validateMobile(String value) {
    String patttern = r'(^[0-9]*$)';
    RegExp regExp =  RegExp(patttern);
    if (value.length == 0) {
      return "Phone Number required";
    } else if (value.length != 9) {
      return "Enter phone number";
    } else if (!regExp.hasMatch(value)) {
      return "Phone Number must be digits";
    }
    return '';
  }

  static String validateName(String value) {
    String patttern = r'(^[a-zA-Z 0-9.,_-]*$)';
    RegExp regExp =  RegExp(patttern);
    if (value.length <= 3) {
      return "Enter name";
    } else if (!regExp.hasMatch(value)) {
      return "Enter valid name";
    }
    return '';
  }

  static String validateMeetUpName(String value) {
    if (value.length <= 3) {
      return "Enter name";
    }
    return '';
  }

  static String validateDescription(String value) {
    if (value.length <= 3) {
      return "Enter Description";
    }
    return '';
  }



}