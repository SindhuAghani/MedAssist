import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart'; // Added Iconsax for modern icons
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mindheal/common/widgets/custom_shapes/containers/t_container.dart';
import 'package:mindheal/features/prescription/controller/prescription_reader_controller.dart';

import '../../../utils/constants/sizes.dart'; // Added for subtle entrance animation


class PrescriptionReaderScreen extends StatelessWidget {
  PrescriptionReaderScreen({super.key});

  // Keep the original controller initialization
  final PrescriptionReaderController _controller = Get.put(PrescriptionReaderController());

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
          'Scan Prescription',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section
              _buildHeaderSection().animate().fade().slideY(duration: 500.ms),
              const SizedBox(height: TSizes.spaceBtwSections),

              // Image Preview Section (Styled as a prominent TContainer Card)
              _buildImagePreviewSection().animate().fade(delay: 100.ms),
              const SizedBox(height: TSizes.spaceBtwSections),

              // Action Buttons
              _buildActionButtons().animate().fade(delay: 200.ms),
              const SizedBox(height: TSizes.spaceBtwItems),

              // Processing Indicator
              Obx(() => _controller.isProcessing
                  ? _buildProcessingIndicator()
                  : const SizedBox()),

              // Error Message
              Obx(() => _controller.errorMessage.isNotEmpty
                  ? _buildErrorMessage()
                  : const SizedBox()),

              const SizedBox(height: TSizes.spaceBtwSections),

              // Tips Section (Styled as a distinct TContainer Card)
              _buildTipsSection().animate().fade(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Take a clear photo of your prescription. Ensure good lighting and focus.',
          style: Get.textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade600, // Use a modern grey tone
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewSection() {
    return Obx(() {
      if (_controller.prescriptionImage == null) {
        // --- Stylized Placeholder Card (No Image Selected) ---
        return TContainer(
          backgroundColor: Colors.blue.shade50.withOpacity(0.5), // Lighter background
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade300, width: 2),
                    color: Colors.blue.shade100,
                  ),
                  child: Icon(Iconsax.camera, size: 40, color: Colors.blue.shade600),
                ),
                const SizedBox(height: TSizes.spaceBtwItems),
                Text(
                  'Tap to scan prescription',
                  style: Get.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  'or',
                  style: Get.textTheme.labelLarge,
                ),
                const SizedBox(height: TSizes.spaceBtwItems / 2),
                Text(
                  'Choose from gallery',
                  style: Get.textTheme.bodyLarge!.copyWith(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // --- Image Preview (Image Selected) ---
        return Stack(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                child: Image.file(
                  _controller.prescriptionImage!, // Use .value for Obx
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.white),
                  onPressed: _controller.clearData,
                ),
              ),
            ),
          ],
        );
      }
    });
  }

  Widget _buildActionButtons() {
    return Obx(() {
      if (_controller.prescriptionImage == null) {
        // --- Buttons for No Image Selected State ---
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _controller.pickImageFromCamera(),
                icon: const Icon(Iconsax.camera), // Use Iconsax
                label: const Text('Open Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600, // Solid blue primary
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  ),
                  textStyle: Get.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _controller.pickImageFromGallery(),
                icon: const Icon(Iconsax.gallery, color: Colors.blue), // Use Iconsax
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  ),
                  side: BorderSide(color: Colors.blue.shade200),
                  textStyle: Get.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      } else {
        // --- Buttons for Image Selected State ---
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _controller.retryProcessing,
                icon: const Icon(Iconsax.refresh), // Use Iconsax
                label: const Text('Rescan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange.shade600, // High-contrast retry color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  ),
                  textStyle: Get.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _controller.pickImageFromCamera(),
                icon: const Icon(Iconsax.camera), // Use Iconsax
                label: const Text('New Photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
                  ),
                  side: BorderSide(color: Colors.blue.shade200),
                  textStyle: Get.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      }
    });
  }

  Widget _buildProcessingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBtwItems),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          Text(
            'Processing prescription...',
            style: Get.textTheme.bodyLarge?.copyWith(
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: TSizes.spaceBtwItems),
      child: TContainer(
        backgroundColor: Colors.red.shade50,
        padding: const EdgeInsets.all(TSizes.spaceBtwItems),
        child: Row(
          children: [
            Icon(Iconsax.danger, color: Colors.red.shade600), // Use Iconsax
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: Text(
                _controller.errorMessage, // Use .value
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return TContainer(
      backgroundColor: Colors.blue.shade50, // Light blue background for emphasis
      padding: const EdgeInsets.all(TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.lamp, size: 24, color: Colors.amber.shade700),
              const SizedBox(width: TSizes.spaceBtwItems / 2),
              Text(
                'Tips for better results:',
                style: Get.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwItems),
          _buildTipItem('Ensure good lighting'),
          _buildTipItem('Keep the prescription flat'),
          _buildTipItem('Avoid shadows and glare', isWarning: true), // Added differentiation
          _buildTipItem('Focus on clear, readable text'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, {bool isWarning = false}) {
    Color iconColor = isWarning ? Colors.red.shade600 : Colors.green.shade600;
    IconData icon = isWarning ? Iconsax.close_circle : Iconsax.check;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: TSizes.spaceBtwItems),
          Expanded(
            child: Text(
              text,
              style: Get.textTheme.bodyMedium!.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TSizes.borderRadiusLg)),
        title: Text('Select Source', style: Get.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold)),
        content: Text('Choose where to get the prescription image', style: Get.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _controller.pickImageFromCamera();
            },
            child: Text('Camera', style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _controller.pickImageFromGallery();
            },
            child: Text('Gallery', style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}