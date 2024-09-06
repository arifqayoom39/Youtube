/*import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube/features/auth/auth_provider.dart';
import 'dart:convert'; // For JSON encoding/decoding

// Define Appwrite configurations
const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
const String projectId = '641c98b6c77b8608f2e5';
const String databaseId = '64266e17ca25c2989d87';
const String usersCollectionId = '64266e290b1360e8d4b5';
const String contentCollectionId = '66d72ebd003532c7221e'; // Replace with your collection ID

// Create a client instance for Appwrite
final Client client = Client()
  ..setEndpoint(appwriteEndpoint)
  ..setProject(projectId);

// Create an instance of the Appwrite Database service
final Databases databases = Databases(client);

class VideoPlayerPage extends ConsumerStatefulWidget {
  final String contentId;

  VideoPlayerPage({required this.contentId});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController; // Nullable to handle initialization
  bool _isVideoInitialized = false;
  int _likes = 0;
  int _views = 0;
  List<Map<String, dynamic>> _comments = []; // List of comments

  @override
  void initState() {
    super.initState();
    _fetchContentDetails(widget.contentId).then((document) {
      final videoUrl = document.data['video_url'] ?? '';
      _likes = document.data['likes_count'] ?? 0;
      _views = document.data['views'] ?? 0;

      // Correctly map comments from JSON strings to List of Map<String, dynamic>
      _comments = (document.data['comments'] ?? []).cast<String>().map<Map<String, dynamic>>((commentJson) {
        return jsonDecode(commentJson) as Map<String, dynamic>;
      }).toList();

      if (videoUrl.isNotEmpty) {
        _incrementViewCount(widget.contentId); // Increment view count
        _initializeVideoPlayer(videoUrl);
      } else {
        debugPrint('Error: Video URL is empty');
      }
    }).catchError((e) {
      debugPrint('Error fetching content details: $e');
    });
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose(); // Properly dispose of the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
      ),
      body: FutureBuilder<models.Document>(
        future: _fetchContentDetails(widget.contentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Error loading video details: ${snapshot.error}');
            return Center(child: Text('Failed to load video details'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Video details not found'));
          }

          final contentData = snapshot.data!.data;
          final title = contentData['title'] ?? 'Untitled';
          final description = contentData['description'] ?? 'No description available';
          final userId = contentData['user_id'] ?? '';

          // Fetch user details based on userId
          return FutureBuilder<models.Document>(
            future: _fetchUserDetails(userId),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError) {
                debugPrint('Error loading user details: ${userSnapshot.error}');
                return Center(child: Text('Failed to load user details'));
              }
              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return Center(child: Text('User details not found'));
              }

              final userData = userSnapshot.data!.data;
              final profilePictureUrl = userData['profilePictureUrl'] ?? '';
              final userName = userData['name'] ?? 'Unknown User';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video player
                  AspectRatio(
                    aspectRatio: _isVideoInitialized && _videoPlayerController != null
                        ? _videoPlayerController!.value.aspectRatio
                        : 16 / 9, // Fallback aspect ratio
                    child: _isVideoInitialized && _videoPlayerController != null
                        ? VideoPlayer(_videoPlayerController!)
                        : Center(child: CircularProgressIndicator()),
                  ),
                  if (_videoPlayerController != null)
                    VideoProgressIndicator(_videoPlayerController!, allowScrubbing: true),

                  // Video details (Title, description, views, etc.)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.visibility, size: 16),
                            SizedBox(width: 4),
                            Text('$_views views'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(description),
                        Divider(),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(profilePictureUrl),
                              radius: 20,
                            ),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Divider(),

                        // Like/Dislike/Comment/Share buttons
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.thumb_up),
                              onPressed: _likeVideo,
                            ),
                            Text('$_likes Likes'),
                            SizedBox(width: 16),
                            IconButton(
                              icon: Icon(Icons.comment),
                              onPressed: () => _showCommentsSection(context),
                            ),
                            Text('${_comments.length} Comments'),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.share),
                              onPressed: () {
                                // Share logic here
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Comments Section
                  Expanded(
                    child: ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return ListTile(
                          title: Text(comment['commentText'] ?? 'No text'),
                          subtitle: Text('User ID: ${comment['userId'] ?? 'Unknown'}'),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // Increment the view count in the database
  void _incrementViewCount(String contentId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: contentCollectionId,
        documentId: contentId,
        data: {
          'views': _views + 1,
        },
      );
      setState(() {
        _views += 1;
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }

  // Like the video
  void _likeVideo() async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: contentCollectionId,
        documentId: widget.contentId,
        data: {
          'likes_count': _likes + 1,
        },
      );
      setState(() {
        _likes += 1;
      });
    } catch (e) {
      debugPrint('Error liking video: $e');
    }
  }

  // Show comments section in a dialog
  void _showCommentsSection(BuildContext context) {
    final userAsyncValue = ref.read(currentUserProvider);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Comments'),
          content: userAsyncValue.when(
            data: (user) {
              if (user == null) return Text('User not logged in');

              final currentUserId = user.$id;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var comment in _comments)
                    Text(comment['commentText'] ?? 'No text'),
                  TextField(
                    decoration: InputDecoration(hintText: 'Add a comment...'),
                    onSubmitted: (commentText) => _addComment(currentUserId, commentText),
                  ),
                ],
              );
            },
            loading: () => CircularProgressIndicator(),
            error: (error, _) => Text('Error loading user data'),
          ),
        );
      },
    );
  }

  // Add a new comment to the database
  void _addComment(String userId, String commentText) async {
    try {
      // Add comment with userId and commentText
      final newComment = {'userId': userId, 'commentText': commentText};
      _comments.add(newComment);

      // Serialize comments to JSON strings
      final serializedComments = _comments.map((comment) => jsonEncode(comment)).toList();

      // Save comments in the content document
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: contentCollectionId,
        documentId: widget.contentId,
        data: {
          'comments': serializedComments,
        },
      );
      setState(() {
        _comments = serializedComments.map((jsonString) => jsonDecode(jsonString) as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  // Initialize the video player
  void _initializeVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoPlayerController!.play();
      }).catchError((e) {
        debugPrint('Error initializing video player: $e');
      });
  }

  // Fetch content details from the database
  Future<models.Document> _fetchContentDetails(String contentId) async {
    try {
      return await databases.getDocument(
        databaseId: databaseId,
        collectionId: contentCollectionId,
        documentId: contentId,
      );
    } catch (e) {
      debugPrint('Error fetching content details: $e');
      rethrow;
    }
  }

  // Fetch user details from the database
  Future<models.Document> _fetchUserDetails(String userId) async {
    try {
      return await databases.getDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      rethrow;
    }
  }
}*/


