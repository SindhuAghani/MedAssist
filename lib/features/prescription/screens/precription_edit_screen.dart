import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mindheal/common/widgets/custom_shapes/containers/t_container.dart';
import 'package:mindheal/features/prescription/controller/prescription_reader_controller.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/prescription/models/prescription_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/sizes.dart';
import 'package:mindheal/utils/constants/enums.dart';
import '../../personalization/models/user_model.dart';

class EditPrescriptionScreen extends StatefulWidget {
  const EditPrescriptionScreen({super.key});

  @override
  State<EditPrescriptionScreen> createState() => _EditPrescriptionScreenState();
}

class _EditPrescriptionScreenState extends State<EditPrescriptionScreen> {
  final PrescriptionReaderController _controller = Get.find<PrescriptionReaderController>();
  final UserController _userController = Get.find<UserController>();

  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _clinicNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _datePrescribedController = TextEditingController();
  final TextEditingController _validUntilController = TextEditingController();

  String? _selectedCaregiverId;
  DateTime? _selectedDatePrescribed;
  DateTime? _selectedValidUntil;

  @override
  void initState() {
    super.initState();
    _loadPrescriptionData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_userController.user.value.role.name == AppRole.patient.name) {
        _userController.loadAllCaregivers();
      } else {
        _userController.loadAllPatients();
      }
    });
  }

  void _loadPrescriptionData() {
    final prescription = _controller.editingPrescription;

    // Set text controllers
    _doctorNameController.text = prescription.doctorName;
    _clinicNameController.text = prescription.clinicName;
    _notesController.text = prescription.notes ?? '';
    _diagnosisController.text = prescription.diagnosis;

    // Set dates
    _selectedDatePrescribed = prescription.datePrescribed;
    _datePrescribedController.text = DateFormat('yyyy-MM-dd').format(prescription.datePrescribed);

    if (prescription.validUntil != null) {
      _selectedValidUntil = prescription.validUntil;
      _validUntilController.text = DateFormat('yyyy-MM-dd').format(prescription.validUntil!);
    }

    // Set caregiver
    _selectedCaregiverId = prescription.caregiverId.isNotEmpty ? prescription.caregiverId : null;
  }

  Future<void> _selectDate(BuildContext context, bool isDatePrescribed) async {
    final initialDate = isDatePrescribed ? _selectedDatePrescribed : _selectedValidUntil;
    final firstDate = isDatePrescribed ? DateTime(2000) : (_selectedDatePrescribed ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: DateTime(2100),
      helpText: isDatePrescribed ? 'Select Date Prescribed' : 'Select Valid Until Date',
    );

    if (picked != null) {
      setState(() {
        if (isDatePrescribed) {
          _selectedDatePrescribed = picked;
          _datePrescribedController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _selectedValidUntil = picked;
          _validUntilController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Prescription'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (moved to top of scrollable area)
            _buildHeader(),
            const SizedBox(height: TSizes.spaceBtwSections),

            // 1. General Details Section
            _buildExpansionTile(
              title: 'General Details',
              icon: Icons.assignment_ind,
              children: [_buildPrescriptionForm()],
              isInitiallyExpanded: true,
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // 2. Dates Section
            _buildExpansionTile(
              title: 'Dates and Validity',
              icon: Icons.date_range,
              children: [_buildDatesSection()],
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // 3. Medications List Section
            Obx(() => _buildExpansionTile(
              title: 'Medications (${_controller.extractedMedications.length} items)',
              icon: Icons.medical_services,
              children: [_buildMedicationsList()],
            )),
            const SizedBox(height: TSizes.spaceBtwItems),

            // 4. AI Analysis Section
            _buildExpansionTile(
              title: 'AI Analysis & Source Data',
              icon: Icons.auto_fix_high,
              children: [
                _buildSimplifiedTextSection(),
                const SizedBox(height: TSizes.spaceBtwSections),
                _buildExtractedTextSection(),
              ],
            ),
            const SizedBox(height: TSizes.spaceBtwSections * 2),
          ],
        ),
      ),
      // Update Button moved to fixed bottom bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: _buildUpdateButton(),
      ),
    );
  }

  /// Helper to create a standardized Expansion Tile for sections
  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isInitiallyExpanded = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
      ),
      child: ExpansionTile(
        initiallyExpanded: isInitiallyExpanded,
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
        leading: Icon(icon, color: TColors.primary),
        title: Text(
          title,
          style: Get.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, 0, TSizes.defaultSpace, TSizes.defaultSpace),
        children: children,
      ),
    );
  }

  Widget _buildHeader() {
    return TContainer(
      backgroundColor: TColors.lightContainer,
      borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
      padding: const EdgeInsets.all(TSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prescription ID: ${_controller.editingPrescription.id.substring(0, 8)}...',
            style: Get.textTheme.bodySmall?.copyWith(color: TColors.darkGrey),
          ),
          Text(
            'Review and Edit Details',
            style: Get.textTheme.headlineSmall,
          ),
          const SizedBox(height: TSizes.xs),
          Text(
            'Ensure all medication timings and caregiver assignments are accurate before saving.',
            style: Get.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: TSizes.md),
          Obx(() => _controller.isSaving
              ? const LinearProgressIndicator(color: TColors.primary)
              : const SizedBox()
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Doctor Name
        TextFormField(
          controller: _doctorNameController,
          decoration: const InputDecoration(
            labelText: 'Doctor Name*',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: TSizes.md),

        // Clinic Name
        TextFormField(
          controller: _clinicNameController,
          decoration: const InputDecoration(
            labelText: 'Clinic/Hospital*',
            prefixIcon: Icon(Icons.local_hospital),
          ),
        ),
        const SizedBox(height: TSizes.md),

        // Diagnosis (Optional)
        TextFormField(
          controller: _diagnosisController,
          decoration: const InputDecoration(
            labelText: 'Diagnosis (Optional)',
            prefixIcon: Icon(Icons.sick),
          ),
        ),
        const SizedBox(height: TSizes.md),

        // Notes (Optional)
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Prescription Notes (Optional)',
            prefixIcon: Icon(Icons.notes),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: TSizes.spaceBtwSections),

        // Caregiver Selection
        _buildCaregiverDropdown(),
      ],
    );
  }

  Widget _buildDatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _datePrescribedController,
                decoration: InputDecoration(
                  labelText: 'Date Prescribed*',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: () => _selectDate(context, true),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: TSizes.md),
            Expanded(
              child: TextFormField(
                controller: _validUntilController,
                decoration: InputDecoration(
                  labelText: 'Valid Until (Optional)',
                  prefixIcon: const Icon(Icons.event_available),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: () => _selectDate(context, false),
                  ),
                ),
                readOnly: true,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCaregiverDropdown() {
    return Obx(() {
      final isPatient = _userController.user.value.role.name == AppRole.patient.name;
      final label = isPatient ? 'Assign Caregiver (Optional)' : 'Patient (Required)';
      final users = isPatient ? _userController.allCaregivers.toList() : _userController.allPatients.toList();

      if ((isPatient && _userController.isLoadingCaregivers) || (!isPatient && _userController.isLoadingPatients)) {
        return const Center(child: CircularProgressIndicator());
      }

      final initialValue = isPatient ? (_selectedCaregiverId ?? 'no_selection') : (_selectedCaregiverId ?? _controller.editingPrescription.patientId);

      return _buildDropdown(
        label: label,
        items: users,
        initialValue: initialValue,
        isPatientSelecting: isPatient,
        onChanged: (value) {
          setState(() {
            // If patient is selecting caregiver, null means "no caregiver"
            // If caregiver is selecting patient, we must assign the selected patientId
            _selectedCaregiverId = value == 'no_selection' ? null : value;

            // If a caregiver is editing, and they change the patient, we update the patientId
            if (!isPatient && value != 'no_selection') {
              // The caregiver is assigning this prescription to a different patient.
              // In the current logic, _selectedCaregiverId is being used as the patientId when the user is a caregiver.
            }
          });
        },
      );
    });
  }

  Widget _buildDropdown({
    required String label,
    required List<UserModel> items,
    required String? initialValue,
    required ValueChanged<String?> onChanged,
    required bool isPatientSelecting,
  }) {
    // Determine the user model for the currently selected ID to display as hint/prefix
    final selectedUser = items.firstWhereOrNull((user) => user.id == initialValue);

    return DropdownButtonFormField<String>(
      value: initialValue == null || initialValue.isEmpty ? 'no_selection' : initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: selectedUser != null
            ? CircleAvatar(
          radius: 12,
          backgroundColor: TColors.primary.withOpacity(0.1),
          backgroundImage: selectedUser.profilePicture.isNotEmpty
              ? NetworkImage(selectedUser.profilePicture) as ImageProvider
              : null,
          child: selectedUser.profilePicture.isEmpty
              ? const Icon(Icons.person, size: 16, color: TColors.primary)
              : null,
        )
            : const Icon(Icons.family_restroom),
        helperText: isPatientSelecting ? 'Select a caregiver to manage medication reminders.' : 'Select the patient this prescription belongs to.',
      ),
      isExpanded: true,
      items: [
        DropdownMenuItem(
          value: 'no_selection',
          child: Text(isPatientSelecting ? 'No Caregiver Assigned' : 'Select Patient', style: const TextStyle(color: Colors.grey)),
        ),
        ...items.map((user) => DropdownMenuItem(
          value: user.id,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: TColors.primary.withOpacity(0.1),
                backgroundImage: user.profilePicture.isNotEmpty
                    ? NetworkImage(user.profilePicture) as ImageProvider
                    : null,
                child: user.profilePicture.isEmpty
                    ? const Icon(Icons.person, size: 16, color: TColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(user.fullName, overflow: TextOverflow.ellipsis)),
              if (user.verificationStatus == VerificationStatus.approved)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.verified, color: Colors.green, size: 16),
                ),
            ],
          ),
        )).toList(),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildExtractedTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.document_scanner, color: Colors.blue),
            const SizedBox(width: TSizes.sm),
            Text(
              'Extracted Text (OCR)',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.md),
        TContainer(
          padding: const EdgeInsets.all(TSizes.md),
          backgroundColor: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          border: Border.all(color: Colors.blue.withOpacity(0.2)),
          child: Obx(() => SelectableText(
            _controller.extractedText,
            style: Get.textTheme.bodyMedium,
          )),
        ),
      ],
    );
  }

  Widget _buildSimplifiedTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.health_and_safety, color: TColors.success),
            const SizedBox(width: TSizes.sm),
            Text(
              'Simplified Explanation (AI)',
              style: Get.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: TSizes.md),
        TContainer(
          padding: const EdgeInsets.all(TSizes.md),
          backgroundColor: TColors.success.withOpacity(0.05),
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
          border: Border.all(color: TColors.success.withOpacity(0.2)),
          child: Obx(() => SelectableText(
            _controller.simplifiedText,
            style: Get.textTheme.bodyMedium?.copyWith(
              color: TColors.success,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildMedicationsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add Medication Button (moved inside the section)
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _addMedication,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Medication'),
          ),
        ),
        const SizedBox(height: TSizes.md),

        // Medications List
        Obx(() => ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _controller.extractedMedications.length,
          itemBuilder: (context, index) {
            final medication = _controller.extractedMedications[index];
            return _buildMedicationCard(medication, index);
          },
        )),
      ],
    );
  }

  Widget _buildMedicationCard(Medication medication, int index) {
    // Using an ExpansionTile inside the card for cleaner details management
    return Card(
      margin: const EdgeInsets.only(bottom: TSizes.sm),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        side: const BorderSide(color: TColors.softGrey, width: 1),
      ),
      child: ExpansionTile(
        title: Text(
          medication.name,
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: TColors.dark,
          ),
        ),
        subtitle: medication.genericName.isNotEmpty
            ? Text(medication.genericName, style: Get.textTheme.bodySmall)
            : null,
        leading: CircleAvatar(
          backgroundColor: TColors.info.withOpacity(0.1),
          child: Text('${index + 1}', style: Get.textTheme.titleSmall?.copyWith(color: TColors.info)),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: TColors.secondary, size: 20),
              onPressed: () => _editMedication(medication),
              tooltip: 'Edit Details',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: TColors.error, size: 20),
              onPressed: () => _removeMedication(medication.id),
              tooltip: 'Remove Medication',
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(TSizes.defaultSpace, 0, TSizes.defaultSpace, TSizes.defaultSpace),
        children: [
          const Divider(height: 1, color: TColors.softGrey),
          const SizedBox(height: TSizes.md),

          // Dosage, Frequency, Duration
          Wrap(
            spacing: TSizes.sm,
            runSpacing: TSizes.sm,
            children: [
              _buildDetailChip(medication.dosage, Icons.medication_outlined),
              _buildDetailChip(medication.frequency, Icons.repeat),
              _buildDetailChip(medication.duration, Icons.calendar_month),
            ],
          ),
          const SizedBox(height: TSizes.md),

          // Timings Selection
          _buildTimingsSelector(medication),
          const SizedBox(height: TSizes.md),

          // Instructions
          if (medication.instructions?.isNotEmpty == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional Instructions:',
                  style: Get.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: TColors.darkGrey,
                  ),
                ),
                Text(
                  medication.instructions!,
                  style: Get.textTheme.bodySmall,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 14, color: TColors.primary),
      label: Text(text),
      backgroundColor: TColors.softGrey,
      labelStyle: Get.textTheme.labelSmall?.copyWith(color: TColors.darkGrey, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _buildTimingsSelector(Medication medication) {
    // Get the current list of timings from the controller (which handles the state)
    final timings = _controller.extractedMedications.firstWhere((m) => m.id == medication.id).timings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set Daily Intake Times:',
          style: Get.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: TColors.dark,
          ),
        ),
        const SizedBox(height: TSizes.xs),
        Wrap(
          spacing: TSizes.xs,
          runSpacing: TSizes.xs,
          children: [
            ..._getTimeSlots().map((time) {
              final isSelected = timings.contains(time);
              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                selectedColor: TColors.primary.withOpacity(0.8),
                backgroundColor: TColors.softGrey,
                labelStyle: Get.textTheme.labelSmall?.copyWith(
                  color: isSelected ? TColors.white : TColors.darkGrey,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (selected) {
                  // Create a modifiable list copy
                  final updatedTimings = List<String>.from(timings);
                  if (selected) {
                    updatedTimings.add(time);
                  } else {
                    updatedTimings.remove(time);
                  }
                  // Update the RxList in the controller, which triggers re-rendering
                  _controller.updateMedicationTiming(medication.id, updatedTimings);
                },
              );
            }).toList(),
          ],
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


  Widget _buildUpdateButton() {
    return Obx(() => _controller.isSaving
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton.icon(
      onPressed: _updatePrescription,
      icon: const Icon(Icons.save, color: TColors.white),
      label: const Text('Update Prescription'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        backgroundColor: TColors.primary,
        foregroundColor: TColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
      ),
    ),
    );
  }

  void _updatePrescription() async {
    // Basic validation check
    if (_doctorNameController.text.isEmpty || _clinicNameController.text.isEmpty || _datePrescribedController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Doctor Name, Clinic Name, and Date Prescribed are required.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: TColors.error,
        colorText: TColors.white,
      );
      return;
    }

    if (_controller.extractedMedications.isEmpty) {
      Get.snackbar(
        'Error',
        'Prescription must contain at least one medication.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: TColors.error,
        colorText: TColors.white,
      );
      return;
    }

    // Update prescription
    await _controller.updatePrescriptionInFirebase(
      doctorName: _doctorNameController.text,
      clinicName: _clinicNameController.text,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      caregiverId: _selectedCaregiverId,
      datePrescribed: _selectedDatePrescribed,
      validUntil: _selectedValidUntil,
      diagnosis: _diagnosisController.text,
    );
  }

  void _addMedication() {
    Get.snackbar(
      'Coming Soon',
      'Advanced features for manually adding and customizing medications are under development. Please edit the extracted list for now.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: TColors.warning,
      colorText: TColors.dark,
    );
  }

  void _editMedication(Medication medication) {
    Get.snackbar(
      'Coming Soon',
      'Advanced features for manually editing medication details are under development. Please use the timing selector and remove/re-add if major data changes are needed.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: TColors.warning,
      colorText: TColors.dark,
    );
  }

  void _removeMedication(String medicationId) {
    Get.defaultDialog(
      title: 'Remove Medication',
      middleText: 'Are you sure you want to remove this medication?',
      textConfirm: 'Yes, Remove',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () {
        _controller.removeMedication(medicationId);
        Get.back();
      },
    );
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _notesController.dispose();
    _diagnosisController.dispose();
    _datePrescribedController.dispose();
    _validUntilController.dispose();
    super.dispose();
  }
}