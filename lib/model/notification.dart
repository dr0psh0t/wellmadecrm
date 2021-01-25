class Notifs {

  final String title;
  final String body;
  final int notificationId;
  final int isRead;
  bool isSelected;

  Notifs({this.title, this.body, this.notificationId, this.isRead});

  factory Notifs.fromJson(Map<String, dynamic> json) {
    return Notifs(
      title: json['title'] as String,
      body: json['body'] as String,
      notificationId: json['notificationId'] as int,
      isRead: json['isRead'] as int,
    );
  }
}