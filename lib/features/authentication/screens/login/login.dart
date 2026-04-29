import 'package:flutter/material.dart';

import '../../../../common/styles/spacing_styles.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Column(
            children: [
              ///  Header
              TLoginHeader(),

              /// Form
              TLoginForm(),

              /// Divider
              // TFormDivider(dividerText: TTexts.orSignInWith.capitalize!),
              // const SizedBox(height: TSizes.spaceBtwSections),

              /// Footer
              //const TSocialButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
