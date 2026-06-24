import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_constants.dart';
import '../../../utils/responsive_helper.dart';
import '../../../utils/widgets/accordion_card.dart';
import '../../../utils/widgets/cust_text.dart';
import '../../../utils/widgets/custom_app_bar.dart';

class ViewDetailScreen extends StatefulWidget {
  const ViewDetailScreen({Key? key}) : super(key: key);

  @override
  State<ViewDetailScreen> createState() => _ViewDetailScreenState();
}

class _ViewDetailScreenState extends State<ViewDetailScreen> {
  bool failureDetailsExpanded = true;
  bool serviceAffectedExpanded = true;
  bool attachedDocumentExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
    appBar: CustomAppBar(
      title: 'SIG/10-2024/0024',
      showDrawer: false,
      onLeadingPressed: () => Navigator.pop(context),
    ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: AppConstants.sectionSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText.detailLabel('Failure No:'),
                                  CustText.detailValue('SIG/10-2024/0024'),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText.detailLabel('Created On:'),
                                  CustText.detailValue('17-10-2024 14:00'),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: AppConstants.elementSpacing),
                          CustText.detailLabel('Location:'),
                          CustText.detailValue('DER'),
                          const SizedBox(height: AppConstants.elementSpacing),
                          Row(
                            children: [
                              CustText.detailLabel('Priority:'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.orangeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: 'Medium',
                                  size: AppConstants.detailValueSize,
                                  color: AppColors.orangeColor,
                                  fontWeightName: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              CustText.detailLabel('Status:'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: 'Open',
                                  size: AppConstants.detailValueSize,
                                  color: AppColors.red,
                                  fontWeightName: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                    // Failure Details Card
                    AccordionCard(
                        title: "Failure Details",
                        isExpanded: true,
                      expanded: failureDetailsExpanded,
                      onTap: () => setState(() => failureDetailsExpanded = !failureDetailsExpanded),
                    child:failureDetailsExpanded ? _failureDetailsContent() : null,),
                    const SizedBox(height: AppConstants.elementSpacing),
                    AccordionCard(
                      isExpanded: true,
                      title: 'Passengers Affected',
                      expanded: serviceAffectedExpanded,
                      onTap: () => setState(() => serviceAffectedExpanded = !serviceAffectedExpanded),
                      child: serviceAffectedExpanded ? _serviceAffectedContent() : null,
                    ),
                    const SizedBox(height: AppConstants.elementSpacing),
                    AccordionCard(
                      isExpanded: true,
                      title: 'Attached Document',
                      expanded: attachedDocumentExpanded,
                      onTap: () => setState(() => attachedDocumentExpanded = !attachedDocumentExpanded),
                      child: attachedDocumentExpanded ? _attachedDocumentContent() : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _failureDetailsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRow(label1: 'Department', value1: 'Department Name', label2: 'Location', value2: 'Location'),
        SizedBox(height: 8),
        DetailRow(label1: 'Functional Location', value1: 'Functional Location', label2: 'Equipment Number', value2: 'Equipment Number'),
        SizedBox(height: 8),
        DetailRow(label1: 'Actual Failure Occurrence', value1: 'Actual Failure Occurrence', label2: "Person Responsible", value2: 'Person Responsible'),
        SizedBox(height: 8),
        CustText.formLabel("Failure Description"),
        CustText(
          name: 'Lorem ipsum dolor sit amet consectetur. Venenatis donec nisl elementum dictum magna facilisi. Suspendisse faucibus ultrices sed tortor magna elementum mattis quisque. Semper pharetra amet eu mauris arcu i',
          size: 14,
          color: AppColors.black,
          fontWeightName: FontWeight.w500,
        ),
      ],
    );
  }

  Widget _serviceAffectedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRow(
          label1: 'Is passengers affected?', value1: 'Yes', boldValue1: true,
          label2: 'Train Delay In Min', value2: '0',
        ),
        SizedBox(height: 8),
        DetailRow(
          label1: 'Train Delay', value1: '0',
          label2: 'Train Cancel', value2: 'Yes',
        ),
        SizedBox(height: 8),
        DetailRow(
          label1: 'Train Replace', value1: 'No',
          label2: 'Train Withdrawal', value2: 'Train Withdrawal',
        ),
        SizedBox(height: 8),
        DetailRow(
          label1: 'Train Deboarded', value1: 'Train Deboarded',
          label2: '', value2: '',
        ),
        SizedBox(height: 8),
        DetailRow(
          label1: 'Passengers Deboarded', value1: 'Yes', boldValue1: true,
          label2: 'Train Replace', value2: 'No',
        ),
        SizedBox(height: 8),
        DetailRow(
          label1: 'Train Withdrawal', value1: 'Train Withdrawal',
          label2: 'Train Deboarded', value2: 'Train Deboarded',
        ),
      ],
    );
  }

  Widget _attachedDocumentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: '2 Files',
          size: 16,
          color: AppColors.textColor,
          fontWeightName: FontWeight.w500,
        ),
        const SizedBox(height: 8),
        _fileRow('Filename.ext', '62.33 kB'),
        const SizedBox(height: 8),
        _fileRow('Filename.ext', '62.33 kB'),
      ],
    );
  }

  Widget _fileRow(String filename, String size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.dividerColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            height:ResponsiveHelper.height(context, 20),
            width:  ResponsiveHelper.height(context, 20),
            decoration: BoxDecoration(color: AppColors.containerColor,borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: filename, size: 17,color: AppColors.black,),
                CustText(name: size, size: 14,color: Colors.black,),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey), // Remove icon
            onPressed: () {
              // TODO: Implement remove file logic
            },
          ),
        ],
      ),
    );
  }
}

class DetailColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool boldValue;
  final double? size;
  const DetailColumn({
    Key? key,
    required this.label,
    required this.value,
    this.boldValue = false,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText.detailLabel(label),
        CustText.detailValue(value),
      ],
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label1, value1, label2, value2;
  final bool boldValue1, boldValue2;
  final double size;
  const DetailRow({
    Key? key,
    required this.label1,
    required this.value1,
    required this.label2,
    required this.value2,
    this.boldValue1 = false,
    this.boldValue2 = false,
    this.size = 1.4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: DetailColumn(label: label1, value: value1, boldValue: boldValue1, size: size)),
        SizedBox(width: 16),
        Expanded(child: DetailColumn(label: label2, value: value2, boldValue: boldValue2, size: size)),
      ],
    );
  }
}