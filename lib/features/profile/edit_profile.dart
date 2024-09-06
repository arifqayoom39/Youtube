import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:youtube/features/auth/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) return Center(child: Text('No user found'));

          _nameController.text = user.name;
          _emailController.text = user.email;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _updateUserDetails(
                    user.$id,
                    _nameController.text,
                    _emailController.text,
                  ),
                  child: Text('Update Details'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _updateProfileImage(user.$id),
                  child: Text('Update Profile Image'),
                ),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load user data')),
      ),
    );
  }

  Future<void> _updateUserDetails(String userId, String name, String email) async {
    try {
      final database = ref.read(databaseProvider);
      await database.updateDocument(
        databaseId: '64266e17ca25c2989d87',
        collectionId: '64266e290b1360e8d4b5',
        documentId: userId,
        data: {
          'name': name,
          'email': email,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Details updated successfully')),
      );
    } catch (e) {
      debugPrint('Error updating user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update details')),
      );
    }
  }

  Future<void> _updateProfileImage(String userId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        final storage = ref.read(storageProvider);
        final uploadedFile = await storage.createFile(
          bucketId: '6427d4792ddd2c15bbdd',
          fileId: 'unique()',
          file: InputFile.fromPath(path: image.path),
        );

        final imageUrl = 'https://cloud.appwrite.io/v1/storage/buckets/6427d4792ddd2c15bbdd/files/${uploadedFile.$id}/view?project=641c98b6c77b8608f2e5&mode=admin';

        final database = ref.read(databaseProvider);
        await database.updateDocument(
          databaseId: '64266e17ca25c2989d87',
          collectionId: '64266e290b1360e8d4b5',
          documentId: userId,
          data: {
            'profilePictureUrl': imageUrl,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile image updated successfully')),
        );
      } catch (e) {
        debugPrint('Error updating profile image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image')),
        );
      }
    }
  }
}
