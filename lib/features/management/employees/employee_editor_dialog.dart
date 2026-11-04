import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';

class EmployeeEditorDialog extends StatefulWidget {
  const EmployeeEditorDialog({super.key, required this.data, this.employee});
  final MockDataService data;
  final Employee? employee;
  @override
  State<EmployeeEditorDialog> createState() => _EmployeeEditorDialogState();
}

class _EmployeeEditorDialogState extends State<EmployeeEditorDialog> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, code, email, phone;
  int? role, branch;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    name = TextEditingController(text: e?.fullName);
    code = TextEditingController(text: e?.employeeCode);
    email = TextEditingController(text: e?.email);
    phone = TextEditingController(text: e?.phone);
    role =
        e?.roleId ??
        widget.data.roles
            .where((r) => r.roleCode == 'EMPLOYEE')
            .firstOrNull
            ?.roleId;
    branch =
        e?.branchId ??
        (widget.data.currentBranch.branchId == 0
            ? null
            : widget.data.currentBranch.branchId);
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  String? requiredText(String? v) =>
      v == null || v.trim().isEmpty ? 'Vui lòng nhập thông tin này.' : null;
  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final emp = Employee(
        employeeId: widget.employee?.employeeId ?? 0,
        roleId: role!,
        branchId: branch!,
        employeeCode: code.text.trim().toUpperCase(),
        fullName: name.text.trim(),
        email: email.text.trim().toLowerCase(),
        phone: phone.text.trim(),
        employmentStatus: widget.employee?.employmentStatus ?? 'ACTIVE',
      );
      if (widget.employee == null) {
        await widget.data.addEmployee(emp);
      } else {
        await widget.data.updateEmployee(emp);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final roles = data.roles
        .where(
          (r) =>
              !data.isRemote ||
              data.currentRoleCode == 'ADMIN' ||
              r.roleCode == 'EMPLOYEE',
        )
        .toList();
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: Text(
          widget.employee == null ? 'Thêm nhân viên' : 'Cập nhật nhân viên',
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin nhân sự',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    enabled: !saving,
                    maxLength: 150,
                    textCapitalization: TextCapitalization.words,
                    validator: requiredText,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: code,
                    enabled: !saving,
                    maxLength: 30,
                    validator: (v) =>
                        requiredText(v) ??
                        (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(v!.trim())
                            ? null
                            : 'Chỉ dùng chữ, số, dấu gạch ngang hoặc gạch dưới.'),
                    decoration: const InputDecoration(
                      labelText: 'Mã nhân viên *',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: email,
                    enabled: !saving,
                    maxLength: 150,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        requiredText(v) ??
                        (RegExp(
                              r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                            ).hasMatch(v!.trim())
                            ? null
                            : 'Địa chỉ email chưa hợp lệ.'),
                    decoration: const InputDecoration(
                      labelText: 'Email đăng nhập *',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phone,
                    enabled: !saving,
                    maxLength: 20,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null ||
                            v.trim().isEmpty ||
                            RegExp(r'^[+0-9 ()-]{5,20}$').hasMatch(v.trim())
                        ? null
                        : 'Số điện thoại chưa hợp lệ.',
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: role,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Vai trò *'),
                    items: [
                      for (final r in roles)
                        DropdownMenuItem(
                          value: r.roleId,
                          child: Text(r.roleName),
                        ),
                    ],
                    onChanged: saving ? null : (v) => setState(() => role = v),
                    validator: (v) =>
                        v == null ? 'Vui lòng chọn vai trò.' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: branch,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Chi nhánh *'),
                    items: [
                      for (final b in data.branches.where((b) => b.isActive))
                        DropdownMenuItem(
                          value: b.branchId,
                          child: Text(
                            b.branchName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) => setState(() => branch = v),
                    validator: (v) =>
                        v == null ? 'Vui lòng chọn chi nhánh.' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tài khoản mới có thể đăng nhập Google bằng email đã khai báo. Biểu mẫu này không gửi email hoặc tạo mật khẩu.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(saving ? 'Đang lưu...' : 'Lưu nhân viên'),
          ),
        ],
      ),
    );
  }
}
