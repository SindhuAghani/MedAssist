import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/routes/routes.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/constants/image_strings.dart';
import 'package:mindheal/utils/constants/sizes.dart';

class TCircularIcon extends StatelessWidget {
  const TCircularIcon({super.key, required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.blueGrey.shade700),
      onPressed: onPressed,
    );
  }
}

// A simple card widget to match the design style
class QuickCheckInCard extends StatelessWidget {
  const QuickCheckInCard({super.key, required this.icon, required this.iconColor, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: TSizes.spaceBtwItems),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge!.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// --- End of Placeholder ---

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Set the background color to match the top blur/gradient
        backgroundColor: Colors.transparent, // Making AppBar transparent
        elevation: 0,
        toolbarHeight: 0, // Hiding the default app bar space
      ),
      body: Stack(
        children: [
          // 1. Background Blur/Gradient Effect (Top Half)
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50.withOpacity(0.8), // Lightest blue/white
                  Colors.blue.shade100.withOpacity(0.5), // Slightly darker blue
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 2. Main Content Scroll View
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom AppBar/Header Area
                _buildCustomHeader(context),
                const SizedBox(height: TSizes.defaultSpace),

                // Welcome Section
                _buildWelcomeBanner(context),
                const SizedBox(height: TSizes.spaceBtwSections),

                // Quick Check-In Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Check-In?',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: TSizes.spaceBtwItems),
                      _buildQuickCheckInCards(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Matches the top bar look
  Widget _buildCustomHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: TSizes.defaultSpace, right: TSizes.defaultSpace, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "MedAssit AI",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700, // Matching the app name color
            ),
          ),
          // User Profile Picture
          Obx(() {
            if (UserController.instance.user.value.profilePicture.isEmpty) {
              [
                GestureDetector(
                  onTap: () => Get.toNamed(TRoutes.userProfile),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: NetworkImage(UserController.instance.user.value.profilePicture),
                  ),
                ),
              ];
            }
            return GestureDetector(
              onTap: () => Get.toNamed(TRoutes.userProfile),
              child: CircleAvatar(radius: 20, backgroundColor: Colors.grey.shade300, backgroundImage: AssetImage(TImages.user)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Text(
              'Hi, ${UserController.instance.user.value.fullName} 👋',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Colors.black87, fontWeight: FontWeight.w600),
            ).animate().fade().slideY(duration: 500.ms),
          ),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Text(
            'Welcome \nto MedAssit AI', // Notice the line break in the design
            style: Theme.of(context).textTheme.displaySmall!.copyWith(fontWeight: FontWeight.bold, color: Colors.black, height: 1.1),
          ).animate().fade().slideY(duration: 500.ms, delay: 100.ms),
          const SizedBox(height: TSizes.spaceBtwItems / 2),
          Text(
            'Let\'s work on your wellness journey together',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Colors.grey.shade700),
          ).animate().fade().slideY(duration: 500.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildQuickCheckInCards(BuildContext context) {
    const String scannedPrescription = 'Scan your prescription and get simple explanations instantly.';
    const String myMedication = 'Track your medicines with easy reminders and instructions.';
    final role = UserController.instance.user.value.role;
    final testReportsTitle = role.name == AppRole.doctor.name ? 'Create Test Reports' : 'My Test Reports';
    final testReportsSubtitle = role.name == AppRole.doctor.name
        ? 'Create structured patient reports, upload files, and build chart-friendly results.'
        : 'Review your saved test reports and see trends over time.';

    return Column(
      children: [
        QuickCheckInCard(
          icon: Iconsax.scan_barcode,
          // Use an icon similar to the design
          iconColor: Colors.amber.shade700,
          // Yellow/Orange tint
          title: 'Scan Prescription',
          subtitle: scannedPrescription,
          onTap: () => Get.toNamed(TRoutes.prescriptionReader),
        ).animate().fade(duration: 500.ms, delay: 300.ms),
        const SizedBox(height: TSizes.spaceBtwItems),
        QuickCheckInCard(
          icon: Iconsax.hospital,
          iconColor: Colors.red.shade400,
          // Red tint
          title: 'My Medication',
          subtitle: myMedication,
          onTap: () => Get.toNamed(TRoutes.patientMedications),
        ).animate().fade(duration: 500.ms, delay: 400.ms),
        const SizedBox(height: TSizes.spaceBtwItems),
        QuickCheckInCard(
          icon: Iconsax.document_text,
          iconColor: Colors.green.shade500,
          // Green tint
          title: testReportsTitle,
          subtitle: testReportsSubtitle,
          onTap: () => Get.toNamed(TRoutes.testReportList),
        ).animate().fade(duration: 500.ms, delay: 500.ms),
      ],
    );
  }
}
