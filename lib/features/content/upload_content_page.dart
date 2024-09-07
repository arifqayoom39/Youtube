// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';

import 'package:uuid/uuid.dart';
import '../models/content_model.dart';
import 'package:youtube/features/auth/auth_provider.dart';

class UploadContentPage extends ConsumerStatefulWidget {
  const UploadContentPage({super.key});

  @override
  UploadContentPageState createState() => UploadContentPageState();
}

class UploadContentPageState extends ConsumerState<UploadContentPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _videoFile;
  File? _thumbnailFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  final Client _client = Client();
  final String endpoint = 'https://cloud.appwrite.io/v1';
  final String projectId = 'project';

  @override
  void initState() {
    super.initState();
    _client
        .setEndpoint(endpoint)
        .setProject(projectId)
        .setSelfSigned(status: true);
  }

  Future<void> _pickThumbnail() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _thumbnailFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _videoFile = File(result.files.single.path!);
      });
    }
  }

  Future<String> _uploadFile(File file, String bucketId, String fileType) async {
    final storage = ref.read(storageProvider);
    final uniqueId = const Uuid().v4();

    try {
      final uploadResult = await storage.createFile(
        bucketId: bucketId,
        fileId: uniqueId,
        file: InputFile(path: file.path),
      );
      return uploadResult.$id;
    } catch (e) {
      rethrow;
    }
  }

  void _uploadContent() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final database = ref.read(databaseProvider);
    final currentUser = await ref.read(currentUserProvider.future);

    if (_videoFile == null || _thumbnailFile == null || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide all fields')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Sequentially upload video and thumbnail
      final videoId = await _uploadFile(_videoFile!, 'bucket', 'Video');
      final thumbnailId = await _uploadFile(_thumbnailFile!, 'bucket', 'Thumbnail');

      final contentId = const Uuid().v4();

      final content = ContentModel(
        id: contentId,
        title: title,
        description: description,
        videoUrl: '$endpoint/storage/buckets/bucket/files/$videoId/view?project=$projectId&mode=admin',
        thumbnailUrl: '$endpoint/storage/buckets/bucket/files/$thumbnailId/view?project=$projectId&mode=admin',
        userId: currentUser.$id,
        likesCount: 0,
        comments: [],
        views: 0,
        subscribersCount: 0,
      );

      await database.createDocument(
        databaseId: 'data',
        collectionId: 'content',
        documentId: content.id,
        data: content.toMap(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content uploaded successfully')),
      );

      // No need to navigate to another page, stay on the same page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload Failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
        backgroundColor: Colors.red,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Video',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                const SizedBox(height: 16),
                _thumbnailFile == null
                    ? GestureDetector(
                        onTap: _pickThumbnail,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Center(child: Text('Select Thumbnail')),
                        ),
                      )
                    : Image.file(
                        _thumbnailFile!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickThumbnail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Change Thumbnail'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                _videoFile == null
                    ? GestureDetector(
                        onTap: _pickVideo,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[300],
                          child: const Center(child: Text('Select Video')),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Video Selected:'),
                            const SizedBox(height: 8),
                            Text(_videoFile!.path),
                          ],
                        ),
                      ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Change Video'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _uploadContent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Upload Content'),
                ),
              ],
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
