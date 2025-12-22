
import 'package:flutter/material.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';

class AccountManagement extends ScopedScreen {
  const AccountManagement({super.key});

  @override
  State<AccountManagement> createState() => _AccountManagementState();
}

class _AccountManagementState extends ScopedScreenState<AccountManagement>{
  @override
  void onReady() {
    // Maybe configure layout here if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Management'),
      ),
      body: const Center(
        child: Text('Account Management Screen Content'),
      ),
    );
  }
}