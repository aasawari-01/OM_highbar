// const userRole = localStorage.getItem('userRole');
// const localStorages: any = localStorage.getItem('user');
// const userData = JSON.parse(localStorages);
// const token = userData?.result;
// const headers = { Authorization: `Bearer ${token}` };
//
// const users = [
// {
// email: 'guestUser@appcart.com',
// password: 'Password123',
// role: 'junior_engineer',
// },
// {
// email: 'je@appcart.com',
// password: 'Password123',
// role: 'junior_engineer',
// },
// {
// email: 'cc@appcart.com',
// password: 'Password123',
// role: 'chief_controller',
// },
// {
// email: 'tc@appcart.com',
// password: 'Password123',
// role: 'traffic_controller',
// },
// ];
//
// const categories = [
// 'ATS HMI',
// 'CCTV Work Station',
// 'PIDS',
// 'PAS',
// 'PIDS/PAS Work Station',
// 'Tetra',
// 'Radio Control Panel',
// 'IP Phone',
// 'DLT Phone',
// 'BSNL',
// 'BMS Work Station',
// 'FACP',
// 'Lift',
// 'Escalator',
// 'Passenger Help Point',
// 'Lift InterCom',
// 'Tom',
// 'EFO',
// 'AFC Gate',
// 'Station Computer',
// 'TVM Equipemnt',
// 'ESP',
// 'MCP',
// 'Baggage Scanner',
// 'DFMD',
// 'HHMD',
// ];
//
// const dataList = categories.map((category, index) => ({
// srNo: { value: index + 1, styleClass: '' },
// category: { value: category, styleClass: '' },
// workStatus: { value: 1, styleClass: '' },
// remark: { value: '', styleClass: '' },
// }));
//
// const departmentList = [
// { id: 10, value: 'Signalling' },
// { id: 20, value: 'Telecom' },
// { id: 30, value: 'Rolling Stock' },
// { id: 40, value: 'Electrical and Mechanical' },
// { id: 50, value: 'Lift and Escalator' },
// { id: 60, value: 'Track' },
// { id: 70, value: 'Information Technology' },
// { id: 80, value: 'Civil' },
// { id: 90, value: 'Overhead Equipment' },
// { id: 100, value: 'Power Supply' },
// { id: 110, value: 'Human Resources' },
// { id: 120, value: 'Operation Chief Controller' },
// { id: 130, value: 'Security Surveillance System' },
// { id: 140, value: 'Depot Equipment' },
// { id: 150, value: 'Finance' },
// { id: 160, value: 'AFC' },
// { id: 170, value: 'Station Operation' },
// { id: 180, value: 'Crew Management System' },
// { id: 190, value: 'Finance' },
// { id: 200, value: 'Safety' },
// { id: 210, value: 'Solar' },
// { id: 220, value: 'Customer Relationship Management' },
// ];
//
// const departmentListValue = departmentList.map((departmentListData) => ({
// name: departmentListData.value,
// }));
//
// const directionList = [
// { id: 1, value: 'Up Line' },
// { id: 2, value: 'Down Line' },
// ];
// const directionListValue = directionList.map((directionListData) => ({
// name: directionListData.value,
// }));
// const stationList = [
// { id: 1, value: 'Khapri' },
// { id: 2, value: 'New Airport' },
// { id: 3, value: 'Airport South' },
// { id: 4, value: 'Airport' },
// { id: 5, value: 'Ujjwal Nagar' },
// { id: 6, value: 'Jaiprakash Nagar' },
// { id: 7, value: 'Chhatrapati Square' },
// { id: 8, value: 'Ajni Square' },
// { id: 9, value: 'Ajni Square' },
// { id: 10, value: 'Rancha Colony' },
// { id: 11, value: 'Congress Nagar' },
// { id: 12, value: 'Sita Buldi' },
// { id: 13, value: 'Chhatrapati Square' },
// { id: 14, value: 'Ajni Square' },
// { id: 15, value: 'Airport South' },
// { id: 16, value: 'Chhatrapati Square' },
// { id: 17, value: 'Airport South' },
// { id: 18, value: 'Rancha Colony' },
// ];
// const stationListValue = stationList.map((stationListData) => ({
// name: stationListData.value,
// }));
//
// const temporarySpeedRestrictionList = [
// { id: 1, value: '5' },
// { id: 2, value: '6' },
// { id: 3, value: '7' },
// { id: 4, value: '8' },
// { id: 5, value: '9' },
// { id: 6, value: '10' },
// { id: 7, value: '11' },
// { id: 8, value: '12' },
// { id: 9, value: '13' },
// { id: 10, value: '14' },
// { id: 11, value: '15' },
// { id: 12, value: '16' },
// { id: 13, value: '17' },
// { id: 14, value: '18' },
// { id: 15, value: '19' },
// { id: 16, value: '20' },
// { id: 17, value: '21' },
// { id: 18, value: '22' },
// { id: 19, value: '23' },
// { id: 20, value: '24' },
// { id: 21, value: '25' },
// { id: 22, value: '26' },
// { id: 23, value: '27' },
// ];
// const temporarySpeedRestrictionListValue = temporarySpeedRestrictionList.map(
// (temporarySpeedRestrictionListData) => ({
// name: temporarySpeedRestrictionListData.value,
// })
// );
//
// const priorityList = [
// { id: 1, value: 'Low' },
// { id: 2, value: 'Medium' },
// { id: 3, value: 'High' },
// { id: 4, value: 'Very High' },
// ];
//
// const priorityListValue = priorityList.map((priorityListData) => ({
// name: priorityListData.value,
// }));
//
// const feedbackTypesList = [
// { id: 1, value: 'Complaints' },
// { id: 2, value: 'Suggestions' },
// { id: 3, value: 'Appreciation' },
// { id: 4, value: 'Neutral' },
// { id: 5, value: 'Enquiry' },
// ];
// const feedbackTypesListValue = feedbackTypesList.map(
// (feedbackTypesListData) => ({
// name: feedbackTypesListData.value,
// })
// );
// const complaintTypesList = [
// { id: 1, value: 'Staff Complaints' },
// { id: 2, value: 'Security/Safety' },
// { id: 3, value: 'Ticket/Revenue' },
// { id: 4, value: 'MMI/PD' },
// { id: 5, value: 'Train Operation' },
// { id: 6, value: 'E&M' },
// { id: 7, value: 'Rolling Stock' },
// { id: 8, value: 'Telecom' },
// { id: 9, value: 'Civil' },
// { id: 10, value: 'Station Operations' },
// { id: 11, value: 'Information Technology' },
// { id: 12, value: 'Miscellaneous' },
// ];
// const complaintTypesListValue = complaintTypesList.map(
// (complaintTypesListData) => ({
// name: complaintTypesListData.value,
// })
// );
// const sourceList = [
// { id: 1, value: 'Email' },
// { id: 2, value: 'Phone' },
// { id: 3, value: 'SMS' },
// { id: 4, value: 'Personal Visit' },
// { id: 5, value: 'Dropbox' },
// { id: 6, value: 'QR' },
// ];
// const sourceListValue = sourceList.map((sourceListData) => ({
// name: sourceListData.value,
// }));
//
// const yesNoList = [
// { id: 1, value: 'Yes' },
// { id: 2, value: 'No' },
// ];
// const yesNoListValue = yesNoList.map((yesNoListData) => ({
// name: yesNoListData.value,
// }));
// const lineList = [
// { id: 1, value: 'Line 1' },
// { id: 2, value: 'Line 2' },
// { id: 3, value: 'Line 3' },
// ];
// const lineListValue = lineList.map((lineListData) => ({
// name: lineListData.value,
// }));
//
// const failureReportedByList = [
// { id: 1, value: 'Ravi_Kumar_93' },
// { id: 2, value: 'Neha_Sharma_88' },
// { id: 3, value: 'Amit_Verma_75' },
// { id: 4, value: 'Pooja_Mehta_66' },
// { id: 5, value: 'Suresh_Singh_54' },
// ];
//
// const failureReportedByListValue = failureReportedByList.map(
// (failureReportedByListData) => ({
// name: failureReportedByListData.value,
// })
// );
//
// const activityList = [
// { id: 1, value: 'Activity 1' },
// { id: 2, value: 'Activity 2' },
// { id: 3, value: 'Activity 3' },
// ];
//
// const activityListValue = activityList.map((activityListData) => ({
// name: activityListData.value,
// }));
//
// const subActivityList = [
// { id: 1, value: 'Sub Activity 1' },
// { id: 2, value: 'Sub Activity 2' },
// { id: 3, value: 'Sub Activity 3' },
// ];
//
// const subActivityListValue = subActivityList.map((subActivityListData) => ({
// name: subActivityListData.value,
// }));
//
// const assignUserList = [
// { id: 1, value: 'manoj_Kumar_63' },
// { id: 1, value: 'ashok_varma_13' },
// { id: 1, value: 'Ravi_Kumar_93' },
// { id: 2, value: 'Neha_Sharma_88' },
// { id: 3, value: 'Amit_Verma_75' },
// { id: 4, value: 'Pooja_Mehta_66' },
// { id: 5, value: 'Suresh_Singh_54' },
// ];
//
// const assignUserListValue = assignUserList.map((assignUserData) => ({
// name: assignUserData.value,
// }));
//
// const phaseList = [
// { id: 1, value: 'Before' },
// { id: 2, value: 'After' },
// ];
//
// const phaseListValue = phaseList.map((phaseListData) => ({
// name: phaseListData.value,
// }));
//
// const checklistList = [
// { id: 1, value: 'Checklist 1' },
// { id: 2, value: 'Checklist 2' },
// { id: 3, value: 'Checklist 3' },
// ];
//
// const checklistListValue = checklistList.map((checklistListData) => ({
// name: checklistListData.value,
// }));
//
// const tripOperatorList = [
// { id: 1, value: 'Ramesh Kumar' },
// { id: 2, value: 'Suman Verma' },
// { id: 3, value: 'Anil Singh' },
// { id: 4, value: 'Priya Mehta' },
// { id: 5, value: 'Vikram Joshi' },
// ];
//
// const tripOperatorListValue = tripOperatorList.map((tripOperatorListData) => ({
// name: tripOperatorListData.value,
// }));
//
// const trainSetList = [
// { id: 2, value: 'Train Set 1' },
// { id: 3, value: 'Train Set 2' },
// ];
//
// const trainSetListValue = trainSetList.map((trainSetListData) => ({
// name: trainSetListData.value,
// }));
// const genderList = [
// { id: 2, value: 'Male' },
// { id: 3, value: 'Female' },
// ];
//
// const genderListValue = genderList.map((genderListData) => ({
// name: genderListData.value,
// }));
//
// const equipmentNumberList = [
// { id: 1, value: 'Equipment 1' },
// { id: 2, value: 'Equipment 2' },
// { id: 3, value: 'Equipment 3' },
// { id: 4, value: 'Equipment 4' },
// { id: 5, value: 'Equipment 5' },
// ];
// const equipmentNumberListValue = equipmentNumberList.map(
// (equipmentNumberListData) => ({
// name: equipmentNumberListData.value,
// })
// );
//
//
// const dutyShiftList: any[] = [
// // { id: 2, value: 'Male' },
// // { id: 3, value: 'Female' },
// ];
//
// const dutyShiftListValue = dutyShiftList.map((dutyShift) => ({
// name: dutyShift.value,
// }));
//
// const staffCategoryList: any[] = [
// { id: 1, value: 'House Keeping' },
// { id: 2, value: 'Security' },
// { id: 3, value: 'TOM' }, // Ticket Office Machine operator
//     { id: 4, value: 'CFA' }, // Customer Facilitation Agent (if applicable)
//     { id: 5, value: 'Others' },
// { id: 6, value: 'Supervisors' }
// ];
//
// const stockCategoryListValue = staffCategoryList.map((staffCategory) => ({
// name: staffCategory.value,
// }));
//
// const stockCategoryList: any[] = [];
// const staffCategoryListValue = stockCategoryList.map((staffCategory) => ({
// name: staffCategory.value,
// }));
//
// const eventTypeList: any[] = [];
// const eventTypeListValue = eventTypeList.map((eventType) => ({
// name: eventType.value,
// }));
// const ptwList: any[] = [];
// const ptwListValue = ptwList.map((ptw) => ({
// name: ptw.value,
// }));
//
//
// const crewManagementList = [
// { id: 1, value: 'General Inspection' },
// ];
// const crewManagementListValue = crewManagementList.map((crewManagement) => ({
// name: crewManagement.value,
// }));
//
// const occInspectionTypeList = [
// { id: 1, value: 'General Inspection' },
// ];
// const occInspectionTypeListValue = occInspectionTypeList.map((occInspectionType) => ({
// name: occInspectionType.value,
// }));
//
// const hrInspectionTypeList = [
// { id: 1, value: 'General Inspection' },
// ];
// const hrInspectionTypeListValue = hrInspectionTypeList.map((hrInspectionType) => ({
// name: hrInspectionType.value,
// }));
//
// const itInspectionTypeList = [
// { id: 1, value: 'General Inspection' },
// ];
// const itInspectionTypeListValue = itInspectionTypeList.map((itInspectionType) => ({
// name: itInspectionType.value,
// }));
//
// const civilInspectionTypeList = [
// { id: 1, value: 'General Inspection' },
// { id: 2, value: 'Detailed Station Inspection' },
// { id: 3, value: 'Inspection of Gaddigodaam OWG Bridge' },
// { id: 4, value: 'Routine Station Inspection' },
// { id: 5, value: 'Routine Inspection of Viaduct' },
// { id: 6, value: 'Detailed Inspection of Structural Steelworks of Station' },
// { id: 7, value: 'Detailed Inspection of Structural Steel Bridge' },
// { id: 8, value: 'Routine Inspection of Structural Steelworks of Station' },
// { id: 9, value: 'Routine Inspection of Structural Steel Bridge' },
// { id: 10, value: 'Detailed Depot Inspection Report' },
// { id: 11, value: 'Routine Depot Inspection Report' },
// { id: 12, value: 'Routine Premonsoon Test' },
// { id: 13, value: 'Inspection of Structural Steel View Cutter' },
// { id: 14, value: 'Inspection of Structural Signal Post Platform' },
// { id: 15, value: 'Inspection Details of POT PTFE/ Spherical Bearing' },
// { id: 16, value: 'Special Inspection of Viaduct' },
// { id: 17, value: 'Inspection Details of Elastomeric Bearing' },
// { id: 18, value: 'Detailed Inspection of Viaduct' }
// ];
// const civilInspectionTypeListValue = civilInspectionTypeList.map((civilInspectionType) => ({
// name: civilInspectionType.value,
// }));
//
// const trackInspectionTypeList = [
// { id: 1, value: 'Curve Inspection' },
// { id: 2, value: 'General Inspection' },
// { id: 3, value: 'Creep Measurement' },
// { id: 4, value: 'Temperature Monitoring' },
// { id: 5, value: 'OMS' },
// { id: 6, value: 'Pilot Train Inspection' },
// { id: 7, value: 'Cab Inspection' },
// { id: 8, value: 'Foot Ins' },
// { id: 9, value: 'Toe Load' },
// { id: 10, value: 'Turn Out' },
// { id: 11, value: 'Buffer Stop' },
// { id: 12, value: 'Ultrasonic Flaw Detection (USFD)' },
// { id: 13, value: 'Inspection of Floating Track - Slab with Spring' },
// { id: 14, value: 'Scissor Crossover Inspection' },
// { id: 15, value: 'AT Weld Inspection' }
// ];
// const trackInspectionTypeListValue = trackInspectionTypeList.map((trackInspectionType) => ({
// name: trackInspectionType.value,
// }));
//
//
// const rollingStockInspectionTypeList = [
// { id: 1, value: 'General Inspection' },
// ];
// const rollingStockInspectionTypeListValue = rollingStockInspectionTypeList.map((rollingStockInspectionType) => ({
// name: rollingStockInspectionType.value,
// }));
// const signalingInspectionTypeList = [
// { id: 1, value: 'Foot Plate' },
// { id: 2, value: 'On-board' },
// { id: 3, value: 'Stations-SE' },
// { id: 4, value: 'Wayside' },
// { id: 5, value: 'OCC/BOCC' },
// { id: 6, value: 'General Inspection' },
// { id: 7, value: 'Stations-JE' },
// ];
// const signalingInspectionTypeListValue = signalingInspectionTypeList.map((signalingInspectionType) => ({
// name: signalingInspectionType.value,
// }));
//
// const range = (size: number) => {
// return Array.from({ length: size }, (_, i) => i + 1);
// };
//
// const parseJwt = (token: any) => {
// var base64Url = token?.split('.')[1];
// var base64 = base64Url?.replace(/-/g, '+').replace(/_/g, '/');
// var jsonPayload = decodeURIComponent(
// window
//     .atob(base64)
//     .split('')
//     .map(function (c) {
// return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
// })
//     .join('')
// );
//
// return JSON.parse(jsonPayload);
// };
//
// const frequency = [
// { id: 1, name: 'Daily' },
// { id: 2, name: 'Weekly' },
// { id: 3, name: 'Monthly' },
// { id: 4, name: 'Quarterly' },
// { id: 5, name: 'Six Month' },
// { id: 6, name: 'Yearly' },
// ];
//
// const titleList = [
// { code: 1, name: 'Mr' },
// { code: 2, name: 'Mrs' },
// { code: 3, name: 'Miss' },
// { code: 4, name: 'Ms' },
// { code: 5, name: 'Dr' },
// { code: 6, name: 'Prof' },
// { code: 7, name: 'Rev' },
// { code: 8, name: 'Sir' },
// ];
//
// const dateFormat = (date: any) => {
// return new Intl.DateTimeFormat('en-GB', {
// day: '2-digit',
// month: '2-digit',
// year: 'numeric',
// }).format(date);
// };
//
// const formatDate = (date: any): string => {
// const validDate = new Date(date);
// if (isNaN(validDate.getTime())) {
// // Handle invalid date cases (if the date cannot be parsed)
// return 'Invalid date';
// }
// const day = String(validDate.getDate()).padStart(2, '0'); // Use validDate here
// const month = String(validDate.getMonth() + 1).padStart(2, '0'); // Months are 0-indexed
// const year = validDate.getFullYear(); // Use validDate here
// return `${day}/${month}/${year}`;
// };
//
// function calculateDateDifference(
// startDate: string,
// endDate: string,
// unit: 'days' | 'months' | 'years' = 'days'
// ): number {
// // Helper function to parse dd/mm/yy into a Date object
// function parseDate(dateStr: string): Date {
// const [day, month, year] = dateStr.split('/').map(Number);
// if (!day || !month || !year) {
// throw new Error(
// `Invalid date format: ${dateStr}. Expected format is dd/mm/yy.`
// );
// }
//
// // Handle two-digit year (e.g., 24 becomes 2024)
// const fullYear = year < 100 ? 2000 + year : year;
//
// return new Date(fullYear, month - 1, day); // Month is 0-based in JavaScript
// }
//
// const start = parseDate(startDate);
// const end = parseDate(endDate);
//
// if (isNaN(start.getTime()) || isNaN(end.getTime())) {
// throw new Error('Invalid date provided');
// }
//
// end.setHours(23, 59, 59, 999);
//
// const diffInMilliseconds = end.getTime() - start.getTime();
//
// switch (unit) {
// case 'days':
// return Math.floor(diffInMilliseconds / (1000 * 60 * 60 * 24)) + 1;
// case 'months':
// return (
// (end.getFullYear() - start.getFullYear()) * 12 +
// (end.getMonth() - start.getMonth())
// );
// case 'years':
// return end.getFullYear() - start.getFullYear();
// default:
// throw new Error("Invalid unit. Use 'days', 'months', or 'years'.");
// }
// }
//
// function formatNotificationDate(dateString: string | number | Date) {
// const date = new Date(dateString);
//
// // Extract time part (e.g., 10:41 AM)
// const time = date.toLocaleTimeString('en-US', {
// hour: 'numeric',
// minute: 'numeric',
// hour12: true,
// });
//
// // Extract date part (e.g., August 7, 2021)
// const formattedDate = date.toLocaleDateString('en-US', {
// month: 'long',
// day: 'numeric',
// year: 'numeric',
// });
//
// return `${time} ${formattedDate}`;
// }
//
// function timeAgo(dateString: any) {
// const now: any = new Date();
// const date: any = new Date(dateString);
//
// // Get the difference in milliseconds
// const diffInMs = now - date;
//
// // Convert the difference to seconds, minutes, hours, and days
// const diffInSecs = Math.floor(diffInMs / 1000);
// const diffInMins = Math.floor(diffInSecs / 60);
// const diffInHours = Math.floor(diffInMins / 60);
// const diffInDays = Math.floor(diffInHours / 24);
//
// if (diffInMins < 1) {
// return `${diffInSecs} sec`;
// } else if (diffInMins < 60) {
// return `${diffInMins} min${diffInMins !== 1 ? 's' : ''}`;
// } else if (diffInHours < 24) {
// return `${diffInHours} hr${diffInHours !== 1 ? 's' : ''}`;
// } else {
// return `${diffInDays} day${diffInDays !== 1 ? 's' : ''} ago`;
// }
// }
//
// function formatAmount(amount: any) {
// if (amount >= 10000000) {
// return '₹ ' + (amount / 10000000).toFixed(1) + ' Cr';
// } else if (amount >= 100000) {
// return '₹ ' + (amount / 100000).toFixed(1) + ' L';
// } else {
// return (
// new Intl.NumberFormat('en-IN', {
// style: 'currency',
// currency: 'INR',
// }).format(amount) + ' /-'
// );
// }
// }
//
// function eachFirstLetterCapital(str: any) {
// return str
//     .toLowerCase()
//     .split(' ')
//     .map((word: string) => word.charAt(0).toUpperCase() + word.slice(1))
//     .join(' ');
// }
// export {
// departmentListValue,
// directionListValue,
// stationListValue,
// temporarySpeedRestrictionListValue,
// feedbackTypesListValue,
// complaintTypesListValue,
// priorityListValue,
// sourceListValue,
// yesNoListValue,
// lineListValue,
// failureReportedByListValue,
// activityListValue,
// subActivityListValue,
// assignUserListValue,
// phaseListValue,
// checklistListValue,
// tripOperatorListValue,
// trainSetListValue,
// equipmentNumberListValue,
// genderListValue,
// userRole,
// users,
// dataList,
// token,
// range,
// parseJwt,
// headers,
// frequency,
// titleList,
// dateFormat,
// formatDate,
// calculateDateDifference,
// formatNotificationDate,
// timeAgo,
// formatAmount,
// eachFirstLetterCapital,
// dutyShiftListValue,
// stockCategoryListValue,
// staffCategoryListValue,
// eventTypeListValue,
// ptwListValue
// };
