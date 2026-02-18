import 'package:flutter/material.dart';

enum Spacing {
  points4(4),
  points8(8),
  points12(12),
  points16(16),
  points20(20),
  points24(24),
  points28(28),
  points32(32),
  points36(36),
  points40(40),
  points44(44),
  points48(48),
  points52(52),
  points56(56),
  points60(60),
  points64(64),
  points68(68),
  points72(72),
  points76(76),
  points80(80);

  final double value;

  const Spacing(this.value);
}

SizedBox verticalSpace(Spacing height) => SizedBox(
      height: height.value,
    );

SizedBox horizontalSpace(Spacing width) => SizedBox(
      width: width.value,
    );
