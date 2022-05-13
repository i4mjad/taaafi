import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:reboot_app_3/shared/constants/constants.dart';
import 'package:reboot_app_3/shared/constants/textstyles_constants.dart';

void newUserDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Iconsax.calendar,
                      color: primaryColor,
                      size: 40,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                'تابع تعافيك',
                style: kHeadlineStyle,
              ),
              Text(
                'حدد اليوم الذي ترغب ببدء المتابعة منه',
                style: kBodyStyle,
              ),
              TextField(
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter your username',
                ),
              ),
            ],
          ));
    },
  );
}
