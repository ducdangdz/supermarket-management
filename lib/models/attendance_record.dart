class AttendanceRecord {
  final String id;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String? note;
  final String? location;
  final String? photoUrl;

  const AttendanceRecord({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.note,
    this.location,
    this.photoUrl,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id']?.toString() ?? '',
      date: json['date'] ?? '',
      checkIn: json['checkIn'] ?? json['check_in'] ?? json['check_in_time'],
      checkOut: json['checkOut'] ?? json['check_out'] ?? json['check_out_time'],
      status: json['status'] ?? 'ON_TIME',
      note: json['note'],
      location: json['location'] ?? json['zone'],
      photoUrl: json['photoUrl'] ?? json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'status': status,
        'note': note,
        'location': location,
        'photoUrl': photoUrl,
      };
}
