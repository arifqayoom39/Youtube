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
const String projectId = 'project';
const String databaseId = 'data';
const String contentCollectionId = 'content';
const String usersCollectionId = 'users';

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

