/// Read-only contractor master-data contract.  Field values are deliberately
/// dynamic where the supplied dataset has nested document/certificate values.
class ContractorDto {
  final String contractorId;
  final String companyName;
  final Object? licenseValidity;
  final Object? insuranceStatus;
  final Object? complianceDocuments;
  final Object? documentExpiryDates;
  final Object? equipmentInspectionCertificates;

  const ContractorDto({required this.contractorId, required this.companyName,
    this.licenseValidity, this.insuranceStatus, this.complianceDocuments,
    this.documentExpiryDates, this.equipmentInspectionCertificates});

  factory ContractorDto.fromJson(Map<String, dynamic> json) => ContractorDto(
    contractorId: json['contractor_id'] as String,
    companyName: json['company_name'] as String,
    licenseValidity: json['license_validity'], insuranceStatus: json['insurance_status'],
    complianceDocuments: json['compliance_documents'],
    documentExpiryDates: json['document_expiry_dates'],
    equipmentInspectionCertificates: json['equipment_inspection_certificates'],
  );

  Map<String, dynamic> toJson() => {
    'contractor_id': contractorId, 'company_name': companyName,
    'license_validity': licenseValidity, 'insurance_status': insuranceStatus,
    'compliance_documents': complianceDocuments, 'document_expiry_dates': documentExpiryDates,
    'equipment_inspection_certificates': equipmentInspectionCertificates,
  };
}
