import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/custom_shapes/containers/rounded_container.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class TLoginHeader extends StatelessWidget {
  const TLoginHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        Align(
          alignment: Alignment.topLeft,
          child: TRoundedContainer(
            padding: EdgeInsets.zero,
            backgroundColor: dark ? TColors.darkContainer : TColors.lightContainer,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
        ),

        const SizedBox(height: TSizes.spaceBtwItems),
        Image(
          height: 150,
          image: AssetImage(dark ? TImages.lightAppLogo : TImages.darkAppLogo),
        ),
        Text(TTexts.loginTitle, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TSizes.sm),
        Text(TTexts.loginSubTitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
