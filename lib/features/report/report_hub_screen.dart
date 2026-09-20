import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/inspection_model.dart';
import '../../shared/providers/app_providers.dart';
import 'attendance/attendance_screen.dart';
import 'document/document_upload_screen.dart';
import 'incident/incident_report_screen.dart';
import 'inspection/inspection_wizard_screen.dart';
import 'observation/observation_screen.dart';

class ReportHubScreen extends ConsumerWidget {
  const ReportHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(rolePermissionsProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(context.l10n.createReport, style: AppTypography.headlineSm),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Header Motive Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardLayer1,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.strokeLowLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    color: AppColors.primaryAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUTORY LOGS & REPORTING HUB',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primaryAmber,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select a statutory report module. All submitted records are cryptographically signed with SHA-256 for DGMS / Mines Act compliance.',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.textMediumEmphasis,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Select Report Type / रिपोर्ट प्रकार चुनें',
            style: AppTypography.headlineMd.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),

          if (permissions?.canPerformInspection ?? true)
            _ReportChoice(
              icon: Icons.fact_check_outlined,
              title: 'Safety Inspection',
              hindiTitle: 'सुरक्षा निरीक्षण एवं चेकलिस्ट (7 DGMS Checklists)',
              description:
                  '7 Pre-configured DGMS statutory checklists: General Safety, Strata & Roof, Ventilation/Gas, Electrical FLP, HEMM Machinery, and Dust Suppression.',
              badge: '7 CHECKLISTS',
              badgeColor: AppColors.primaryAmberDark,
              onTap: () => _showChecklistSelectorModal(context),
            ),
          if (permissions?.canReportIncident ?? true)
            _ReportChoice(
              icon: Icons.warning_amber_rounded,
              title: 'Incident Report',
              hindiTitle: 'घटना रिपोर्ट (Emergency / Incident)',
              description:
                  'Accident, roof fall, toxic gas outburst, or high-risk dangerous occurrence requiring immediate authority broadcast.',
              badge: 'HIGH PRIORITY',
              color: AppColors.hazardRed,
              badgeColor: AppColors.hazardRed,
              onTap: () => _open(context, const IncidentReportScreen()),
            ),
          if (permissions?.canManageAttendance ?? true)
            _ReportChoice(
              icon: Icons.people_outline,
              title: 'Attendance & Muster Roll',
              hindiTitle: 'उपस्थिति एवं मस्टर रोल (Form-D / Headcount)',
              description:
                  'Underground miner headcount verification, pit muster point roll call, and contractor worker check-in.',
              badge: 'FORM-D',
              badgeColor: AppColors.telemetryBlue,
              onTap: () => _open(context, const AttendanceScreen()),
            ),
          if (permissions?.canSubmitObservation ?? true)
            _ReportChoice(
              icon: Icons.visibility_outlined,
              title: 'Observation / Grievance',
              hindiTitle: 'अवलोकन एवं शिकायत (Field Hazard / Grievance)',
              description:
                  'Quick atmospheric gas readings (CH4, CO, O2), field hazard sightings, or worker welfare/grievance notes.',
              badge: 'FIELD LOG',
              badgeColor: AppColors.secondaryOrange,
              onTap: () => _open(context, const ObservationScreen()),
            ),
          if (permissions?.canUploadDocument ?? true)
            _ReportChoice(
              icon: Icons.description_outlined,
              title: 'Document',
              hindiTitle: 'दस्तावेज़ एवं प्रमाण पत्र (Compliance Vault)',
              description:
                  'Upload or scan flameproof clearance certificates, DGMS approvals, vendor maintenance cards, or statutory notices.',
              badge: 'DOC VAULT',
              badgeColor: AppColors.complianceGreen,
              onTap: () => _open(context, const DocumentUploadScreen()),
            ),
        ],
      ),
    );
  }

  void _showChecklistSelectorModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.strokeActive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppColors.primaryAmber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statutory Audit Checklists',
                          style: AppTypography.headlineSm.copyWith(fontSize: 17),
                        ),
                        Text(
                          'वैधानिक सुरक्षा चेकलिस्ट (DGMS Standards)',
                          style: AppTypography.bilingualCue.copyWith(
                            color: AppColors.primaryAmber,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _ChecklistTile(
                    icon: Icons.security_rounded,
                    title: 'General Safety & PPE Checklist',
                    hindiTitle: 'दैनिक सामान्य सुरक्षा एवं PPE (CMR Reg 180)',
                    badge: 'DAILY SHIFT',
                    badgeColor: AppColors.primaryAmberDark,
                    itemsCount: '6 Questions',
                    onTap: () {
                      Navigator.pop(ctx);
                      _open(context, const InspectionWizardScreen(type: InspectionType.safety));
                    },
                  ),
                  _ChecklistTile(
                    icon: Icons.foundation_rounded,
                    title: 'Strata & Roof Support Checklist',
                    hindiTitle: 'छत एवं साइड सपोर्ट / रॉक बोल्टिंग (CMR Reg 123)',
                    badge: 'SCMP AUDIT',
                    badgeColor: AppColors.secondaryOrange,
                    itemsCount: '4 Questions',
                    onTap: () {
                      Navigator.pop(ctx);
                      _open(context, const InspectionWizardScreen(type: InspectionType.strata));
                    },
                  ),
                  _ChecklistTile(
                    icon: Icons.air_rounded,
                    title: 'Ventilation & Gas Monitoring Checklist',
                    hindiTitle: 'वेंटिलेशन एवं मल्टी-गैस जांच (CMR Reg 153)',
                    badge: 'GAS AUDIT',
                    badgeColor: AppColors.telemetryCyan,
                    itemsCount: '4 Questions',
                    onTap: () {
                      Navigator.pop(ctx);
                      _open(context, const InspectionWizardScreen(type: InspectionType.ventilation));
                    },
                  ),
                  _ChecklistTile(
                    icon: Icons.bolt_rounded,
                    title: 'Electrical & Flameproof (FLP) Checklist',
                    hindiTitle: 'विद्युत एवं FLP उपकरण जांच (CEA Reg 116)',
                    badge: 'FLP SAFETY',
                    badgeColor: AppColors.hazardRed,
                    itemsCount: '4 Questions',
                    onTap: () {
                      Navigator.pop(ctx);
                      _open(context, const InspectionWizardScreen(type: InspectionType.electrical));
                    },
                  ),
                  _ChecklistTile(
                    icon: Icons.fire_truck_rounded,
                    title: 'HEMM & Machinery Safety Checklist',
                    hindiTitle: 'मशीनरी, डंपर एवं ब्रेक जांच (DGMS Tech Cir)',
                    badge: 'HEMM AUDIT',
                    badgeColor: AppColors.primaryAmber,
                    itemsCount: '4 Questions',
                    onTap: () {
                      Navigator.pop(ctx);
                      _open(context, const InspectionWizardScreen(type: InspectionType.machinery));
                    },
                  ),
                  _ChecklistTile(
                    icon: Icons.eco_rounded,
                    title: 'Environmental & Dust Control Checklist',
                    hindiTitle: 'धूल दमन एवं पर्यावरण अनुपालन (DGMS Dust Code)',
                    badge: 'DUST & WATER',
                    badgeColor: AppColors.complianceGreen,
                    itemsCount: '3 Questions',
                    onTap: () {
                      Navigator.pop(ctx);
                      _open(context, const InspectionWizardScreen(type: InspectionType.environmental));
                    },
                  ),
                  _ChecklistTile(
                    icon: Icons.medical_services_outlined,
                    title: 'Labour Welfare & First-Aid Checklist',
                    hindiTitle: 'श्रमिक कल्याण, चिकित्सा एवं जल (Mines Rules)',
                    badge: 'WELFARE',
                    badgeColor: AppColors.telemetryBlue,
                    itemsCount: '3 Questions',
                    onTap: () {
                      Navigator.pop(ctx);
                      _open(context, const InspectionWizardScreen(type: InspectionType.labour));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _ReportChoice extends StatelessWidget {
  const _ReportChoice({
    required this.icon,
    required this.title,
    required this.hindiTitle,
    required this.description,
    required this.onTap,
    required this.badge,
    required this.badgeColor,
    this.color = AppColors.primaryAmberDark,
  });

  final IconData icon;
  final String title;
  final String hindiTitle;
  final String description;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppColors.cardLayer1,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 15,
                              color: color == AppColors.hazardRed
                                  ? AppColors.hazardRed
                                  : AppColors.textHighEmphasis,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: AppTypography.labelSm.copyWith(
                              color: badgeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hindiTitle,
                      style: AppTypography.bilingualCue.copyWith(
                        color: AppColors.primaryAmber,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textMediumEmphasis,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textDisabled,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.icon,
    required this.title,
    required this.hindiTitle,
    required this.badge,
    required this.badgeColor,
    required this.itemsCount,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hindiTitle;
  final String badge;
  final Color badgeColor;
  final String itemsCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: AppColors.cardLayer1,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: badgeColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: AppTypography.labelSm.copyWith(
                              color: badgeColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hindiTitle,
                      style: AppTypography.bilingualCue.copyWith(
                        color: AppColors.textMediumEmphasis,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '• $itemsCount • Full Statutory Audit Form',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.primaryAmber,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textDisabled,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
