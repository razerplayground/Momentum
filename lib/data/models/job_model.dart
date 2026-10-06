class JobModel {
  final String id;
  final String businessId;
  final String title;
  final String department;
  final String status;

  const JobModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.department,
    required this.status,
  });

  factory JobModel.fromApiJson(
    Map<String, dynamic> json, {
    required String businessId,
  }) {
    final id = (json['id'] ?? json['_id'])?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Job response is missing an id');
    }

    return JobModel(
      id: id,
      businessId: businessId,
      title: (json['title'] ?? json['name'] ?? '').toString(),
      department: (json['department'] ?? json['description'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
    );
  }
}
