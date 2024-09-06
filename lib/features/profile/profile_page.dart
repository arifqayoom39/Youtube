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
const String projectId = '641c98b6c77b8608f2e5';
const String databaseId = '64266e17ca25c2989d87';
const String usersCollectionId = '64266e290b1360e8d4b5';
const String contentCollectionId = '66d72ebd003532c7221e'; // Add your actual content collection ID

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
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage()),
              );
            },
          ),
        ],
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) {
            debugPrint('No user found');
            return Center(child: Text('No user found'));
          }

          final userId = user.$id;
          debugPrint('User ID: $userId');

          return FutureBuilder<models.Document>(
            future: _fetchUserDetails(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Failed to load user data'));
              }
              if (!snapshot.hasData) {
                return Center(child: Text('User data not found'));
              }

              final userData = UserModel.fromMap(snapshot.data!.data);
              debugPrint('User data fetched: ${userData.toMap()}');

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          SizedBox(height: 16),
                          Text(
                            userData.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            userData.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 24),
                          Divider(color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            'Uploaded Videos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: userContentAsyncValue.when(
                        data: (contents) {
                          if (contents.isEmpty) {
                            return Center(child: Text('No content uploaded.'));
                          }

                          return GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: contents.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 16 / 9,
                            ),
                            itemBuilder: (context, index) {
                              final content = contents[index];

                              return GestureDetector(
                                onTap: () {
                                  // Navigate to VideoPlayerPage with the content ID
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerPage(
                                        contentId: content.id, // Pass the content ID to VideoPlayerPage
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: CachedNetworkImage(
                                        imageUrl: content.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorWidget: (context, url, error) {
                                          return Icon(Icons.error);
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      content.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${content.views} views',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => Center(child: CircularProgressIndicator()),
                        error: (error, _) => Center(child: Text('Failed to load content')),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load user data')),
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