import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube/features/auth/auth_provider.dart';
import 'dart:convert';

const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
const String projectId = '641c98b6c77b8608f2e5';
const String databaseId = '64266e17ca25c2989d87';
const String usersCollectionId = '64266e290b1360e8d4b5';
const String contentCollectionId = '66d72ebd003532c7221e';

final Client client = Client()
  ..setEndpoint(appwriteEndpoint)
  ..setProject(projectId);

final Databases databases = Databases(client);

class VideoPlayerPage extends ConsumerStatefulWidget {
  final String contentId;

  // ignore: use_super_parameters
  const VideoPlayerPage({required this.contentId, Key? key}) : super(key: key);

  @override
  VideoPlayerPageState createState() => VideoPlayerPageState();
}

class VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  int _likes = 0;
  int _views = 0;
  List<Map<String, dynamic>> _comments = [];
  bool _isSubscribed = false;
  String _title = '';
  String _description = '';
  String _userId = '';
  String _profilePictureUrl = '';
  String _userName = '';
  bool _isHoveringSubscribeButton = false;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final contentDetails = await _fetchContentDetails(widget.contentId);
      _title = contentDetails.data['title'] ?? 'Untitled';
      _description = contentDetails.data['description'] ?? 'No description available';
      _userId = contentDetails.data['user_id'] ?? '';
      _likes = contentDetails.data['likes_count'] ?? 0;
      _views = contentDetails.data['views'] ?? 0;
      _comments = (contentDetails.data['comments'] ?? [])
          .cast<String>()
          .map<Map<String, dynamic>>((commentJson) {
        return jsonDecode(commentJson) as Map<String, dynamic>;
      }).toList();

      final userDetails = await _fetchUserDetails(_userId);
      _profilePictureUrl = userDetails.data['profilePictureUrl'] ?? '';
      _userName = userDetails.data['name'] ?? 'Unknown User';

      _checkSubscriptionStatus(_userId);

      final videoUrl = contentDetails.data['video_url'] ?? '';
      if (videoUrl.isNotEmpty) {
        _incrementViewCount(widget.contentId);
        _initializeVideoPlayer(videoUrl);
      }

      setState(() {});
    } catch (e) {
      // Handle any error
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideoInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: _videoPlayerController != null
                  ? _videoPlayerController!.value.aspectRatio
                  : 16 / 9,
              child: _videoPlayerController != null
                  ? VideoPlayer(_videoPlayerController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
            if (_videoPlayerController != null)
              VideoProgressIndicator(_videoPlayerController!, allowScrubbing: true),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.visibility, size: 16),
                      const SizedBox(width: 4),
                      Text('$_views views'),
                      const SizedBox(width: 16),
                      Text('$_likes likes'),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.thumb_up_alt_outlined),
                        onPressed: _likeVideo,
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // Share logic here
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showDescriptionPopup(context),
                    child: Row(
                      children: const [
                        Text('Show More', style: TextStyle(color: Colors.blue)),
                        Icon(Icons.expand_more, color: Colors.blue),
                      ],
                    ),
                  ),
                  const Divider(),
