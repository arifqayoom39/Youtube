// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import 'package:youtube/features/auth/auth_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends ConsumerState<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: userAsyncValue.when(
        data: (user) {
          if (user == null) return const Center(child: Text('No user found'));

          _nameController.text = user.name;
          _emailController.text = user.email;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _updateUserDetails(
                    user.$id,
                    _nameController.text,
                    _emailController.text,
                  ),
                  child: const Text('Update Details'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _updateProfileImage(user.$id),
                  child: const Text('Update Profile Image'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const Center(child: Text('Failed to load user data')),
      ),
    );
  }

  Future<void> _updateUserDetails(String userId, String name, String email) async {
    try {
      final database = ref.read(databaseProvider);
      await database.updateDocument(
        databaseId: 'data',
        collectionId: 'users',
        documentId: userId,
        data: {
          'name': name,
          'email': email,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Details updated successfully')),
      );
    } catch (e) {
      debugPrint('Error updating user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update details')),
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

        final imageUrl = 'https://cloud.appwrite.io/v1/storage/buckets/bucketid/files/${uploadedFile.$id}/view?project=projectid&mode=admin';

        final database = ref.read(databaseProvider);
        await database.updateDocument(
          databaseId: 'data',
          collectionId: 'content',
          documentId: userId,
          data: {
            'profilePictureUrl': imageUrl,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } catch (e) {
        debugPrint('Error updating profile image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile image')),
        );
      }
    }
  }
}
