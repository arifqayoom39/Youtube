/*import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube/features/content/video_player.dart';
import 'package:youtube/features/models/content_model.dart';
import 'package:youtube/features/models/user_model.dart';
import 'user_profile_page.dart'; // Assuming this is your user profile page

// Appwrite constants
const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
const String projectId = '641c98b6c77b8608f2e5';
const String databaseId = '64266e17ca25c2989d87';
const String contentCollectionId = '66d72ebd003532c7221e';
const String usersCollectionId = '64266e290b1360e8d4b5';

// Appwrite client
final Client client = Client()
  ..setEndpoint(appwriteEndpoint)
  ..setProject(projectId);

// Databases instance
final Databases databases = Databases(client);

// Providers to fetch content and users
final contentProvider = FutureProvider<List<ContentModel>>((ref) async {
  try {
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: contentCollectionId,
    );
    final contents = response.documents.map((doc) => ContentModel.fromMap(doc.data)).toList();
    return contents;
  } catch (e) {
    debugPrint('Error fetching content: $e');
    rethrow;
  }
});

final usersProvider = FutureProvider<List<models.Document>>((ref) async {
  try {
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollectionId,
    );
    return response.documents;
  } catch (e) {
    debugPrint('Error fetching users: $e');
    rethrow;
  }
});

class ContentUserListPage extends ConsumerStatefulWidget {
  const ContentUserListPage({Key? key}) : super(key: key);

  @override
  _ContentUserListPageState createState() => _ContentUserListPageState();
}

class _ContentUserListPageState extends ConsumerState<ContentUserListPage> {
  TextEditingController searchController = TextEditingController();

  void _performSearch(String query) {
    setState(() {}); // Trigger UI update when search is performed.
  }

  @override
  Widget build(BuildContext context) {
    final contentAsyncValue = ref.watch(contentProvider);
    final usersAsyncValue = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content & Users'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Text('Content List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  contentAsyncValue.when(
                    data: (contents) {
                      if (contents.isEmpty) {
                        return const Center(child: Text('No content available.'));
                      }

                      final filteredContents = contents.where((content) {
                        return content.title.toLowerCase().contains(searchController.text.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: filteredContents.length,
                        shrinkWrap: true, // Ensure the ListView takes only the required space
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final content = filteredContents[index];
                          return ContentTile(content: content);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Failed to load content: $error')),
                  ),

                  // Users Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: const Text('User List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  usersAsyncValue.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return const Center(child: Text('No users available.'));
                      }

                      final filteredUsers = users.where((user) {
                        final userData = UserModel.fromMap(user.data);
                        return userData.name.toLowerCase().contains(searchController.text.toLowerCase());
                      }).toList();

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: filteredUsers.length,
                        shrinkWrap: true, // Ensure the ListView takes only the required space
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final userDoc = filteredUsers[index];
                          final userData = UserModel.fromMap(userDoc.data);
                          return UserTile(user: userData, userId: userDoc.$id);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(child: Text('Failed to load users: $error')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContentTile extends StatelessWidget {
  final ContentModel content;

  const ContentTile({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(contentId: content.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: content.thumbnailUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            const SizedBox(height: 8),
            Text(
              content.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${content.views} views',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final UserModel user;
  final String userId;

  const UserTile({Key? key, required this.user, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(userId: userId),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: CachedNetworkImageProvider(user.profilePictureUrl),
          onBackgroundImageError: (error, stackTrace) {
            debugPrint('Error loading profile picture: $error');
          },
        ),
        title: Text(user.name),
        subtitle: Text(user.email),
      ),
    );
  }
}*/





import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube/features/content/video_player.dart';
import 'package:youtube/features/models/content_model.dart';
import 'package:youtube/features/models/user_model.dart';
import 'user_profile_page.dart'; // Import your user profile page

// Appwrite constants
const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
const String projectId = '641c98b6c77b8608f2e5';
const String databaseId = '64266e17ca25c2989d87';
const String contentCollectionId = '66d72ebd003532c7221e';
const String usersCollectionId = '64266e290b1360e8d4b5';

// Appwrite client
final Client client = Client()
  ..setEndpoint(appwriteEndpoint)
  ..setProject(projectId);

// Databases instance
final Databases databases = Databases(client);

// Providers to fetch content and users
final contentProvider = FutureProvider<List<ContentModel>>((ref) async {
  try {
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: contentCollectionId,
    );
    final contents = response.documents.map((doc) => ContentModel.fromMap(doc.data)).toList();
    return contents;
  } catch (e) {
    debugPrint('Error fetching content: $e');
    rethrow;
  }
});

final usersProvider = FutureProvider<List<models.Document>>((ref) async {
  try {
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: usersCollectionId,
    );
    return response.documents;
  } catch (e) {
    debugPrint('Error fetching users: $e');
    rethrow;
  }
});

class ContentUserListPage extends ConsumerStatefulWidget {
  const ContentUserListPage({super.key});

  @override
  ContentUserListPageState createState() => ContentUserListPageState();
}

class ContentUserListPageState extends ConsumerState<ContentUserListPage> {
  TextEditingController searchController = TextEditingController();

  void _performSearch(String query) {
    setState(() {}); // Trigger UI update when search is performed.
  }

  @override
  Widget build(BuildContext context) {
    final contentAsyncValue = ref.watch(contentProvider);
    final usersAsyncValue = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            controller: searchController,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: 'Search',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[300],
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Combine users and content based on search
            ..._buildSearchResults(contentAsyncValue, usersAsyncValue),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchResults(
    AsyncValue<List<ContentModel>> contentAsyncValue,
    AsyncValue<List<models.Document>> usersAsyncValue,
  ) {
    List<Widget> widgets = [];

    final searchTerm = searchController.text.toLowerCase();

    // Handle content results
    contentAsyncValue.when(
      data: (contents) {
        final filteredContents = contents.where((content) {
          return content.title.toLowerCase().contains(searchTerm);
        }).toList();

        widgets.addAll(
          filteredContents.map((content) => ContentTile(content: content)).toList(),
        );
      },
      loading: () => [const Center(child: CircularProgressIndicator())],
      error: (error, _) => [Center(child: Text('Failed to load content: $error'))],
    );

    // Handle user results
    usersAsyncValue.when(
      data: (users) {
        final filteredUsers = users.where((user) {
          final userData = UserModel.fromMap(user.data);
          return userData.name.toLowerCase().contains(searchTerm);
        }).toList();

        widgets.addAll(
          filteredUsers.map((userDoc) {
            final userData = UserModel.fromMap(userDoc.data);
            return UserTile(user: userData, userId: userDoc.$id);
          }).toList(),
        );
      },
      loading: () => [const Center(child: CircularProgressIndicator())],
      error: (error, _) => [Center(child: Text('Failed to load users: $error'))],
    );

    return widgets;
  }
}

class ContentTile extends StatelessWidget {
  final ContentModel content;

  const ContentTile({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(contentId: content.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: content.thumbnailUrl,
              height: 200, // Set height to be rectangular like YouTube
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            const SizedBox(height: 4),
            Text(
              content.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${content.views} views',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class UserTile extends StatelessWidget {
  final UserModel user;
  final String userId;

  const UserTile({super.key, required this.user, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(userId: userId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.profilePictureUrl),
            onBackgroundImageError: (error, stackTrace) {
              debugPrint('Error loading profile picture: $error');
            },
          ),
          title: Text(user.name),
          subtitle: Text('${user.subscriptions.length} Subscribers'),
        ),
      ),
    );
  }
}

