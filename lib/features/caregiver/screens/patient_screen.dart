import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindheal/data/repositories/authentication/authentication_repository.dart';
import 'package:mindheal/features/personalization/controllers/user_controller.dart';
import 'package:mindheal/features/personalization/models/user_model.dart';
import 'package:mindheal/utils/constants/colors.dart';
import 'package:mindheal/utils/constants/sizes.dart';

import '../controller/caregiver_controller.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({Key? key}) : super(key: key);

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final UserController userController = Get.find();
  final CaregiverController caregiverController = Get.find();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userController.loadAllPatients();  // ⬅ Load patients on screen open
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Patient'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TSizes.defaultSpace),
        child: Column(
          children: [
            // 🔍 Search Bar
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TSizes.cardRadiusLg),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // Refresh list as user types
              },
            ),

            const SizedBox(height: TSizes.spaceBtwSections),

            // 🩺 All Patients List
            Obx(() {
              if (userController.isLoadingPatients) {
                return const Center(child: CircularProgressIndicator());
              }

              if(caregiverController.isLoading){
                return const Center(child: CircularProgressIndicator());
              }

              if (userController.errorMessage.isNotEmpty) {
                return Center(
                  child: Text(
                    userController.errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              List<UserModel> patients = userController.allPatients.where((patient) => !patient.caregiverIds!.contains(AuthenticationRepository.instance.getUserID)).toList();

              // Filter by search text
              String query = searchController.text.toLowerCase();
              if (query.isNotEmpty) {
                patients = patients.where((p) {
                  return p.fullName.toLowerCase().contains(query) ||
                      p.email.toLowerCase().contains(query) && p.caregiverIds!.contains(AuthenticationRepository.instance.getUserID) ;
                }).toList();
              }

              if (patients.isEmpty) {
                return const Center(
                  child: Text('No patients found.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: TSizes.sm),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(patient.fullName),
                      subtitle: Text(patient.email),
                      trailing: ElevatedButton(
                        onPressed: () => _addPatient(patient.id),
                        child: const Text('Add'),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ➕ Add Patient to Caregiver List
  void _addPatient(String patientId) async {
    try {
      final UserModel patient = await userController.getUserData(patientId);
      await caregiverController.addPatient(patient);
      await caregiverController.refreshData();
      Get.back();

      Get.snackbar(
        "Success",
        "${patient.fullName} added successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
