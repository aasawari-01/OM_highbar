import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:om_mobile/constants/colors.dart';
import 'package:om_mobile/constants/app_data.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/cust_button.dart';
import 'package:om_mobile/widgets/cust_date_picker.dart';
import 'package:om_mobile/widgets/cust_dropdown.dart';
import 'package:om_mobile/widgets/cust_radio.dart';
import 'package:om_mobile/widgets/cust_text.dart';
import 'package:om_mobile/widgets/cust_textfield.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'package:flutter_stepindicator/flutter_stepindicator.dart';

class ShiftAbstractRegisterForm extends StatefulWidget {
  const ShiftAbstractRegisterForm({Key? key}) : super(key: key);

  @override
  State<ShiftAbstractRegisterForm> createState() => _ShiftAbstractRegisterFormState();
}

class _ShiftAbstractRegisterFormState extends State<ShiftAbstractRegisterForm> {
  DateTime? _selectedDate;
  String? _selectedCreatedFor;
  String? _selectedStationName = stationListValue.isNotEmpty ? stationListValue[0] : null;
  String? _selectedMonth = monthsList[DateTime.now().month - 1];
  String? _selectedYear = DateTime.now().year.toString();
  final TextEditingController _tomEfoNoController = TextEditingController();
  final TextEditingController _shiftNoController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  TimeOfDay? _dutyFromTime;
  TimeOfDay? _dutyToTime;
  String? _selectedPrivateCash;
  final TextEditingController _imprestGivenController = TextEditingController();
  // Summary of Notes
  String? _selectedDenomination;
  final TextEditingController _notesNoController = TextEditingController();
  final TextEditingController _notesAmountController = TextEditingController();
  String? _selectedNoteType;
  // Summary of Sales
  String? _selectedParticulars;
  final TextEditingController _salesQuantityController = TextEditingController();
  final TextEditingController _salesAmountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();

  int _currentStep = 0;
  final List<String> _stepTitles = [
    "Shift Details",
    "Summary of Notes",
    "Summary of Sales",
    "Remark"
  ];

  final List<String> createdForList = ["TOM", "EFO"];
  final List<String> privateCashList = ["Yes", "No"];
  static const List<String> monthsList = [
    "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
  ];
  final List<String> yearsList = List.generate(10, (i) => (DateTime.now().year - 5 + i).toString());
  final List<String> denominationsList = ["01", "02", "05", "10", "20", "100"];
  final List<String> noteTypeList = ["Cash", "QR", "CARD"];
  final List<String> particularsList = [
    "QR Ticket",
    "EMV CardSales",
    "FREE EXIT",
    "EMV EXIT",
    "OUTSTANDING MISC GENERATED",
    "OUTSTANDING AFC-QR PAID",
    "OUTSTANDING MISC PAID",
    "OUTSTANDING AFC-QR GENERATED",
    "QR NON CASH",
    "QR CASH DEPOSITED",
    "OUTSTANDING AFC-ONE PUNE CARD PAID",
    "ONE PUNE CARD NON CASH",
    "OUTSTANDING AFC-ONE PUNE CARD GENERATED",
    "ONE PUNE CARD CASH DEPOSITED",
    "PENALTY",
    "EXCESS AMOUNT",
    "DAILY PASS",
    "Paid Exit",
    "Surcharge"
  ];

  List<Widget> get _steps => [
    _buildShiftDetailsStep(),
    _buildSummaryOfNotesStep(),
    _buildSummaryOfSalesStep(),
    _buildReviewStep()
  ];

