import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../repository/user_admin_repository.dart';
import '../viewmodel/admin_viewmodel.dart';
import '../viewmodel/auth_viewmodel.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  static String _label(UserRole r) => switch (r) {
    UserRole.public => 'Public',
    UserRole.healthOfficer => 'Health officer',
    UserRole.admin => 'Admin',
  };

  Future<void> _change(
      BuildContext context, AdminViewModel vm, UserModel target, UserRole newRole) async {
    final adminId = context.read<AuthViewModel>().currentUser?.id;
    if (adminId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change role?'),
        content: Text('${target.name} (${target.email})\n'
            '${_label(target.role)}  →  ${_label(newRole)}\n\n'
            'This is recorded in the audit trail. The user must log in again '
            'for the new role to take effect.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await vm.setRole(adminId: adminId, target: target, newRole: newRole);
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(success
          ? '${target.name} is now ${_label(newRole)}'
          : (vm.errorMessage ?? 'Could not change the role')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final myId = context.read<AuthViewModel>().currentUser?.id;

    return ChangeNotifierProvider(
      create: (ctx) => AdminViewModel(ctx.read<UserAdminRepository>())..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Manage Users')),
        body: Consumer<AdminViewModel>(
          builder: (context, vm, _) {
            if (vm.isLoading) return const Center(child: CircularProgressIndicator());
            if (vm.errorMessage != null && vm.users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vm.errorMessage!),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: vm.load, child: const Text('Try again')),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    onChanged: vm.setQuery,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: vm.users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final u = vm.users[i];
                      final isMe = u.id == myId;
                      return ListTile(
                        leading: Icon(
                          switch (u.role) {
                            UserRole.admin => Icons.admin_panel_settings,
                            UserRole.healthOfficer => Icons.medical_services,
                            UserRole.public => Icons.person,
                          },
                          color: AppColors.primary,
                        ),
                        title: Text(isMe ? '${u.name} (you)' : u.name),
                        subtitle: Text('${u.email}\n${_label(u.role)}'),
                        isThreeLine: true,
                        trailing: isMe
                            ? null
                            : PopupMenuButton<UserRole>(
                          tooltip: 'Change role',
                          onSelected: (r) => _change(context, vm, u, r),
                          itemBuilder: (_) => [
                            for (final r in UserRole.values)
                              if (r != u.role)
                                PopupMenuItem(value: r, child: Text('Make ${_label(r)}')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}