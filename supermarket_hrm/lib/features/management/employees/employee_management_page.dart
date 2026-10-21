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
  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL';
  String _selectedStatusFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();

    // Lọc danh sách nhân viên
    final filteredEmployees = data.employees.where((emp) {
      final matchesSearch = emp.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.employeeCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          emp.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesRole = _selectedRoleFilter == 'ALL' ||
          (_selectedRoleFilter == 'MANAGER' && emp.roleId == 2) ||
          (_selectedRoleFilter == 'HR' && emp.roleId == 3) ||
          (_selectedRoleFilter == 'EMPLOYEE' && emp.roleId == 4);

      final matchesStatus = _selectedStatusFilter == 'ALL' || emp.employmentStatus == _selectedStatusFilter;

      return matchesSearch && matchesRole && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý nhân viên', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      _buildFilterChip('Tất cả', 'ALL', _selectedRoleFilter, (val) {
                        setState(() => _selectedRoleFilter = val);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Nhân viên', 'EMPLOYEE', _selectedRoleFilter, (val) {
                        setState(() => _selectedRoleFilter = val);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Quản lý', 'MANAGER', _selectedRoleFilter, (val) {
                        setState(() => _selectedRoleFilter = val);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Nhân sự', 'HR', _selectedRoleFilter, (val) {
                        setState(() => _selectedRoleFilter = val);
                      }),
                      const SizedBox(width: 14),
                      Container(width: 1, height: 24, color: AppColors.divider),
                      const SizedBox(width: 14),
                      _buildFilterChip('Đang làm', 'ACTIVE', _selectedStatusFilter, (val) {
                        setState(() => _selectedStatusFilter = val);
                      }),
                      const SizedBox(width: 8),
                      _buildFilterChip('Tạm khóa', 'SUSPENDED', _selectedStatusFilter, (val) {
                        setState(() => _selectedStatusFilter = val);
                      }),
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
                    child: Text('Không tìm thấy nhân viên nào phù hợp', style: TextStyle(color: AppColors.textMuted)),
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
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Thêm nhân viên'),
        onPressed: () => _showAddEmployeeDialog(context, data),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String) onSelect) {
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
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      ),
    );
  }

  Widget _buildEmployeeCard(BuildContext context, Employee emp, MockDataService data) {
    String roleName = 'Nhân viên';
    if (emp.roleId == 2) roleName = 'Quản lý';
    if (emp.roleId == 3) roleName = 'Nhân sự';
    if (emp.roleId == 1) roleName = 'Admin';

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
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(emp.avatarUrl ?? ''),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      emp.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: emp.roleId == 2 ? const Color(0xFFEDE9FE) : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        roleName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: emp.roleId == 2 ? Colors.purple : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${emp.employeeCode}  •  ${emp.email}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (emp.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SĐT: ${emp.phone}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  isActive ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: isActive ? Colors.green : Colors.red,
                  size: 20,
                ),
                tooltip: isActive ? 'Khóa tài khoản' : 'Kích hoạt lại',
                onPressed: () {
                  data.toggleEmployeeStatus(emp.employeeId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isActive ? 'Đã tạm khóa tài khoản ${emp.fullName}' : 'Đã kích hoạt lại ${emp.fullName}',
                      ),
                    ),
                  );
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

  void _showAddEmployeeDialog(BuildContext context, MockDataService data) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    int roleId = 4; // Default employee

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Thêm nhân viên mới', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Họ và tên *'),
                  ),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(labelText: 'Mã nhân viên (VD: EMP009) *'),
                  ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Google đăng nhập *'),
                  ),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    value: roleId,
                    decoration: const InputDecoration(labelText: 'Vai trò'),
                    items: const [
                      DropdownMenuItem(value: 4, child: Text('Nhân viên siêu thị')),
                      DropdownMenuItem(value: 3, child: Text('Nhân sự (HR)')),
                      DropdownMenuItem(value: 2, child: Text('Quản lý chi nhánh')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => roleId = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đủ họ tên, mã NV và email')),
                    );
                    return;
                  }

                  data.addEmployee(Employee(
                    employeeId: 0,
                    roleId: roleId,
                    employeeCode: codeCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  ));

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã thêm nhân viên ${nameCtrl.text}')),
                  );
                },
                child: const Text('Lưu thông tin'),
              ),
            ],
          );
        },
      ),
    );
  }
}
