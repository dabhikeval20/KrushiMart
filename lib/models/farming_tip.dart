class FarmingTip {
  final int id;
  final String title;
  final String body;
  final int userId;

  FarmingTip({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
  });

  factory FarmingTip.fromJson(Map<String, dynamic> json) {
    return FarmingTip(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      userId: json['userId'] as int,
    );
  }
}
