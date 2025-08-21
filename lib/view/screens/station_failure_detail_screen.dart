import 'package:flutter/material.dart';
import 'package:om_mobile/utils/size_config.dart';
import 'package:om_mobile/widgets/accordion_card.dart';
import 'package:om_mobile/widgets/custom_app_bar.dart';
import 'widgets/cust_text.dart';
import 'constants/colors.dart';

class StationFailureDetailScreen extends StatefulWidget {
  const StationFailureDetailScreen({Key? key}) : super(key: key);

  @override
  State<StationFailureDetailScreen> createState() => _StationFailureDetailScreenState();
}

class _StationFailureDetailScreenState extends State<StationFailureDetailScreen> {
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText(
                                    name: 'Failure No:',
                                    size: 1.4,
                                    color: AppColors.textColor4,
                                  ),
                                  CustText(
                                    name: 'SIG/10-2024/0024',
                                    size: 1.6,
                                    fontWeightName: FontWeight.w600,
                                    color: AppColors.black,
                                  ),

                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustText(
                                    name: 'Created On:',
                                    size: 1.4,
                                    color: AppColors.textColor4,
                                  ),
                                  CustText(
                                    name: '17-10-2024 14:00',
                                    size: 1.6,
                                    fontWeightName: FontWeight.w600,
                                    color: AppColors.black,
                                  ),
                                ],
                              )
                            ],),
                          SizedBox(height: 1 * SizeConfig.heightMultiplier),
                          CustText(
                            name: 'Location:',
                            size: 1.4,
                            color: AppColors.textColor4,
                          ),
                          CustText(
                            name: 'DER',
                            size: 1.6,
                            fontWeightName: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          SizedBox(height: 1 * SizeConfig.heightMultiplier),
                          Row(
                            children: [
                              CustText(
                                name: 'Priority:',
                                size: 1.4,
                                color: AppColors.textColor4,
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: 'Medium',
                                  size: 1.4,
                                  color: AppColors.orange,
                                ),
                              ),
                              Spacer(),
                              CustText(
                                name: 'Status:',
                                size: 1.4,
                                color: AppColors.textColor4,
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: CustText(
                                  name: 'Open',
                                  size: 1.4,
                                  color: AppColors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 1* SizeConfig.heightMultiplier,),
                    AccordionCard(
                      isExpanded: true,
                      title: 'Failure Details',
                      expanded: failureDetailsExpanded,
                      onTap: () => setState(() => failureDetailsExpanded = !failureDetailsExpanded),
                      child: failureDetailsExpanded ? _failureDetailsContent() : null,
                    ),
                    SizedBox(height: 1* SizeConfig.heightMultiplier,),
                    AccordionCard(
                      isExpanded: true,
                      title: 'Passengers Affected',
                      expanded: serviceAffectedExpanded,
                      onTap: () => setState(() => serviceAffectedExpanded = !serviceAffectedExpanded),
                      child: serviceAffectedExpanded ? _serviceAffectedContent() : null,
                    ),
                    SizedBox(height: 1* SizeConfig.heightMultiplier,),
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
        DetailRow(label1: 'Functional Location', value1: 'Functional Location', label2: 'Sub Location', value2: 'Sub Location'),
        SizedBox(height: 8),
        DetailRow(label1: 'System', value1: 'System', label2: 'Actual Failure Occurrence', value2: 'Actual Failure Occurrence'),

        DetailRow(label1: 'Failure Reported By', value1: 'Failure Reported By', label2: "", value2: ''),
        SizedBox(height: 8),
        CustText(
          name: 'Failure Description',
          size: 1.4,
          color: AppColors.textColor4,
        ),
        CustText(
          name: 'Lorem ipsum dolor sit amet consectetur. Venenatis donec nisl elementum dictum magna facilisi. Suspendisse faucibus ultrices sed tortor magna elementum mattis quisque. Semper pharetra amet eu mauris arcu i',
          size: 1.4,
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
          label1: 'Passengers Deboarding', value1: 'Yes', boldValue1: true,
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
          size: 1.6,
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
            height: 5 * SizeConfig.heightMultiplier,
            width:  5 * SizeConfig.heightMultiplier,
            decoration: BoxDecoration(color: AppColors.containerColor,borderRadius: BorderRadius.circular(5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustText(name: filename, size: 1.7,color: AppColors.black,),
                CustText(name: size, size: 1.4,color: Colors.black,),
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
  final double size;
  const DetailColumn({
    Key? key,
    required this.label,
    required this.value,
    this.boldValue = false,
    this.size = 1.4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustText(
          name: label,
          size: size,
          color: AppColors.textColor4,
        ),
        CustText(
          name: value,
          size: size,
          color: AppColors.black,
          fontWeightName:  FontWeight.w500,
        ),
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