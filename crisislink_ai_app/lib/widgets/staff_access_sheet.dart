import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StaffRole { responder, admin }

class StaffAccessSheet extends StatefulWidget {
  const StaffAccessSheet({
    super.key,
    required this.expanded,
    required this.selectedRole,
    required this.onToggle,
    required this.onRoleChanged,
  });

  final bool expanded;
  final StaffRole selectedRole;
  final VoidCallback onToggle;
  final ValueChanged<StaffRole> onRoleChanged;

  @override
  State<StaffAccessSheet> createState() => _StaffAccessSheetState();
}

class _StaffAccessSheetState extends State<StaffAccessSheet> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final id = _idController.text.trim();
    final password = _passwordController.text.trim();
    final expectsAdmin = widget.selectedRole == StaffRole.admin;
    final isValid = expectsAdmin
        ? id == 'admin' && password == 'admin'
        : id == 'resp' && password == 'resp';

    final messenger = ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar();

    if (id.isEmpty || password.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter your staff ID and password.')),
      );
      return;
    }

    if (!isValid) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            expectsAdmin
                ? 'Invalid admin credentials. Try admin / admin.'
                : 'Invalid responder credentials. Try resp / resp.',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          expectsAdmin
              ? 'Admin access verified.'
              : 'Responder access verified.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isExpanded = widget.expanded;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 540,
            minHeight: isExpanded ? 368 : 70,
            maxHeight: isExpanded ? 368 : 70,
          ),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF171A23).withValues(alpha: 0.94),
                const Color(0xFF0C0E14).withValues(alpha: 0.98),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: widget.onToggle,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6F7586),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF1D2330),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.admin_panel_settings_rounded,
                                      color: Color(0xFFEEF2F7),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Staff Access',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Responder and admin sign-in',
                                          style: TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_up_rounded,
                                    color: const Color(0xFFC7CCD4),
                                    size: 28,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: IgnorePointer(
                          ignoring: !isExpanded,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: isExpanded ? 1 : 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _RoleCard(
                                        selected: widget.selectedRole ==
                                            StaffRole.responder,
                                        title: 'Responder',
                                        subtitle: 'Dispatch access',
                                        icon: Icons.shield_outlined,
                                        activeColor: const Color(0xFF2F6BFF),
                                        onTap: () => widget.onRoleChanged(
                                          StaffRole.responder,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _RoleCard(
                                        selected:
                                            widget.selectedRole == StaffRole.admin,
                                        title: 'Admin',
                                        subtitle: 'Control room',
                                        icon: Icons.manage_accounts_rounded,
                                        activeColor: const Color(0xFF875CFF),
                                        onTap: () =>
                                            widget.onRoleChanged(StaffRole.admin),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _idController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Staff ID',
                                    hintText: 'Enter your ID',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  onSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter password',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppTheme.accentRed,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      widget.selectedRole == StaffRole.admin
                                          ? 'Login as Admin'
                                          : 'Login as Responder',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    widget.selectedRole == StaffRole.admin
                                        ? 'Demo: admin / admin'
                                        : 'Demo: resp / resp',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.activeColor,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.08),
          ),
          color: selected
              ? activeColor.withValues(alpha: 0.14)
              : const Color(0xFF151924),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? activeColor.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                icon,
                color: selected ? activeColor : const Color(0xFFD7DBE4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
