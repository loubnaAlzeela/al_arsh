/// WeekModel — mirrors public.weeks table
class WeekModel {
  final String id;
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime votingClosesAt;
  final DateTime announcementAt;
  final String status; // active | voting_closed | announced
  final String? blueWinnerId;
  final String? goldWinnerId;
  final String? redWinnerId;
  final DateTime createdAt;

  const WeekModel({
    required this.id,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.votingClosesAt,
    required this.announcementAt,
    required this.status,
    this.blueWinnerId,
    this.goldWinnerId,
    this.redWinnerId,
    required this.createdAt,
  });

  factory WeekModel.fromJson(Map<String, dynamic> json) => WeekModel(
    id:             json['id'] as String,
    weekNumber:     json['week_number'] as int,
    startDate:      DateTime.parse(json['start_date'] as String),
    endDate:        DateTime.parse(json['end_date'] as String),
    votingClosesAt: DateTime.parse(json['voting_closes_at'] as String),
    announcementAt: DateTime.parse(json['announcement_at'] as String),
    status:         json['status'] as String,
    blueWinnerId:   json['blue_winner_id'] as String?,
    goldWinnerId:   json['gold_winner_id'] as String?,
    redWinnerId:    json['red_winner_id'] as String?,
    createdAt:      DateTime.parse(json['created_at'] as String),
  );

  bool get isActive        => status == 'active';
  bool get isVotingClosed  => status == 'voting_closed';
  bool get isAnnounced     => status == 'announced';

  /// Time remaining until voting closes (null if already closed)
  Duration? get timeUntilVotingCloses {
    final now = DateTime.now();
    if (now.isAfter(votingClosesAt)) return null;
    return votingClosesAt.difference(now);
  }

  /// Time remaining until announcement (null if already announced)
  Duration? get timeUntilAnnouncement {
    final now = DateTime.now();
    if (now.isAfter(announcementAt)) return null;
    return announcementAt.difference(now);
  }
}
