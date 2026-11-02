/// One meter reading of the BMS inspection.
class BmsField {
  final String label;
  final String payloadKey; // key sent to the API
  final String responseKey; // key returned by GetBMSDetails
  final bool required;

  const BmsField(this.label, this.payloadKey, this.responseKey,
      {this.required = false});
}

/// Fields shown together in one titled card.
class BmsSection {
  final String title;
  final List<BmsField> fields;

  const BmsSection(this.title, this.fields);
}

const bmsSections = <BmsSection>[
  BmsSection('MDB - 1', [
    BmsField('MDB - 1 MFM Import Kwh', 'MDB1MFMIMportKwh', 'mdB1MFMIMportKwh',
        required: true),
    BmsField('MDB - 1 MFM Export Kwh', 'MDB1MFMExportKwh', 'mdB1MFMExportKwh',
        required: true),
    BmsField(
        'MDB - 1 MFM Import KVah', 'MDB1MFMIMportKVah', 'mdB1MFMIMportKVah'),
    BmsField(
        'MDB - 1 MFM Export KVah', 'MDB1MFMExportKVah', 'mdB1MFMExportKVah'),
  ]),
  BmsSection('MDB - 2', [
    BmsField('MDB - 2 MFM Import Kwh', 'MDB2MFMIMportKwh', 'mdB2MFMIMportKwh'),
    BmsField('MDB - 2 MFM Export Kwh', 'MDB2MFMExportKwh', 'mdB2MFMExportKwh'),
    BmsField(
        'MDB - 2 MFM Import KVah', 'MDB2MFMIMportKVah', 'mdB2MFMIMportKVah'),
    BmsField(
        'MDB - 2 MFM Export KVah', 'MDB2MFMExportKVah', 'mdB2MFMExportKVah'),
  ]),
  BmsSection('Solar and S&T UPS', [
    BmsField('Solar MFM KWh', 'SolarMFMKWh', 'solarMFMKWh'),
    BmsField('Solar MFM KVah', 'SolarMFMKVah', 'solarMFMKVah'),
    BmsField('S&T UPS MDB KWh', 'SandTUPSMDBKWh', 'sandTUPSMDBKWh'),
    BmsField('S&T UPS EPP KWh', 'SandTUPSEPPKWh', 'sandTUPSEPPKWh'),
  ]),
  BmsSection('Panels', [
    BmsField('EPP KWh', 'EPPKWh', 'eppkWh'),
    BmsField('MLP KWh', 'MLPKWh', 'mlpkWh'),
    BmsField('ACPP KWh', 'ACPPKWh', 'acppkWh'),
    BmsField('ESC Panel KWh', 'ESCPanelKWh', 'escPanelKWh'),
    BmsField('DPP KWh', 'DPPKWh', 'dppkWh'),
    BmsField('FPP KWh', 'FPPKWh', 'fppkWh'),
    BmsField('EMLP KWh', 'EMLPKWh', 'emlpkWh'),
    BmsField('UPSO KWh', 'UPSOKWh', 'upsokWh'),
    BmsField('AMF Panel KWh', 'AMFPanelKWh', 'amfPanelKWh'),
    BmsField('Solar MSEDCL', 'SolarMSEDCL', 'solarMSEDCL'),
  ]),
];
