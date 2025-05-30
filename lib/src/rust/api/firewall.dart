// This file is automatically generated, so please do not edit it.
// @generated by `flutter_rust_bridge`@ 2.10.0.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

Future<bool> getFirewallStatus({required int profileIndex}) => RustLib
    .instance
    .api
    .crateApiFirewallGetFirewallStatus(profileIndex: profileIndex);

Future<void> setFirewallStatus({
  required int profileIndex,
  required bool enable,
}) => RustLib.instance.api.crateApiFirewallSetFirewallStatus(
  profileIndex: profileIndex,
  enable: enable,
);
