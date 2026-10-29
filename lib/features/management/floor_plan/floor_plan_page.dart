import '../../../core/widgets/app_avatar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';

class FloorPlanPage extends StatefulWidget {
  const FloorPlanPage({super.key});

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends State<FloorPlanPage> {
  WorkArea? _selectedArea;
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sơ đồ mặt bằng & Vị trí',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${data.currentFloorPlan.floorName} (Trực quan hóa thời gian thực)',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Đặt lại góc nhìn',
            icon: const Icon(Icons.center_focus_strong_rounded),
            onPressed: _resetZoom,
          ),
          IconButton(
            tooltip: 'Thông tin chú thích',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showLegendDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chú thích trạng thái nhanh
          _buildQuickLegendBar(),

          // Bản đồ tương tác 2D
          Expanded(
            child: Stack(
              children: [
                InteractiveViewer(
                  constrained: false,
                  transformationController: _transformController,
                  boundaryMargin: const EdgeInsets.all(40),
                  minScale: 0.7,
                  maxScale: 2.8,
                  child: Center(
                    child: Container(
                      width: 380,
                      height: 520,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFCFD8DC),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Bản vẽ lưới mặt bằng siêu thị
                          Positioned.fill(
                            child: CustomPaint(
                              painter: SupermarketGridPainter(),
                            ),
                          ),

                          // Cửa ra vào chính
                          Positioned(
                            bottom: 0,
                            left: 130,
                            right: 130,
                            child: Container(
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F4C81),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'CỬA CHÍNH (MAIN ENTRANCE)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Cửa kho & nhập hàng
                          Positioned(
                            top: 0,
                            right: 30,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'CỬA NHẬP HÀNG (LOADING BAY)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Các khu vực làm việc (Work Areas)
                          ...data.workAreas
                              .where(
                                (area) =>
                                    area.floorPlanId ==
                                    data.currentFloorPlan.floorPlanId,
                              )
                              .map((area) => _buildAreaWidget(area, data)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Nút thu phóng nổi
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'zoom_in',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        child: const Icon(Icons.add),
                        onPressed: () {
                          _transformController.value = _transformController
                              .value
                              .scaled(1.2);
                        },
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'zoom_out',
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        child: const Icon(Icons.remove),
                        onPressed: () {
                          _transformController.value = _transformController
                              .value
                              .scaled(0.8);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        alignment: WrapAlignment.spaceAround,
        children: [
          _buildLegendItem(AppColors.statusPresent, 'Đúng vị trí'),
          _buildLegendItem(AppColors.statusLate, 'Đi muộn'),
          _buildLegendItem(AppColors.statusInvalid, 'Sai vị trí'),
          _buildLegendItem(AppColors.statusPending, 'Chưa vào ca'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaWidget(WorkArea area, MockDataService data) {
    final assignedStaff = data.getEmployeesAssignedToArea(area.workAreaId);
    final isSelected = _selectedArea?.workAreaId == area.workAreaId;

    // Tính toán tọa độ pixel từ tỷ lệ %
    final left = (area.mapX / 100.0) * 380;
    final top = (area.mapY / 100.0) * 520;
    final width = ((area.mapWidth ?? 25.0) / 100.0) * 380;
    final height = ((area.mapHeight ?? 18.0) / 100.0) * 520;

    Color areaBgColor;
    Color areaBorderColor;
    IconData areaIcon;

    switch (area.areaType) {
      case 'CASHIER':
        areaBgColor = AppColors.areaCashier;
        areaBorderColor = const Color(0xFF38BDF8);
        areaIcon = Icons.point_of_sale_rounded;
        break;
      case 'FRESH_FOOD':
        areaBgColor = AppColors.areaFreshFood;
        areaBorderColor = const Color(0xFF4ADE80);
        areaIcon = Icons.eco_rounded;
        break;
      case 'GROCERY':
        areaBgColor = AppColors.areaGrocery;
        areaBorderColor = const Color(0xFFFBBF24);
        areaIcon = Icons.inventory_2_rounded;
        break;
      case 'WAREHOUSE':
        areaBgColor = AppColors.areaWarehouse;
        areaBorderColor = const Color(0xFFA78BFA);
        areaIcon = Icons.warehouse_rounded;
        break;
      case 'SECURITY':
        areaBgColor = AppColors.areaSecurity;
        areaBorderColor = const Color(0xFFFB7185);
        areaIcon = Icons.security_rounded;
        break;
      default:
        areaBgColor = AppColors.areaService;
        areaBorderColor = const Color(0xFF94A3B8);
        areaIcon = Icons.support_agent_rounded;
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedArea = area);
          _showAreaDetailSheet(context, area, assignedStaff, data);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: areaBgColor.withOpacity(isSelected ? 0.95 : 0.75),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : areaBorderColor,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề khu vực và icon
              Row(
                children: [
                  Icon(areaIcon, size: 14, color: areaBorderColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      area.areaName,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Hiển thị nhân viên trong khu vực (Avatar dots)
              Row(
                children: [
                  // Sức chứa
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: areaBorderColor.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '${assignedStaff.length}/${area.maxEmployees ?? "∞"}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color:
                                assignedStaff.length > (area.maxEmployees ?? 99)
                                ? Colors.red
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Các chấm trạng thái nhân viên
                  Expanded(
                    child: Wrap(
                      spacing: 3,
                      children: assignedStaff.map((emp) {
                        final status = data.getEmployeeAttendanceStatus(
                          emp.employeeId,
                        );
                        Color dotColor = AppColors.statusPending;
                        if (status == 'PRESENT')
                          dotColor = AppColors.statusPresent;
                        if (status == 'LATE') dotColor = AppColors.statusLate;
                        if (status == 'INVALID_LOCATION' ||
                            status == 'REJECTED') {
                          dotColor = AppColors.statusInvalid;
                        }

                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAreaDetailSheet(
    BuildContext context,
    WorkArea area,
    List<Employee> assignedStaff,
    MockDataService data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề khu vực
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.areaName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mã khu vực: ${area.areaCode}  •  Bán kính GPS: ${area.radiusMeters ?? 25}m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sức chứa: ${assignedStaff.length}/${area.maxEmployees}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Danh sách nhân sự được phân công
              Text(
                'Nhân viên đang phân công tại khu vực (${assignedStaff.length}):',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              if (assignedStaff.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: const Text(
                    'Chưa có nhân viên nào được phân công trong khu vực này hôm nay.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                )
              else
                ...assignedStaff.map((emp) {
                  final status = data.getEmployeeAttendanceStatus(
                    emp.employeeId,
                  );
                  String statusText = 'Chờ vào ca';
                  Color statusColor = AppColors.statusPending;

                  if (status == 'PRESENT') {
                    statusText = 'Đang làm việc (Đúng giờ)';
                    statusColor = AppColors.statusPresent;
                  } else if (status == 'LATE') {
                    statusText = 'Đi muộn';
                    statusColor = AppColors.statusLate;
                  } else if (status == 'INVALID_LOCATION') {
                    statusText = 'Sai vị trí check-in';
                    statusColor = AppColors.statusInvalid;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        AppAvatar(radius: 18, imageUrl: emp.avatarUrl ?? ''),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${emp.employeeCode}  •  ${emp.phone ?? ""}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Phân công thêm nhân viên vào khu vực'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Chuyển đến màn hình phân công cho "${area.areaName}"',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quy tắc trực quan hóa mặt bằng'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Sơ đồ 2D mô phỏng mặt bằng tầng 1 của siêu thị.'),
            SizedBox(height: 6),
            Text(
              '• Chấm Xanh: Nhân viên đã quét mã QR và xác thực tọa độ GPS đúng tại quầy/khu vực.',
            ),
            SizedBox(height: 6),
            Text(
              '• Chấm Vàng: Nhân viên đến muộn hơn số phút cho phép của ca làm.',
            ),
            SizedBox(height: 6),
            Text(
              '• Chấm Đỏ: Quét mã QR ngoài bán kính GPS cho phép hoặc check-in sai khu vực.',
            ),
            SizedBox(height: 6),
            Text(
              '• Chạm vào từng khu vực để kiểm tra danh sách nhân viên và quản lý tỷ lệ lấp đầy.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

// Vẽ nền lưới kỹ thuật siêu thị (Grid blueprint)
class SupermarketGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..strokeWidth = 1;

    const double step = 20;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
