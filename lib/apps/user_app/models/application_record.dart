enum ApplicationStatus { applied, confirmed }

class ApplicationRecord {
  const ApplicationRecord({
    required this.status,
    required this.appliedAt,
    this.confirmedAt,
  });

  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? confirmedAt;

  ApplicationRecord copyWith({
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? confirmedAt,
  }) {
    return ApplicationRecord(
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}
