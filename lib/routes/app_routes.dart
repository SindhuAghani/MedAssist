
import 'package:get/get.dart';
import 'package:mindheal/features/caregiver/screens/medication_schedule_screen.dart';
import 'package:mindheal/features/medication/controller/medication_schedule_controller.dart';
import 'package:mindheal/features/prescription/screens/prescription_reader_screen.dart';
import 'package:mindheal/features/test_reports/controller/test_report_analytics_controller.dart';
import 'package:mindheal/features/test_reports/controller/test_report_detail_controller.dart';
import 'package:mindheal/features/test_reports/controller/test_report_form_controller.dart';
import 'package:mindheal/features/test_reports/controller/test_report_list_controller.dart';
import 'package:mindheal/features/test_reports/screens/test_report_analytics_screen.dart';
import 'package:mindheal/features/test_reports/screens/test_report_detail_screen.dart';
import 'package:mindheal/features/test_reports/screens/test_report_form_screen.dart';
import 'package:mindheal/features/test_reports/screens/test_report_list_screen.dart';
import 'package:mindheal/features/authentication/screens/login/login.dart';
import 'package:mindheal/features/authentication/screens/onboarding/onboarding.dart';
import 'package:mindheal/features/authentication/screens/password_configuration/forget_password.dart';
import 'package:mindheal/features/authentication/screens/signup/signup.dart';
import 'package:mindheal/features/authentication/screens/signup/verify_email.dart';
import 'package:mindheal/features/prescription/screens/prescription_detail_screen.dart';
import 'package:mindheal/features/prescription/screens/prescription_medication_screen.dart';
import '../features/Home/home_page.dart';
import '../features/prescription/controller/prescription_reader_controller.dart';
import '../features/prescription/screens/prescription_result_screen.dart';
import '../features/personalization/screens/profile/profile.dart';
import 'routes.dart';

class AppRoutes {
  static final pages = [
    GetPage(name: TRoutes.userProfile, page: () => const ProfileScreen()),
    GetPage(name: TRoutes.signup, page: () => const SignupScreen(),),
    GetPage(name: TRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(name: TRoutes.logIn, page: () => const LoginScreen()),
    GetPage(name: TRoutes.forgetPassword, page: () => const ForgetPasswordScreen()),
    GetPage(name: TRoutes.onBoarding, page: () => const OnBoardingScreen()),
    GetPage(name: TRoutes.home, page: () => HomePage()),

    GetPage(
      name: TRoutes.prescriptionReader,
      page: () => PrescriptionReaderScreen(),
      binding: BindingsBuilder(() {
        Get.put(PrescriptionReaderController());
      }),
    ),
    GetPage(
      name: TRoutes.prescriptionResults,
      page: () => PrescriptionResultsScreen(),
    ),
    GetPage(
      name: TRoutes.patientMedications,
      page: () => PatientMedicationsScreen(),
    ),
    GetPage(
      name: TRoutes.prescriptionDetails,
      page: () => PrescriptionDetailsScreen(),
    ),
    GetPage(
      name: TRoutes.medicationSchedule,
      page: () => MedicationScheduleScreen(),
      binding: BindingsBuilder(() {
        Get.put(MedicationScheduleController());
      }),
    ),
    GetPage(
      name: TRoutes.testReportForm,
      page: () => const TestReportFormScreen(),
      binding: BindingsBuilder(() {
        Get.put(TestReportFormController());
      }),
    ),
    GetPage(
      name: TRoutes.testReportList,
      page: () => const TestReportListScreen(),
      binding: BindingsBuilder(() {
        Get.put(TestReportListController());
      }),
    ),
    GetPage(
      name: TRoutes.testReportDetail,
      page: () => const TestReportDetailScreen(),
      binding: BindingsBuilder(() {
        Get.put(TestReportDetailController());
      }),
    ),
    GetPage(
      name: TRoutes.testReportAnalytics,
      page: () => const TestReportAnalyticsScreen(),
      binding: BindingsBuilder(() {
        Get.put(TestReportAnalyticsController());
      }),
    ),
  ];
}
