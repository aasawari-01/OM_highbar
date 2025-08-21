import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../utils/size_config.dart';
import 'cust_text.dart';
import 'cust_textfield.dart';

class CustDateTimePicker extends StatelessWidget {
  final String label;
  final String hint;
  final DateTime? selectedDateTime;
  final ValueChanged<DateTime?> onDateTimeSelected;

  const CustDateTimePicker({
    Key? key,
    required this.label,
    required this.hint,
    this.selectedDateTime,
    required this.onDateTimeSelected,
  }) : super(key: key);

  Future<void> _pickDateTime(BuildContext context) async {
    DateTime tempDate = selectedDateTime ?? DateTime.now();
    int tempHour = selectedDateTime?.hour ?? TimeOfDay.now().hour;
    int tempMinute = selectedDateTime?.minute ?? TimeOfDay.now().minute;
    DateTime selectedDate = tempDate;
    int selectedHour = tempHour;
    int selectedMinute = tempMinute;
    bool isAm = selectedHour < 12;
    int displayHour12 = ((selectedHour % 12) == 0) ? 12 : (selectedHour % 12);

    final focusScopeNode = FocusScopeNode();

    // Create controllers outside of StatefulBuilder
    final hourController = TextEditingController(
      text: (((selectedHour % 12) == 0) ? 12 : (selectedHour % 12)).toString().padLeft(2, '0'),
    );
    final minuteController = TextEditingController(
      text: selectedMinute.toString().padLeft(2, '0'),
    );
    final ampmController = TextEditingController();
    DateTime? pickedDateTime = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final scrollController = ScrollController();
              final timeSectionKey = GlobalKey();
              ampmController.text= isAm ? 'AM' : 'PM';
              return FocusScope(
                node: focusScopeNode,
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
                      Navigator.pop(context, null);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 2 * SizeConfig.heightMultiplier),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: CustText(name: 'Select Date & Time', size: 1.8,fontWeightName: FontWeight.w500,),
                      ),
                      SizedBox(height: 1 * SizeConfig.heightMultiplier),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CalendarDatePicker(
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            onDateChanged: (date) {
                              setState(() {
                                selectedDate = date;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustText(name: 'Hour', size: 1.6, fontWeightName: FontWeight.w500),
                                    SizedBox(height: 1 * SizeConfig.heightMultiplier),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedHour = (selectedHour + 1) % 24;
                                          isAm = selectedHour < 12;
                                          hourController.text = (((selectedHour % 12) == 0) ? 12 : (selectedHour % 12)).toString().padLeft(2, '0');
                                        });
                                      },
                                      child: Icon(Icons.keyboard_arrow_up, size: 32, color: AppColors.textColor4),
                                    ),
                                    SizedBox(
                                      width: 48,
                                      child: TextField(
                                        controller: hourController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 2,
                                        onChanged: (val) {
                                          int? v = int.tryParse(val);
                                          if (v != null && v >= 1 && v <= 12) {
                                            selectedHour = isAm
                                                ? (v == 12 ? 0 : v)
                                                : (v == 12 ? 12 : v + 12);
                                          }
                                        },
                                        onSubmitted: (val) {
                                          int? v = int.tryParse(val);
                                          if (v != null && v >= 1 && v <= 12) {
                                            selectedHour = isAm
                                                ? (v == 12 ? 0 : v)
                                                : (v == 12 ? 12 : v + 12);
                                            hourController.text = val.padLeft(2, '0');
                                          } else {
                                            final fallback = (selectedHour % 12 == 0 ? 12 : selectedHour % 12);
                                            hourController.text = fallback.toString().padLeft(2, '0');
                                          }
                                        },
                                        maxLines: 1,
                                        decoration: InputDecoration(
                                          hintText: "hh",
                                          hintStyle: GoogleFonts.workSans(color: AppColors.textColor4, fontSize: 1.6 * SizeConfig.textMultiplier),
                                          filled: true,
                                          fillColor: Colors.white,
                                          counterText: "",
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 12.0,
                                          ),
                                        ),
                                        readOnly: false,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedHour = (selectedHour - 1 + 24) % 24;
                                          isAm = selectedHour < 12;
                                          hourController.text = (((selectedHour % 12) == 0) ? 12 : (selectedHour % 12)).toString().padLeft(2, '0');
                                        });
                                      },
                                      child: Icon(Icons.keyboard_arrow_down, size: 32, color: AppColors.textColor4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustText(name: 'Minute', size: 1.6, color: AppColors.textColor, fontWeightName: FontWeight.w500),
                                    SizedBox(height: 1 * SizeConfig.heightMultiplier),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedMinute = (selectedMinute + 1) % 60;
                                          minuteController.text = selectedMinute.toString().padLeft(2, '0');
                                        });
                                      },
                                      child: Icon(Icons.keyboard_arrow_up, size: 32, color: AppColors.textColor4),
                                    ),
                                    SizedBox(
                                      width: 48,
                                      child: TextField(
                                        controller: minuteController,
                                        keyboardType: TextInputType.number,
                                        maxLength: 2,
                                        onChanged: (val) {
                                          int? v = int.tryParse(val);
                                          if (v != null && v >= 0 && v <= 59) {
                                            selectedMinute = v;
                                            print("selectedMinute1====$selectedMinute");
                                          }
                                        },
                                        onSubmitted: (val) {
                                          int? v = int.tryParse(val);
                                          if (v != null && v >= 0 && v <= 59) {
                                            selectedMinute = v;
                                            minuteController.text = val.padLeft(2, '0');
                                            print("selectedMinute==$selectedMinute");
                                            print("minuteController==${minuteController.text}");
                                          } else {
                                            minuteController.text = selectedMinute.toString().padLeft(2, '0');
                                            print("minuteController==${minuteController.text}");

                                          }
                                        },
                                        maxLines: 1,
                                        decoration: InputDecoration(
                                          hintText: "mm",
                                          hintStyle: GoogleFonts.workSans(color: AppColors.textColor4, fontSize: 1.6 * SizeConfig.textMultiplier),
                                          filled: true,
                                          fillColor: Colors.white,
                                          counterText: "",
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 12.0,
                                          ),
                                        ),
                                        readOnly: false,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedMinute = (selectedMinute - 1 + 60) % 60;
                                          minuteController.text = selectedMinute.toString().padLeft(2, '0');
                                        });
                                      },
                                      child: Icon(Icons.keyboard_arrow_down, size: 32, color: AppColors.textColor4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustText(name: 'AM/PM', size: 1.6, color: AppColors.textColor, fontWeightName: FontWeight.w500),
                                    SizedBox(height: 1 * SizeConfig.heightMultiplier),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          print("isAm==$isAm");
                                          if (!isAm) {
                                            isAm = true;
                                          } else {
                                            isAm = false;
                                          }
                                          ampmController.text= isAm ? 'AM' : 'PM';
                                        });
                                      },
                                      child: Icon(Icons.keyboard_arrow_up, size: 32, color: AppColors.textColor4),
                                    ),
                                    SizedBox(
                                      width: 48,
                                      child: TextField(
                                        controller: ampmController,
                                        readOnly: true,
                                        maxLines: 1,
                                        decoration: InputDecoration(
                                          hintText: "",
                                          hintStyle: GoogleFonts.workSans(color: AppColors.textColor4, fontSize: 1.6 * SizeConfig.textMultiplier),
                                          filled: true,
                                          fillColor: Colors.white,
                                          counterText: "",
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          disabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(2.5 * SizeConfig.widthMultiplier),
                                            borderSide: BorderSide(color: AppColors.textFieldColor),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 12.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (!isAm) {
                                            isAm = true;
                                          } else {
                                            isAm = false;
                                          }
                                          ampmController.text= isAm ? 'AM' : 'PM';
                                        });
                                      },
                                      child: Icon(Icons.keyboard_arrow_down, size: 32, color: AppColors.textColor4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, null),
                              child: Text('Cancel'),
                            ),
                            SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                int hour12 = int.tryParse(hourController.text) ?? 12;
                                hour12 = hour12.clamp(1, 12);
                                selectedHour = isAm
                                    ? (hour12 == 12 ? 0 : hour12)
                                    : (hour12 == 12 ? 12 : hour12 + 12);
                                Navigator.pop(
                                  context,
                                  DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    selectedHour,
                                    selectedMinute,
                                  ),
                                );
                              },
                              child: Text('OK'),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (pickedDateTime != null) {
      onDateTimeSelected(pickedDateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayText = '';
    if (selectedDateTime != null) {
      final date = "${selectedDateTime!.year.toString().padLeft(4, '0')}-${selectedDateTime!.month.toString().padLeft(2, '0')}-${selectedDateTime!.day.toString().padLeft(2, '0')}";
      int hour = selectedDateTime!.hour;
      final ampm = hour < 12 ? 'AM' : 'PM';
      hour = hour % 12 == 0 ? 12 : hour % 12;
      final time = "${hour.toString().padLeft(2, '0')}:${selectedDateTime!.minute.toString().padLeft(2, '0')} $ampm";
      displayText = "$date $time";
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: label,
          size: 1.8,
          fontWeightName: FontWeight.w500,
        ),
        SizedBox(height: 1 * SizeConfig.heightMultiplier),
        InkWell(
          onTap: () => _pickDateTime(context),
          child: AbsorbPointer(
            child: CustomTextField(
              controller: TextEditingController(
                text: displayText,
              ),
              hintText: hint,
              suffixIcon: const Icon(TablerIcons.calendar,size: 24,color: AppColors.textColor4,),
            ),
          ),
        ),
      ],
    );
  }
}