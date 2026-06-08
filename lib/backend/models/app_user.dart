import 'package:flutter/foundation.dart';

@immutable
class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  @override
  bool operator ==(Object other) => other is AppUser && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}
