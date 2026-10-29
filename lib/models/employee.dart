class Employee {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String branch;
  final String employeeCode;
  final String? avatarUrl;

  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.branch,
    required this.employeeCode,
    this.avatarUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'Nhân viên',
      branch: json['branch'] ?? '',
      employeeCode: json['employeeCode'] ?? json['employee_code'] ?? 'NV-001',
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'branch': branch,
        'employeeCode': employeeCode,
        'avatarUrl': avatarUrl,
      };

  Employee copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? branch,
    String? role,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      branch: branch ?? this.branch,
      employeeCode: employeeCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
