/*import 'package:flutter/material.dart';
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
                    child: const Row(
                      children: [
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

  void _showCommentsSection(BuildContext context) async {
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

              return FutureBuilder<List<Map<String, String>>>(
                future: _fetchCommentersDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final commentersDetails = snapshot.data ?? [];

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            final commenter = commentersDetails
                                .firstWhere(
                                  (details) => details['userId'] == comment['userId'],
                                  orElse: () => {'name': 'Unknown', 'profilePictureUrl': ''},
                                );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(commenter['profilePictureUrl'] ?? ''),
                                radius: 20,
                              ),
                              title: Text(commenter['name'] ?? 'Unknown User'),
                              subtitle: Text(comment['commentText'] ?? 'No text'),
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
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => const Text('Error loading user data'),
          ),
        );
      },
    );
  }

  Future<List<Map<String, String>>> _fetchCommentersDetails() async {
    final userIds = _comments.map((comment) => comment['userId'] as String).toSet();
    final List<Map<String, String>> usersDetails = [];

    for (final userId in userIds) {
      try {
        final userDocument = await _fetchUserDetails(userId);
        usersDetails.add({
          'userId': userId,
          'name': userDocument.data['name'] ?? 'Unknown User',
          'profilePictureUrl': userDocument.data['profilePictureUrl'] ?? '',
        });
      } catch (e) {
        // Handle any error
      }
    }

    return usersDetails;
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
*/


import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube/features/auth/auth_provider.dart';
import 'dart:convert';

const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
const String projectId = 'project';
const String databaseId = 'data';
const String usersCollectionId = 'users';
const String contentCollectionId = 'content';

final Client client = Client()
  ..setEndpoint(appwriteEndpoint)
  ..setProject(projectId);

final Databases databases = Databases(client);

class VideoPlayerPage extends ConsumerStatefulWidget {
  final String contentId;

  const VideoPlayerPage({required this.contentId, super.key});

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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.expand_more),
                        onPressed: () => _showDescriptionPopup(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                              label: Text('$_likes', style: const TextStyle(fontSize: 12)),
                              onPressed: _likeVideo,
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.share, size: 16),
                              label: const Text('Share', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                // Share logic here
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Download', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                // Download logic here
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.comment, size: 16),
                              label: Text('${_comments.length} Comments', style: const TextStyle(fontSize: 12)),
                              onPressed: () => _showCommentsSection(context),
                      ),
                    ],
                  ),
                      )
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
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: Text(
                  _description,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCommentsSection(BuildContext context) async {
  final userAsyncValue = ref.read(currentUserProvider);
  final FocusNode _commentFocusNode = FocusNode(); // Create a FocusNode for TextField

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the bottom sheet to adjust for the keyboard
    builder: (context) {
      return userAsyncValue.when(
        data: (currentUser) {
          final currentUserId = currentUser!.$id;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom, // Adjusts for the keyboard
                ),
                child: FractionallySizedBox(
                  heightFactor: 0.7, // Adjusts the height of the bottom sheet
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Comments',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<Map<String, String>>>(
                          future: _fetchCommentersDetails(), // Fetch commenter details
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            final commentersDetails = snapshot.data ?? [];

                            return ListView.builder(
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                final commenter = commentersDetails.firstWhere(
                                  (details) => details['userId'] == comment['userId'],
                                  orElse: () => {'name': 'Unknown', 'profilePictureUrl': ''},
                                );

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(commenter['profilePictureUrl'] ?? ''),
                                    radius: 20,
                                  ),
                                  title: Text(commenter['name'] ?? 'Unknown User'),
                                  subtitle: Text(comment['commentText'] ?? 'No text'),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          focusNode: _commentFocusNode, // Assign FocusNode to TextField
                          decoration: const InputDecoration(hintText: 'Add a comment...'),
                          onSubmitted: (commentText) {
                            _addComment(currentUserId, commentText); // Add comment functionality
                            setState(() {}); // Update UI
                          },
                          autofocus: true, // Automatically focus TextField to bring up keyboard
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()), // Show loading indicator
        error: (error, _) => const Text('Error loading user data'), // Show error message if user data fails
      );
    },
  ).whenComplete(() => _commentFocusNode.dispose()); // Dispose of FocusNode when sheet is closed
}


  Future<List<Map<String, String>>> _fetchCommentersDetails() async {
    final userIds = _comments.map((comment) => comment['userId'] as String).toSet();
    final List<Map<String, String>> usersDetails = [];

    for (final userId in userIds) {
      try {
        final userDocument = await _fetchUserDetails(userId);
        usersDetails.add({
          'userId': userId,
          'name': userDocument.data['name'] ?? 'Unknown User',
          'profilePictureUrl': userDocument.data['profilePictureUrl'] ?? '',
        });
      } catch (e) {
        // Handle any error
      }
    }

    return usersDetails;
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
    // ignore: deprecated_member_use
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





