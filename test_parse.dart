import 'dart:convert';
import 'lib/core/models/rst_failure_full_response.dart';
void main() {
  String jsonStr = '''
{
  \
success\: true,
  \message\: \Data
fetched
successfully\,
  \data\: {
    \notificationHistory\: {
      \historyId\: 193557,
      \description\: \asd\,
      \createdBy\: \Mr.Sanjay
Gomekar\,
      \createdOn\: \2026-06-07T13:12:00\
    },
    \rstFetchData\: {
      \notificationId\: 142319,
      \notificationCode\: \RST/07-2026/0006\,
      \description\: \asd\,
      \functionLocationId\: 322678,
      \deptId\: 3,
      \deptName\: \Rolling
Stock\,
      \equipmentId\: 0,
      \actualFailureOccuranceOn\: \06/07/2026
12:00\,
      \assignedUserId\: 1,
      \isPTWReq\: false,
      \ptwNo\: null,
      \isIntimationOfWorkReq\: false,
      \intimationWorkNo\: null,
      \isServiceAffected\: false,
      \trainDelayInNo\: null,
      \trainDelayInMin\: null,
      \noOfTranCancel\: null,
      \noOfTranWithdrawal\: null,
      \noOfTrainReplace\: null,
      \isPassengerDeboarding\: false,
      \noofTrainDeboarded\: null,
      \isPassengerAffected\: false,
      \noOfPassengerAffected\: null,
      \trappedDuration\: null,
      \rescuedDuration\: null,
      \isOHEReq\: true,
      \powerBlockRequired\: false,
      \isSICReq\: false,
      \assignUserId_SIC\: null,
      \isJointInspectionReq\: false,
      \deptId_JI\: null,
      \assignedUserId_JI\: null
    }
  }
}
  ''';
  var map = json.decode(jsonStr);
  try {
    var data = RstFetchData.fromJson(map['data']['rstFetchData']);
    print('Success');
  } catch (e, s) {
    print(e);
    print(s);
  }
}

