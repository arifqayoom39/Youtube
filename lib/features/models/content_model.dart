class ContentModel {
  final String id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String userId;  // To track which user uploaded the video
  final int likesCount;
  final List<String> comments;  // Storing comment IDs (optional)
  final int views;
  final int subscribersCount;

  ContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.userId,
    required this.likesCount,
    required this.comments,
    required this.views,
    required this.subscribersCount,
  });

  // Convert to Map for Appwrite database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'user_id': userId,
      'likes_count': likesCount,
      'comments': comments,
      'views': views,
      'subscribers_count': subscribersCount,
    };
  }

  // Create ContentModel from Appwrite document
  factory ContentModel.fromMap(Map<String, dynamic> map) {
    return ContentModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      videoUrl: map['video_url'],
      thumbnailUrl: map['thumbnail_url'],
      userId: map['user_id'],
      likesCount: map['likes_count'] ?? 0,
      comments: List<String>.from(map['comments'] ?? []),
      views: map['views'] ?? 0,
      subscribersCount: map['subscribers_count'] ?? 0,
    );
  }
}
