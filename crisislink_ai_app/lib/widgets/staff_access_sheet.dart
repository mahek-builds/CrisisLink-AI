import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum StaffRole { responder, admin }

class StaffAccessSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF14151C).withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: const Color(0xFFA9A3AD),
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Staff Access',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  color: const Color(0xFFA9A3AD),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstCurve: Curves.easeOut,
            secondCurve: Curves.easeOut,
            sizeCurve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 240),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(height: 10),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.shield_outlined,
                        label: 'Responder',
                        selected: selectedRole == StaffRole.responder,
                        onTap: () => onRoleChanged(StaffRole.responder),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Admin',
                        selected: selectedRole == StaffRole.admin,
                        onTap: () => onRoleChanged(StaffRole.admin),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Staff ID',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const TextField(
                  decoration: InputDecoration(hintText: 'Enter your ID'),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Password',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(hintText: 'Enter password'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF50515C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Login as Staff',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    selectedRole == StaffRole.admin
                        ? 'Demo: admin/admin'
                        : 'Demo: resp/resp',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.accentRed.withValues(alpha: 0.6)
                : const Color(0xFF454050),
          ),
          gradient: LinearGradient(
            colors: selected
                ? [
                    const Color(0xFF3A151B),
                    const Color(0xFF241820),
                  ]
                : [
                    const Color(0xFF231E27),
                    const Color(0xFF1A1920),
                  ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFFD4D2D7),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
