// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube/features/content/video_player.dart';
import 'package:youtube/features/models/user_model.dart';
import 'package:youtube/features/auth/auth_provider.dart';
import 'edit_profile.dart';  // Import the EditProfilePage

// Define Appwrite configurations
const String appwriteEndpoint = 'https://cloud.appwrite.io/v1';
const String projectId = 'project';
const String databaseId = 'database';
const String usersCollectionId = 'users';
const String contentCollectionId = 'content'; // Add your actual content collection ID

// Create a client instance for Appwrite
final Client client = Client()
  ..setEndpoint(appwriteEndpoint)
  ..setProject(projectId);

// Create an instance of the Appwrite Database service
final Databases databases = Databases(client);

class ProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(currentUserProvider);
    final userContentAsyncValue = ref.watch(userContentProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
            },
          ),
        ],
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text('No user found', style: TextStyle(fontSize: 18, color: Colors.grey[700])));
          }

          final userId = user.$id;

          return FutureBuilder<models.Document>(
            future: _fetchUserDetails(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load user data', style: TextStyle(fontSize: 18, color: Colors.red)));
              }
              if (!snapshot.hasData) {
                return Center(child: Text('User data not found', style: TextStyle(fontSize: 18, color: Colors.grey[700])));
              }

              final userData = UserModel.fromMap(snapshot.data!.data);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: CachedNetworkImageProvider(
                            userData.profilePictureUrl,
                          ),
                          onBackgroundImageError: (error, stackTrace) {
                            debugPrint('Failed to load profile picture: $error');
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userData.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[300],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${userData.subscriptions.length} Subscribers', // Display the number of subscriptions
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: userContentAsyncValue.when(
                      data: (contents) {
                        if (contents.isEmpty) {
                          return Center(child: Text('No content uploaded.', style: TextStyle(fontSize: 18, color: Colors.grey[700])));
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          itemCount: contents.length,
                          itemBuilder: (context, index) {
                            final content = contents[index];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VideoPlayerPage(
                                      contentId: content.id,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: content.thumbnailUrl,
                                      height: 90,
                                      width: 160,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                      errorWidget: (context, url, error) {
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            content.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${content.views} views',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => const Center(child: Text('Failed to load content', style: TextStyle(fontSize: 18, color: Colors.red))),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Failed to load user data', style: TextStyle(fontSize: 18, color: Colors.red))),
      ),
    );
  }

  // Function to fetch user details from the Appwrite users collection
  Future<models.Document> _fetchUserDetails(String userId) async {
    try {
      final document = await databases.getDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
      );
      return document;
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      rethrow;
    }
  }
}
