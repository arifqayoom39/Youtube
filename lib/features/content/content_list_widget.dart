import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
// ignore: unused_import
import 'package:youtube/features/content/video_player.dart';
import 'package:youtube/features/models/content_model.dart';
import 'package:youtube/features/auth/auth_provider.dart';

const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
const String projectId = '641c98b6c77b8608f2e5';
const String databaseId = '64266e17ca25c2989d87';
const String contentCollectionId = '66d72ebd003532c7221e';
const String usersCollectionId = '64266e290b1360e8d4b5';

final Client client = Client()
  ..setEndpoint(appwriteEndpoint)
  ..setProject(projectId);

final Databases databases = Databases(client);

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

final userProvider = FutureProvider.family<models.Document, String>((ref, userId) async {
  try {
    final document = await databases.getDocument(
      databaseId: databaseId,
      collectionId: usersCollectionId,
      documentId: userId,
    );
    return document;
  } catch (e) {
    debugPrint('Error fetching user details for ID $userId: $e');
    rethrow;
  }
});

class ContentListWidget extends ConsumerWidget {
  final VoidCallback? onLogout;
  final Function(String contentId)? onContentTap;

  // ignore: use_super_parameters
  const ContentListWidget({
    Key? key,
    this.onLogout,
    this.onContentTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final contentAsyncValue = ref.watch(contentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/youtube_logo.png',
          height: 40,
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Implement search functionality here
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: onLogout,
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No user found'));
          }

          return contentAsyncValue.when(
            data: (contents) {
              if (contents.isEmpty) {
                return const Center(child: Text('No content available.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount: contents.length,
                itemBuilder: (context, index) {
                  final content = contents[index];
                  final userAsyncValue = ref.watch(userProvider(content.userId));

                  return userAsyncValue.when(
                    data: (userDoc) {
                      final userData = userDoc.data;
                      final profilePictureUrl = userData['profilePictureUrl'] ?? '';
                      final userName = userData['name'] ?? 'Unknown User';

                      return GestureDetector(
                        onTap: () => onContentTap?.call(content.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Video Thumbnail
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
                              // User profile picture and video details
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CircleAvatar(
                                      backgroundImage: NetworkImage(profilePictureUrl),
                                      radius: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          content.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$userName • ${content.views} views',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: Text('Failed to load user details: $error')),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Failed to load content: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load user data: $error')),
      ),
    );
  }
}
