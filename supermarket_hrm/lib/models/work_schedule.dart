class WorkSchedule {
  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final String location;
  final String status;
  final String? note;
  final String? checkInTime;
  final String? checkOutTime;

  const WorkSchedule({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.status,
    this.note,
    this.checkInTime,
    this.checkOutTime,
  });

  factory WorkSchedule.fromJson(Map<String, dynamic> json) {
    return WorkSchedule(
      id: json['id']?.toString() ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? json['start_time'] ?? '08:00',
      endTime: json['endTime'] ?? json['end_time'] ?? '17:00',
      location: json['location'] ?? json['zone'] ?? 'Khu vực chính',
      status: json['status'] ?? 'PENDING',
      note: json['note'],
      checkInTime: json['checkInTime'] ?? json['check_in_time'],
      checkOutTime: json['checkOutTime'] ?? json['check_out_time'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'status': status,
        'note': note,
        'checkInTime': checkInTime,
        'checkOutTime': checkOutTime,
      };

  WorkSchedule copyWith({
    String? status,
    String? checkInTime,
    String? checkOutTime,
    String? location,
    String? note,
  }) {
    return WorkSchedule(
      id: id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      location: location ?? this.location,
      status: status ?? this.status,
      note: note ?? this.note,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }
}
