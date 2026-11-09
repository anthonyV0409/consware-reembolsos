enum ReimbursementStatus { pending, approved, rejected, unknown }

ReimbursementStatus parseStatus(String? value) {
  switch (value) {
    case 'Pending':
      return ReimbursementStatus.pending;
    case 'Approved':
      return ReimbursementStatus.approved;
    case 'Rejected':
      return ReimbursementStatus.rejected;
    default:
      return ReimbursementStatus.unknown;
  }
}

class Reimbursement {
  final int id;
  final String employeeName;
  final num amount;
  final String category;
  final String description;
  final ReimbursementStatus status;
  final String? rejectionReason;
  final DateTime createdAtUtc;
  final DateTime? decidedAtUtc;

  const Reimbursement({
    required this.id,
    required this.employeeName,
    required this.amount,
    required this.category,
    required this.description,
    required this.status,
    required this.rejectionReason,
    required this.createdAtUtc,
    required this.decidedAtUtc,
  });

  factory Reimbursement.fromJson(Map<String, dynamic> json) {
    return Reimbursement(
      id: json['id'] as int,
      employeeName: json['employeeName'] as String,
      amount: json['amount'] as num,
      category: json['category'] as String,
      description: json['description'] as String,
      status: parseStatus(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      decidedAtUtc: json['decidedAtUtc'] == null
          ? null
          : DateTime.parse(json['decidedAtUtc'] as String),
    );
  }
}