Row(
  children: [
    CircleAvatar(
      backgroundImage: NetworkImage(_profilePictureUrl),
      radius: 20,
    ),
    const SizedBox(width: 8),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _userName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
    const Spacer(),
    MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHoveringSubscribeButton = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHoveringSubscribeButton = false;
        });
      },
      child: _isSubscribed
          ? TextButton(
              onPressed: () => _toggleSubscription(_userId),
              child: Text(
                _isHoveringSubscribeButton ? 'Unsubscribe' : 'Subscribed',
                style: TextStyle(
                  color: _isHoveringSubscribeButton ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : TextButton(
              onPressed: () => _toggleSubscription(_userId),
              child: const Text(
                'Subscribe',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    ),
  ],
),

                  const Divider(),
                  Row(
  children: [
    IconButton(
      icon: const Icon(Icons.comment),
      onPressed: () => _showCommentsSection(context), // Opens the popup for comments
    ),
    Text('${_comments.length} Comments'),
  ],
),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _incrementViewCount(String contentId) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: contentCollectionId,
        documentId: contentId,
        data: {
          'views': _views + 1,
        },
      );
      setState(() {
        _views += 1;
      });
    } catch (e) {
      // Handle any error
    }
  }

  void _likeVideo() async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: contentCollectionId,
        documentId: widget.contentId,
        data: {
          'likes_count': _likes + 1,
        },
      );
      setState(() {
        _likes += 1;
      });
    } catch (e) {
      // Handle any error
    }
  }

  void _showDescriptionPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Text(
              _description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }

  void _showCommentsSection(BuildContext context) {
    final userAsyncValue = ref.read(currentUserProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: userAsyncValue.when(
            data: (user) {
              if (user == null) return const Text('User not logged in');

              final currentUserId = user.$id;

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        return ListTile(
                          title: Text(comment['commentText'] ?? 'No text'),
                          subtitle: Text('User ID: ${comment['userId'] ?? 'Unknown'}'),
                        );
                      },
                    ),
                  ),
                  TextField(
                    decoration: const InputDecoration(hintText: 'Add a comment...'),
                    onSubmitted: (commentText) => _addComment(currentUserId, commentText),
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => const Text('Error loading user data'),
          ),
        );
      },
    );
  }

  void _addComment(String userId, String commentText) async {
    try {
      final newComment = {'userId': userId, 'commentText': commentText};
      setState(() {
        _comments.add(newComment);
      });

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: contentCollectionId,
        documentId: widget.contentId,
        data: {
          'comments': _comments.map((comment) => jsonEncode(comment)).toList(),
        },
      );
    } catch (e) {
      // Handle any error
    }
  }

  void _initializeVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoPlayerController!.play();
        });
      });
  }

  Future<models.Document> _fetchContentDetails(String contentId) async {
    return await databases.getDocument(
      databaseId: databaseId,
      collectionId: contentCollectionId,
      documentId: contentId,
    );
  }

  Future<models.Document> _fetchUserDetails(String userId) async {
    return await databases.getDocument(
      databaseId: databaseId,
      collectionId: usersCollectionId,
      documentId: userId,
    );
  }

  void _checkSubscriptionStatus(String userId) async {
    try {
      final userDocument = await _fetchUserDetails(userId);
      final subscriptions = List<String>.from(userDocument.data['subscriptions'] ?? []);
      final currentUser = ref.read(currentUserProvider).asData?.value;

      if (currentUser != null) {
        setState(() {
          _isSubscribed = subscriptions.contains(currentUser.$id);
        });
      }
    } catch (e) {
      // Handle any error
    }
  }

  void _toggleSubscription(String userId) async {
    try {
      final currentUser = ref.read(currentUserProvider).asData?.value;
      if (currentUser == null) return;

      final currentUserId = currentUser.$id;
      final userDocument = await _fetchUserDetails(userId);
      final subscriptions = List<String>.from(userDocument.data['subscriptions'] ?? []);

      if (_isSubscribed) {
        subscriptions.remove(currentUserId);
      } else {
        subscriptions.add(currentUserId);
      }

      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
        data: {
          'subscriptions': subscriptions,
        },
      );

      setState(() {
        _isSubscribed = !_isSubscribed;
      });
    } catch (e) {
      // Handle any error
    }
  }
}



