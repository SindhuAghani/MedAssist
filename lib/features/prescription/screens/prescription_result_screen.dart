import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindheal/features/prescription/controller/prescription_reader_controller.dart';

import '../../../common/widgets/custom_shapes/containers/t_container.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../../personalization/controllers/user_controller.dart';
import '../../personalization/models/user_model.dart';
import '../models/prescription_model.dart'; // Added Iconsax for modern icons



class PrescriptionResultsScreen extends StatefulWidget {
  const PrescriptionResultsScreen({super.key});

  @override
  State<PrescriptionResultsScreen> createState() => _PrescriptionResultsScreenState();
}

class _PrescriptionResultsScreenState extends State<PrescriptionResultsScreen> {
  final PrescriptionReaderController _controller = Get.find<PrescriptionReaderController>(); // Use Get.find if already put
  final UserController _userController = Get.find<UserController>();

  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedCaregiverId;
  final Map<String, List<String>> _medicationTimings = {};

  @override
  void initState() {
    super.initState();
    _loadArguments();
    // Pre-fill fields with mock/extracted data if available (optional)
    _doctorNameController.text = 'Dr. Jane Doe';
    _clinicNameController.text = 'City General Hospital';

    // Load users based on role
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_userController.user.value.role.name == AppRole.patient.name) {
        _userController.loadAllCaregivers();
      } else {
        _userController.loadAllPatients();
      }
    });
  }

  void _loadArguments() {
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      // Initialize medication timings
      for (var medication in _controller.extractedMedications) {
        _medicationTimings[medication.id] = medication.timings.toList(); // Copy list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Prescription Review',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Prescription Info Form
            _buildPrescriptionForm(),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Medications List
            _buildMedicationsList(),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Extracted Text
            _buildExtractedTextSection(),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Simplified Text
            _buildSimplifiedTextSection(),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Urdu Translation
            _buildTranslatedTextSection(),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Additional Notes
            _buildNotesSection(),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: _buildSaveButton(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Final Check',
          style: Get.textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: TSizes.sm),
        Text(
          'Please verify all details, assign a patient/caregiver, and set medication timings before saving.',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: TColors.textSecondary,
          ),
        ),
        const SizedBox(height: TSizes.md),
        Obx(() => _controller.isSaving
            ? const LinearProgressIndicator(color: TColors.primary)
            : const SizedBox()
        ),
      ],
    );
  }

  Widget _buildPrescriptionForm() {
    return TContainer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('General Details', Iconsax.document_text),
          const SizedBox(height: TSizes.md),

          // Doctor Name
          TextFormField(
            controller: _doctorNameController,
            decoration: const InputDecoration(
              labelText: 'Doctor Name',
              prefixIcon: Icon(Iconsax.user_tag),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Clinic Name
          TextFormField(
            controller: _clinicNameController,
            decoration: const InputDecoration(
              labelText: 'Clinic/Hospital',
              prefixIcon: Icon(Iconsax.hospital),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Caregiver/Patient Selection
          _buildCaregiverDropdown(),
        ],
      ),
    );
  }

  Widget _buildCaregiverDropdown() {
    final isPatientRole = _userController.user.value.role.name == AppRole.patient.name;
    final userList = isPatientRole ? _userController.allCaregivers : _userController.allPatients;
    final isLoading = isPatientRole ? _userController.isLoadingCaregivers : _userController.isLoadingPatients;
    final labelText = isPatientRole ? 'Assign to Caregiver (Optional)' : 'Assign to Patient (Optional)';
    final emptyText = isPatientRole ? 'No caregivers available' : 'No patients available';
    final helpText = isPatientRole ? 'Select a caregiver to manage this prescription' : 'Select the patient this prescription is for';

    return Obx(() {
      if (isLoading && userList.isEmpty) {
        return _buildLoadingDropdown(labelText, 'Loading users...');
      }

      if (userList.isEmpty) {
        return _buildLoadingDropdown(labelText, emptyText, icon: Iconsax.user_remove);
      }

      final verifiedUsers = userList
          .where((p) => p.verificationStatus == VerificationStatus.approved)
          .toList();
      final otherUsers = userList
          .where((p) => p.verificationStatus != VerificationStatus.approved)
          .toList();

      return DropdownButtonFormField<String>(
        initialValue: _selectedCaregiverId ?? 'no_selection',
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: const Icon(Iconsax.profile_add),
          border: const OutlineInputBorder(),
          helperMaxLines: 2,
          helperText: helpText,
        ),
        isExpanded: true,
        items: [
          DropdownMenuItem<String>(
            value: 'no_selection',
            child: Text(isPatientRole ? 'No Caregiver' : 'No Patient', style: Get.textTheme.bodyMedium?.copyWith(color: TColors.textSecondary)),
          ),
          // Group by verification status
          ..._createDropdownItemGroups(verifiedUsers, otherUsers, isPatientRole),
        ],
        onChanged: (value) {
          setState(() {
            _selectedCaregiverId = value == 'no_selection' ? null : value;
          });
        },
      );
    });
  }

  Widget _buildLoadingDropdown(String labelText, String helperText, {IconData icon = Iconsax.refresh_square_2}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: TColors.textSecondary),
        border: const OutlineInputBorder(),
        helperText: helperText,
      ),
      items: const [],
      onChanged: (String? value) {},
      hint: const Text('...'),
    );
  }

  List<DropdownMenuItem<String>> _createDropdownItemGroups(
      List<UserModel> verifiedUsers,
      List<UserModel> otherUsers,
      bool isCaregiverList) {
    final items = <DropdownMenuItem<String>>[];
    final verifiedTitle = isCaregiverList ? 'Verified Caregivers' : 'Verified Patients';
    final otherTitle = isCaregiverList ? 'Other Caregivers' : 'Other Patients';

    // Add verified group
    if (verifiedUsers.isNotEmpty) {
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          child: _buildDropdownGroupHeader(verifiedTitle, TColors.success),
        ),
      );
      items.addAll(verifiedUsers.map((user) => _buildUserDropdownItem(user)));
      if (otherUsers.isNotEmpty) {
        items.add(const DropdownMenuItem<String>(
          enabled: false,
          child: Divider(height: 1, color: Colors.grey),
        ));
      }
    }

    // Add other patients group
    if (otherUsers.isNotEmpty) {
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          child: _buildDropdownGroupHeader(otherTitle, TColors.warning),
        ),
      );
      items.addAll(otherUsers.map((user) => _buildUserDropdownItem(user)));
    }

    return items;
  }

  Widget _buildDropdownGroupHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 4.0),
      child: Text(
        title.toUpperCase(),
        style: Get.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  DropdownMenuItem<String> _buildUserDropdownItem(UserModel user) {
    return DropdownMenuItem<String>(
      value: user.id,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user.fullName,
                  style: Get.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildExtractedTextSection() {
    return TContainer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Extracted Text (Raw)', Iconsax.document_text_1),
          const SizedBox(height: TSizes.md),
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            width: double.infinity,
            decoration: BoxDecoration(
              color: TColors.lightContainer,
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SelectableText(
              _controller.extractedText,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: TColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedTextSection() {
    return TContainer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Simplified Explanation', Iconsax.security_safe),
          const SizedBox(height: TSizes.md),
          Container(
            padding: const EdgeInsets.all(TSizes.md),
            width: double.infinity,
            decoration: BoxDecoration(
              color: TColors.lightGrey.withOpacity(0.2), // Light success color
              borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
              border: Border.all(color: TColors.primary.withOpacity(0.1)),
            ),
            child: SelectableText(
              _controller.simplifiedText,
              style: Get.textTheme.bodyMedium?.copyWith(
                color: TColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: TSizes.md),
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _controller.isTranslating
                    ? null
                    : () => _controller.translateSimplifiedTextToUrdu(),
                icon: _controller.isTranslating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate),
                label: Text(
                  _controller.isTranslating
                      ? 'Translating...'
                      : 'Show Translation in Urdu',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslatedTextSection() {
    return Obx(() {
      if (_controller.translatedText.trim().isEmpty) {
        return const SizedBox.shrink();
      }

      return TContainer(
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Urdu Translation', Icons.language),
            const SizedBox(height: TSizes.md),
            Container(
              padding: const EdgeInsets.all(TSizes.md),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
                border: Border.all(color: Colors.green.withOpacity(0.18)),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SelectableText(
                  _controller.translatedText,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                    height: 1.7,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNotesSection() {
    return TContainer(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Additional Notes', Iconsax.note_text),
          const SizedBox(height: TSizes.md),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Add any personal notes or reminders',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsList() {
    return TContainer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionTitle('Medications', Iconsax.receipt_2),
              const Spacer(),
              Text(
                '${_controller.extractedMedications.length} items',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: TColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),

          // Medications List
          Obx(() => ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _controller.extractedMedications.length,
            separatorBuilder: (context, index) => const SizedBox(height: TSizes.spaceBtwItems),
            itemBuilder: (context, index) {
              final medication = _controller.extractedMedications[index];
              return _buildMedicationCard(medication, index);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication, int index) {
    // Determine which list to use (map value or default to controller's value)
    final timings = _medicationTimings[medication.id] ?? medication.timings;

    return TContainer(
      backgroundColor: TColors.lightContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medication Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                ),
                child: Center(
                  child: Text(
                    (index + 1).toString(),
                    style: Get.textTheme.titleLarge!.copyWith(color: TColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: TSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (medication.genericName.isNotEmpty)
                      Text(
                        '(${medication.genericName})',
                        style: Get.textTheme.bodySmall?.copyWith(color: TColors.textSecondary),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Iconsax.trash, color: TColors.error, size: 20),
                onPressed: () => _removeMedication(medication.id),
                tooltip: 'Remove Medication',
              ),
            ],
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Dosage, Frequency, and Duration
          Wrap(
            spacing: TSizes.sm,
            runSpacing: TSizes.sm,
            children: [
              _buildDetailChip(medication.dosage, Iconsax.box),
              _buildDetailChip(medication.frequency, Iconsax.repeat),
              _buildDetailChip(medication.duration, Iconsax.calendar),
            ],
          ),

          const SizedBox(height: TSizes.spaceBtwItems),

          // Instructions
          if (medication.instructions?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(bottom: TSizes.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: Get.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication.instructions!,
                    style: Get.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          // Timings Selection
          _buildTimingsSelector(medication, timings),

        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 14, color: TColors.primary),
      label: Text(text),
      backgroundColor: TColors.softGrey.withOpacity(0.1),
      labelStyle: Get.textTheme.labelMedium?.copyWith(color: TColors.primary, fontWeight: FontWeight.w500),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusMd)),
    );
  }

  Widget _buildTimingsSelector(Medication medication, List<String> currentTimings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Daily Timings (Select all that apply):',
          style: Get.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Wrap(
          spacing: TSizes.sm,
          runSpacing: TSizes.sm,
          children: _getTimeSlots().map((time) {
            final isSelected = currentTimings.contains(time);
            return ChoiceChip(
              label: Text(time),
              selected: isSelected,
              selectedColor: TColors.primary,
              backgroundColor: TColors.lightContainer,
              labelStyle: Get.textTheme.labelMedium?.copyWith(
                color: isSelected ? Colors.white : TColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TSizes.cardRadiusSm),
                side: BorderSide(
                  color: isSelected ? TColors.primary : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              onSelected: (selected) {
                setState(() {
                  final newTimings = currentTimings.toList();
                  if (selected) {
                    newTimings.add(time);
                  } else {
                    newTimings.remove(time);
                  }
                  // Sort to maintain order
                  newTimings.sort();
                  _medicationTimings[medication.id] = newTimings;
                  _controller.updateMedicationTiming(medication.id, newTimings);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  List<String> _getTimeSlots() {
    return [
      '06:00', '08:00', '10:00', '12:00',
      '14:00', '16:00', '18:00', '20:00',
      '22:00', '00:00'
    ];
  }

  Widget _buildSaveButton() {
    return Obx(() => ElevatedButton(
      onPressed: _controller.isSaving ? null : _savePrescription,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: TColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.cardRadiusLg)),
      ),
      child: _controller.isSaving
          ? const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
      )
          : Text(
        'Save Prescription',
        style: Get.textTheme.titleMedium!.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: TColors.primary, size: 24),
        const SizedBox(width: TSizes.sm),
        Text(
          title,
          style: Get.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _savePrescription() async {
    // Validation logic...
    if (_doctorNameController.text.isEmpty) {
      Get.snackbar('Validation Error', 'Please enter the doctor\'s name.', snackPosition: SnackPosition.BOTTOM, backgroundColor: TColors.error, colorText: Colors.white, icon: const Icon(Iconsax.warning_2, color: Colors.white));
      return;
    }

    // Save prescription
    await _controller.savePrescriptionToFirebase(
      doctorName: _doctorNameController.text,
      clinicName: _clinicNameController.text,
      notes: _notesController.text,
      caregiverId: _selectedCaregiverId,
    );
  }

  void _removeMedication(String medicationId) {
    Get.defaultDialog(
      title: 'Remove Medication',
      middleText: 'Are you sure you want to permanently remove this medication from the list?',
      titleStyle: Get.textTheme.titleLarge?.copyWith(color: TColors.error, fontWeight: FontWeight.bold),
      middleTextStyle: Get.textTheme.bodyMedium,
      textConfirm: 'Yes, Remove',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: TColors.error,
      cancelTextColor: TColors.textSecondary,
      onConfirm: () {
        _controller.removeMedication(medicationId);
        _medicationTimings.remove(medicationId);
        Get.back();
      },
    );
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
