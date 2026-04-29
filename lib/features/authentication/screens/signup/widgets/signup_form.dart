import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mindheal/utils/constants/enums.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../../../utils/validators/validation.dart';
import '../../../controllers/signup_controller.dart';
import 'terms_conditions_checkbox.dart';

class TSignupForm extends StatelessWidget {
  const TSignupForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);
    final controller = Get.put(SignupController());
    return Form(
      key: controller.signupFormKey,
      child: Column(
        children: [
          const SizedBox(height: TSizes.spaceBtwSections),

          /// First & Last Name
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.firstName,
                  validator: (value) => TValidator.validateEmptyText('First name', value),
                  expands: false,
                  decoration: const InputDecoration(labelText: TTexts.firstName, prefixIcon: Icon(Iconsax.user)),
                ),
              ),
              const SizedBox(width: TSizes.spaceBtwInputFields),
              Expanded(
                child: TextFormField(
                  controller: controller.lastName,
                  validator: (value) => TValidator.validateEmptyText('Last name', value),
                  expands: false,
                  decoration: const InputDecoration(labelText: TTexts.lastName, prefixIcon: Icon(Iconsax.user)),
                ),
              ),
            ],
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Username
          TextFormField(
            controller: controller.username,
            validator: TValidator.validateUsername,
            expands: false,
            decoration: const InputDecoration(labelText: TTexts.username, prefixIcon: Icon(Iconsax.user_edit)),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Email
          TextFormField(
            controller: controller.email,
            validator: TValidator.validateEmail,
            decoration: const InputDecoration(labelText: TTexts.email, prefixIcon: Icon(Iconsax.direct)),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Phone Number
          TextFormField(
            cursorColor: TColors.primary,
            cursorHeight: TSizes.lg,
            style: Theme.of(context).textTheme.bodySmall,
            validator: (value) => TValidator.validatePhoneNumber(value),
            controller: controller.phoneNumber,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              fillColor: isDark ? TColors.dark : TColors.light,
              prefixIcon: CountryCodePicker(
                alignLeft: false,
                hideMainText: true,
                showCountryOnly: false,
                padding: EdgeInsets.zero,
                showDropDownButton: true,
                initialSelection: '+92',
                showOnlyCountryWhenClosed: false,
                headerText: TTexts.selectCountry,
                favorite: const ['+92'],
                onChanged: (value) => controller.selectedCountryCode.value = value.dialCode!,
                searchDecoration: InputDecoration(fillColor: isDark ? TColors.darkContainer : TColors.lightContainer),
                dialogBackgroundColor: isDark ? TColors.dark : TColors.light,
              ),
              hintText: TTexts.phoneNo,
              errorStyle: const TextStyle(color: TColors.error),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwInputFields),

          /// Select Role
          Obx(() => DropdownButtonFormField<AppRole>(
            value: controller.selectedRole.value,
            decoration: const InputDecoration(
              labelText: "Select Role",
              prefixIcon: Icon(Iconsax.shield3),
            ),
            items: const [
              DropdownMenuItem(
                value: AppRole.patient,
                child: Text("Patient"),
              ),
              DropdownMenuItem(
                value: AppRole.doctor,
                child: Text("Doctor"),
              ),
              DropdownMenuItem(
                value: AppRole.caregiver,
                child: Text("Caregiver"),
              ),
            ],
            onChanged: (value) {
              controller.selectedRole.value = value!;
            },
            validator: (value) =>
            value == null ? "Please select a role" : null,
          )),
          const SizedBox(height: TSizes.spaceBtwInputFields),


          /// Password
          Obx(
            () => TextFormField(
              controller: controller.password,
              validator: TValidator.validatePassword,
              obscureText: controller.hidePassword.value,
              decoration: InputDecoration(
                labelText: TTexts.password,
                prefixIcon: const Icon(Iconsax.password_check),
                suffixIcon: IconButton(
                  onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                  icon: const Icon(Iconsax.eye_slash),
                ),
              ),
            ),
          ),
          const SizedBox(height: TSizes.spaceBtwSections),

          /// Terms&Conditions Checkbox
          const TTermsAndConditionCheckbox(),
          const SizedBox(height: TSizes.spaceBtwSections),

          /// Sign Up Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () => controller.signup(), child: const Text(TTexts.createAccount)),
          ),
        ],
      ),
    );
  }
}
