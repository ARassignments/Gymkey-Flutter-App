import 'package:flutter/material.dart';

class AvatarNotifier extends ValueNotifier<String?> {
  AvatarNotifier() : super(null);

  void updateAvatar(String avatar) {
    value = avatar;
  }
}

final avatarNotifier = AvatarNotifier();
