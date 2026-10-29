import 'employee_editor_dialog.dart';
import '../../../core/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';

class EmployeeManagementPage extends StatefulWidget {
  const EmployeeManagementPage({super.key});

  @override
  State<EmployeeManagementPage> createState() => _EmployeeManagementPageState();
}

class _EmployeeManagementPageState extends State<EmployeeManagementPage> {
  final Set<int> _pendingStatus = {};
  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL';
  String _selectedStatusFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();

    // Lọc danh sách nhân viên
    final filteredEmployees = data.employees.where((emp) {
      final matchesSearch =
          emp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole =
          _selectedRoleFilter == 'ALL' ||
          data.roles.any(
            (r) => r.roleId == emp.roleId && r.roleCode == _selectedRoleFilter,
          );

      final matchesStatus =
          _selectedStatusFilter == 'ALL' ||
          emp.employmentStatus == _selectedStatusFilter;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản lý nhân viên',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm và bộ lọc
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, mã NV hoặc email...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'ALL', _selectedRoleFilter, (
                        val,
                      ) {
                        setState(() => _selectedRoleFilter = val);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Nhân viên',
                        'EMPLOYEE',
                        _selectedRoleFilter,
                        (val) {
                          setState(() => _selectedRoleFilter = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Quản lý',
                        'MANAGER',
                        _selectedRoleFilter,
                        (val) {
                          setState(() => _selectedRoleFilter = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('Nhân sự', 'HR', _selectedRoleFilter, (
                        val,
                      ) {
                        setState(() => _selectedRoleFilter = val);
                      }),
                      const SizedBox(width: 14),
                      Container(width: 1, height: 24, color: AppColors.divider),
                      const SizedBox(width: 14),
                      _buildFilterChip(
                        'Đang làm',
                        'ACTIVE',
                        _selectedStatusFilter,
                        (val) {
                          setState(() => _selectedStatusFilter = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Tạm khóa',
                        'SUSPENDED',
                        _selectedStatusFilter,
                        (val) {
                          setState(() => _selectedStatusFilter = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Danh sách nhân viên
          Expanded(
            child: filteredEmployees.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy nhân viên nào phù hợp',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEmployees.length,
                    itemBuilder: (ctx, idx) {
                      final emp = filteredEmployees[idx];
                      return _buildEmployeeCard(context, emp, data);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Thêm nhân viên'),
        onPressed: () => _showAddEmployeeDialog(context, data),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    String current,
    Function(String) onSelect,
  ) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(
    BuildContext context,
    Employee emp,
    MockDataService data,
  ) {
    final roleName =
        data.roles.where((r) => r.roleId == emp.roleId).firstOrNull?.roleName ??
        'Chưa xác định';

    final canManage =
        !data.isRemote ||
        (emp.employeeId != data.currentLoggedInEmployeeId &&
            (data.currentRoleCode == 'ADMIN' ||
                (data.roles
                            .where((r) => r.roleId == emp.roleId)
                            .firstOrNull
                            ?.roleCode ==
                        'EMPLOYEE' &&
                    emp.branchId == data.currentBranch.branchId &&
                    data.currentBranch.branchId != 0)));
    final isActive = emp.employmentStatus == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          AppAvatar(radius: 24, imageUrl: emp.avatarUrl ?? ''),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      emp.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: emp.roleId == 2
                            ? const Color(0xFFEDE9FE)
                            : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: emp.roleId == 2
                              ? Colors.purple
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${emp.employeeCode}  •  ${emp.email}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (emp.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SĐT: ${emp.phone}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                tooltip: 'Sửa thông tin',
                onPressed: canManage
                    ? () => _showAddEmployeeDialog(context, data, employee: emp)
                    : null,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                icon: Icon(
                  isActive ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                tooltip: isActive ? 'Khóa tài khoản' : 'Kích hoạt lại',
                onPressed: !canManage || _pendingStatus.contains(emp.employeeId)
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                              isActive
                                  ? 'Tạm khóa tài khoản?'
                                  : 'Kích hoạt tài khoản?',
                            ),
                            content: Text(
                              isActive
                                  ? '${emp.fullName} sẽ không thể tiếp tục sử dụng hệ thống.'
                                  : 'Cho phép ${emp.fullName} đăng nhập trở lại.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Hủy'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Xác nhận'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true || !mounted) return;
                        setState(() => _pendingStatus.add(emp.employeeId));
                        try {
                          await data.toggleEmployeeStatus(emp.employeeId);
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã cập nhật trạng thái tài khoản.',
                                ),
                              ),
                            );
                        } catch (e) {
                          if (context.mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                        } finally {
                          if (mounted)
                            setState(
                              () => _pendingStatus.remove(emp.employeeId),
                            );
                        }
                      },
              ),
              Text(
                isActive ? 'Hoạt động' : 'Tạm khóa',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEmployeeDialog(
    BuildContext context,
    MockDataService data, {
    Employee? employee,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EmployeeEditorDialog(data: data, employee: employee),
    );
    if (result == true && context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            employee == null
                ? 'Đã thêm nhân viên vào hệ thống.'
                : 'Đã cập nhật thông tin nhân viên.',
          ),
        ),
      );
  }
}