  @override
  void dispose() {
    _tomEfoNoController.dispose();
    _shiftNoController.dispose();
    _imprestGivenController.dispose();
    _notesNoController.dispose();
    _notesAmountController.dispose();
    _salesQuantityController.dispose();
    _salesAmountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: "Shift Abstract Register Form"),
      backgroundColor: AppColors.bgColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1 * SizeConfig.heightMultiplier,),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: FlutterStepIndicator(
              height: 20,
              list: List.generate(_steps.length, (index) => index),
              page: _currentStep,
              division: _steps.length,
              positiveColor: AppColors.gradientStart,
              negativeColor: AppColors.textColor4,
              progressColor: AppColors.gradientStart,
              onChange: (i) {},
            ),
          ),
          SizedBox(height: 1 * SizeConfig.heightMultiplier,),
          Expanded(
            child: _steps[_currentStep],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  CustOutlineButton(
                    name: 'Back',
                    size: 30,
                    onSelected: (_) => setState(() => _currentStep--),
                  ),
                if (_currentStep < _steps.length - 1)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: CustButton(
                        name: 'Next',
                        size: 30,
                        onSelected: (_) => setState(() => _currentStep++),
                      ),
                    ),
                  ),
                if (_currentStep == _steps.length - 1)
                  CustButton(
                    name: 'Submit',
                    size: 30,
                    onSelected: (_) {
                      // TODO: Implement submit logic
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustDatePicker(
              label: 'Date *',
              hint: 'DD/MM/YYYY',
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  // Automatically set month and year based on selected date
                  if (date != null) {
                    _selectedMonth = monthsList[date.month - 1];
                    _selectedYear = date.year.toString();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Created for *',
              hint: 'Select Created for',
              items: createdForList,
              selectedValue: _selectedCreatedFor,
              onChanged: (value) {
                setState(() {
                  _selectedCreatedFor = value;
                });
              },
            ),
            const SizedBox(height: 16),
            CustDropdown(
              label: 'Station Name *',
              hint: 'Station Name',
              items: stationListValue,
              selectedValue: _selectedStationName,
              onChanged: (value) {}, // No-op function
              // Disabled
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Month *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller:monthController,
              hintText: 'Month',
              fillColor: AppColors.textFieldColor,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Year *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller:yearController,
              hintText: 'Year',
              fillColor: AppColors.textFieldColor,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'TOM/EFO No *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _tomEfoNoController,
              hintText: 'Enter TOM/EFO No',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Shift No *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _shiftNoController,
              hintText: 'Enter Shift No',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Duty Performed From (Hrs)*',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _dutyFromTime ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() {
                    _dutyFromTime = picked;
                  });
                }
              },
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: TextEditingController(
                    text: _dutyFromTime != null ? _dutyFromTime!.format(context) : '',
                  ),
                  hintText: 'HH:mm',
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Duty Performed To (Hrs)*',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _dutyToTime ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  setState(() {
                    _dutyToTime = picked;
                  });
                }
              },
              child: AbsorbPointer(
                child: CustomTextField(
                  controller: TextEditingController(
                    text: _dutyToTime != null ? _dutyToTime!.format(context) : '',
                  ),
                  hintText:'HH:mm',
                  readOnly: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Private Cash *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            Row(
              children: privateCashList.map((option) => Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CustRadio<String>(
                  value: option,
                  groupValue: _selectedPrivateCash ?? '',
                  label: option,
                  onChanged: (value) {
                    setState(() {
                      _selectedPrivateCash = value;
                    });
                  },
                ),
              )).toList(),
            ),
            const SizedBox(height: 16),
            CustText(
              name: 'Imprest given to Operator Counter (in Rs.) *',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _imprestGivenController,
              hintText: 'Enter Amount',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryOfNotesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: SizedBox(
          width: 50 * SizeConfig.widthMultiplier,
          child: CustButton(
            name: 'Add Notes Details',
            size: 140,
            onSelected: (p0) {
              showDialog(
                context: context,
                builder: (context) => AddNotesDetailsDialog(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryOfSalesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: SizedBox(
          width: 50 * SizeConfig.widthMultiplier,
          child: CustButton(
            name: 'Add Sales Details',
            size: 140,
            onSelected: (p0) {
              showDialog(
                context: context,
                builder: (context) => AddSalesDetailsDialog(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: AccordionCard(
        expanded: true,
        onTap: () {},
        isExpanded: false,
        title: _stepTitles[_currentStep],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustText(
              name: 'Remark * (Max 500 Characters)',
              size: 1.8,
              fontWeightName: FontWeight.w500,
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: _remarkController,
              hintText: 'Enter Remark',
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

}

class AddNotesDetailsDialog extends StatefulWidget {
  @override
  State<AddNotesDetailsDialog> createState() => _AddNotesDetailsDialogState();
}

class _AddNotesDetailsDialogState extends State<AddNotesDetailsDialog> {
  String? _selectedDenomination;
  String? _selectedNoteType;
  final TextEditingController _notesNoController = TextEditingController();
  final TextEditingController _notesAmountController = TextEditingController();

  final List<String> denominationsList = ["01", "02", "05", "10", "20", "100"];
  final List<String> noteTypeList = ["Cash", "QR", "CARD"];

  @override
  void dispose() {
    _notesNoController.dispose();
    _notesAmountController.dispose();
    super.dispose();
  }

  void _calculateAmount() {
    if (_selectedNoteType == "Cash" && _selectedDenomination != null && _notesNoController.text.isNotEmpty) {
      final denomination = double.tryParse(_selectedDenomination!) ?? 0;
      final no = double.tryParse(_notesNoController.text) ?? 0;
      final amount = denomination * no;
      _notesAmountController.text = amount.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 15, bottom: 10, right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: CustText(
              name: "Add Notes Details",
              size: 1.8,
              color: AppColors.textColor3,
              fontWeightName: FontWeight.w500,
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustDropdown(
                    label: 'Note Type *',
                    hint: 'Select Note Type',
                    items: noteTypeList,
                    selectedValue: _selectedNoteType,
                    onChanged: (value) {
                      setState(() {
                        _selectedNoteType = value;
                        if (value != "Cash") {
                          _notesAmountController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedNoteType == "Cash") ...[
                    CustDropdown(
                      label: 'Denominations *',
                      hint: 'Select Denomination',
                      items: denominationsList,
                      selectedValue: _selectedDenomination,
                      onChanged: (value) {
                        setState(() {
                          _selectedDenomination = value;
                        });
                        _calculateAmount();
                      },
                    ),
                    const SizedBox(height: 16),
                    CustText(
                      name: 'No *',
                      size: 1.8,
                      fontWeightName: FontWeight.w500,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _notesNoController,
                      hintText: 'Enter No',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateAmount(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  CustText(
                    name: 'Amount *',
                    size: 1.8,
                    fontWeightName: FontWeight.w500,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _notesAmountController,
                    hintText: 'Enter Amount',
                    keyboardType: TextInputType.number,
                    enabled: _selectedNoteType != "Cash",
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textColor3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textColor3)),
                      ),
                      const SizedBox(width: 16),
                      CustButton(
                        name: "Save",
                        size: 30,
                        onSelected: (p0) {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddSalesDetailsDialog extends StatefulWidget {
  @override
  State<AddSalesDetailsDialog> createState() => _AddSalesDetailsDialogState();
}

class _AddSalesDetailsDialogState extends State<AddSalesDetailsDialog> {
  String? _selectedParticulars;
  final TextEditingController _salesQuantityController = TextEditingController();
  final TextEditingController _salesAmountController = TextEditingController();

  final List<String> particularsList = [
    "QR Ticket",
    "EMV CardSales",
    "FREE EXIT",
    "EMV EXIT",
    "OUTSTANDING MISC GENERATED",
    "OUTSTANDING AFC-QR PAID",
    "OUTSTANDING MISC PAID",
    "OUTSTANDING AFC-QR GENERATED",
    "QR NON CASH",
    "QR CASH DEPOSITED",
    "OUTSTANDING AFC-ONE PUNE CARD PAID",
    "ONE PUNE CARD NON CASH",
    "OUTSTANDING AFC-ONE PUNE CARD GENERATED",
    "ONE PUNE CARD CASH DEPOSITED",
    "PENALTY",
    "EXCESS AMOUNT",
    "DAILY PASS",
    "Paid Exit",
    "Surcharge"
  ];

  @override
  void dispose() {
    _salesQuantityController.dispose();
    _salesAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 15, bottom: 10, right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
            ),
            child: CustText(
              name: "Add Sales Details",
              size: 1.8,
              color: AppColors.textColor3,
              fontWeightName: FontWeight.w500,
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustDropdown(
                    label: 'Particulars *',
                    hint: 'Select Particulars',
                    items: particularsList,
                    selectedValue: _selectedParticulars,
                    onChanged: (value) {
                      setState(() {
                        _selectedParticulars = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CustText(
                    name: 'Quantity *',
                    size: 1.8,
                    fontWeightName: FontWeight.w500,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _salesQuantityController,
                    hintText: 'Enter Quantity',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustText(
                    name: 'Amount *',
                    size: 1.8,
                    fontWeightName: FontWeight.w500,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _salesAmountController,
                    hintText: 'Enter Amount',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textColor3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textColor3)),
                      ),
                      const SizedBox(width: 16),
                      CustButton(
                        name: "Save",
                        size: 30,
                        onSelected: (p0) {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}