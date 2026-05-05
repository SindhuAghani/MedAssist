import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:mindheal/common/widgets/appbar/appbar.dart';
import 'package:mindheal/common/widgets/custom_shapes/containers/t_container.dart';
import 'package:mindheal/features/test_reports/controller/test_report_form_controller.dart';
import 'package:mindheal/features/test_reports/models/test_metric_model.dart';
import 'package:mindheal/features/test_reports/models/test_report_template_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/sizes.dart';
import 'package:mindheal/utils/helpers/helper_functions.dart';

class TestReportFormScreen extends StatefulWidget {
  const TestReportFormScreen({super.key});

  @override
  State<TestReportFormScreen> createState() => _TestReportFormScreenState();
}

class _TestReportFormScreenState extends State<TestReportFormScreen> {
  final TestReportFormController controller = Get.find<TestReportFormController>();
  final Map<String, TextEditingController> _metricControllers = {};

  @override
  void dispose() {
    for (final textController in _metricControllers.values) {
      textController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);


    if (!controller.isDoctor) {
      return Scaffold(
        appBar: TAppBar(title: const Text('Create Test Report'),showActions: false,showSkipButton: false,showBackArrow: true,),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Only doctors can create test reports.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Create Test Report'),showActions: false,showSkipButton: false,showBackArrow: true,
      ),
      body: Obx(
        () => Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: TSizes.spaceBtwItems),
                _buildPatientSection(isDark),
                const SizedBox(height: TSizes.spaceBtwItems),
                _buildReportMetaSection(context,isDark),
                const SizedBox(height: TSizes.spaceBtwItems),
                _buildMetricsSection(isDark),
                const SizedBox(height: TSizes.spaceBtwItems),
                _buildAttachmentsSection(isDark),
                const SizedBox(height: TSizes.spaceBtwItems),
                _buildNotesSection(isDark),
                const SizedBox(height: TSizes.spaceBtwSections),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final template = TTestReportTemplates.templateFor(controller.selectedReportType.value);

    return TContainer(
      showShadow: true,
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doctor Test Report',
            style: Get.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Create a structured report with numeric values for charts and add optional image or PDF attachments.',
            style: Get.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.sm),
          Chip(
            label: Text(template.title),
            backgroundColor: TColors.primary.withValues(alpha: 0.1),
            labelStyle: const TextStyle(color: TColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSection(bool isDark) {
    final patients = controller.allPatients;

    return TContainer(
      showShadow: true,
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: TSizes.md),
          if (controller.isLoadingPatients)
            const LinearProgressIndicator()
          else
            DropdownButtonFormField<String>(
              initialValue: controller.selectedPatientId.value.isEmpty ? null : controller.selectedPatientId.value,
              decoration: const InputDecoration(
                labelText: 'Select Patient',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_search),
              ),
              items: patients
                  .map(
                    (patient) => DropdownMenuItem<String>(
                      value: patient.id,
                      child: Text(patient.fullName.isEmpty ? patient.email : patient.fullName),
                    ),
                  )
                  .toList(),
              validator: (value) => value == null || value.isEmpty ? 'Please select a patient' : null,
              onChanged: (value) {
                if (value != null) controller.selectPatient(value);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReportMetaSection(BuildContext context, bool isDark) {
    return TContainer(
      showShadow: true,
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report Details', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: TSizes.md),
          DropdownButtonFormField<TestReportType>(
            initialValue: controller.selectedReportType.value,
            decoration: const InputDecoration(
              labelText: 'Report Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.science),
            ),
            items: TestReportType.values
                .map(
                  (type) => DropdownMenuItem<TestReportType>(
                    value: type,
                    child: Text(TTestReportTemplates.templateFor(type).title),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  controller.loadTemplate(value);
                  _syncMetricControllers();
                });
              }
            },
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: controller.labNameController,
            decoration: const InputDecoration(
              labelText: 'Lab / Hospital Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_hospital),
            ),
            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter lab or hospital name' : null,
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          InkWell(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: controller.selectedReportDate.value,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedDate != null) {
                controller.setReportDate(pickedDate);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Report Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                '${controller.selectedReportDate.value.day}/${controller.selectedReportDate.value.month}/${controller.selectedReportDate.value.year}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(bool isDark) {

    return TContainer(
      showShadow: true,
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Test Metrics', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: TSizes.xs),
          Text(
            'Enter structured numeric values so the patient, caregiver, and doctor can view trends graphically.',
            style: Get.textTheme.bodySmall?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.md),
          ...controller.metrics.map((metric) => _buildMetricInput(metric, isDark)),
        ],
      ),
    );
  }

  Widget _buildMetricInput(TestMetricModel metric, bool isDark) {
    final textController = _metricControllers.putIfAbsent(
      metric.metricKey,
      () => TextEditingController(),
    );


    final flagColor = _flagColor(metric.flag);
    final flagLabel = metric.flag == TestMetricFlag.unknown ? 'Pending' : metric.flag.name.toUpperCase();
    final referenceLabel = _referenceLabel(metric);

    return Padding(
      padding: const EdgeInsets.only(bottom: TSizes.md),
      child: TContainer(
        backgroundColor: isDark ? TColors.darkContainer : Colors.grey.shade50,
        showBorder: true,
        borderColor: Colors.grey.shade200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    metric.metricLabel,
                    style: Get.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(flagLabel),
                  backgroundColor: flagColor.withValues(alpha: 0.12),
                  labelStyle: TextStyle(color: flagColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: TSizes.sm),
            TextFormField(
              controller: textController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Value${metric.unit.isNotEmpty ? ' (${metric.unit})' : ''}',
                border: const OutlineInputBorder(),
                helperText: referenceLabel,
              ),
             onChanged: (value) {
               controller.updateMetricValue(metric.metricKey, value);
             },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(bool isDark) {
    return TContainer(
      showShadow: true,
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attachments', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: TSizes.xs),
          Text(
            'Upload a report image or PDF. Structured values will still drive charting.',
            style: Get.textTheme.bodySmall?.copyWith(color: TColors.textSecondary),
          ),
          const SizedBox(height: TSizes.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isUploading.value ? null : _pickAndUploadAttachment,
              icon: controller.isUploading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(controller.isUploading.value ? 'Uploading...' : 'Upload Image or PDF'),
            ),
          ),
          if (controller.attachmentUrls.isNotEmpty) ...[
            const SizedBox(height: TSizes.md),
            ...controller.attachmentUrls.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file),
                title: Text('Attachment ${entry.key + 1}'),
                subtitle: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => controller.removeAttachment(entry.value),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(bool isDark) {
    return TContainer(
      showShadow: true,
      backgroundColor: isDark ? TColors.darkContainer : TColors.lightContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Clinical Notes', style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: TSizes.md),
          TextFormField(
            controller: controller.summaryController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Summary',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),
          TextFormField(
            controller: controller.notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Doctor Notes',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () => controller.saveReport(status: TestReportStatus.draft),
              child: const Text('Save Draft'),
            ),
          ),
          const SizedBox(width: TSizes.md),
          Expanded(
            child: ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () => controller.saveReport(status: TestReportStatus.finalReport),
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Final'),
            ),
          ),
        ],
      ),
    );
  }

  void _syncMetricControllers() {
    final validKeys = controller.metrics.map((metric) => metric.metricKey).toSet();
    final staleKeys = _metricControllers.keys.where((key) => !validKeys.contains(key)).toList();

    for (final key in staleKeys) {
      _metricControllers.remove(key)?.dispose();
    }

    for (final metric in controller.metrics) {
      final existing = _metricControllers[metric.metricKey];
      if (existing == null) {
        _metricControllers[metric.metricKey] = TextEditingController(
          text: metric.value?.toString() ?? '',
        );
      } else {
        // final nextText = metric.value?.toString() ?? '';
        // if (existing.text != nextText) {
        //   existing.text = nextText;
        // }
      }
    }
  }

  Future<void> _pickAndUploadAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    if (file.path == null) return;

    await controller.uploadAttachment(
      filePath: file.path!,
      fileName: file.name,
    );
  }

  String _referenceLabel(TestMetricModel metric) {
    if (metric.referenceMin == null || metric.referenceMax == null) {
      return 'Reference range will be added later';
    }

    final unitSuffix = metric.unit.isEmpty ? '' : ' ${metric.unit}';
    return 'Reference: ${metric.referenceMin} - ${metric.referenceMax}$unitSuffix';
  }

  Color _flagColor(TestMetricFlag flag) {
    switch (flag) {
      case TestMetricFlag.low:
        return Colors.orange;
      case TestMetricFlag.normal:
        return Colors.green;
      case TestMetricFlag.high:
        return Colors.red;
      case TestMetricFlag.unknown:
        return Colors.blueGrey;
    }
  }
}
