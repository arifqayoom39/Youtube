import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:uuid/uuid.dart';
import '../models/content_model.dart';
import 'package:youtube/features/auth/auth_provider.dart';

class UploadContentPage extends ConsumerStatefulWidget {
  @override
  _UploadContentPageState createState() => _UploadContentPageState();
}

class _UploadContentPageState extends ConsumerState<UploadContentPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _videoFile;
  File? _thumbnailFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  final Client _client = Client();
  final String endpoint = 'https://cloud.appwrite.io/v1';
  final String projectId = '641c98b6c77b8608f2e5';

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
    final uniqueId = Uuid().v4();

    try {
      final uploadResult = await storage.createFile(
        bucketId: bucketId,
        fileId: uniqueId,
        file: InputFile(path: file.path),
      );
      print('$fileType uploaded successfully: ${uploadResult.$id}');
      return uploadResult.$id;
    } catch (e) {
      print('Upload Failed for $fileType: $e');
      throw e;
    }
  }

  void _uploadContent() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final database = ref.read(databaseProvider);
    final currentUser = await ref.read(currentUserProvider.future);

    if (_videoFile == null || _thumbnailFile == null || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide all fields')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Sequentially upload video and thumbnail
      final videoId = await _uploadFile(_videoFile!, '6427d4792ddd2c15bbdd', 'Video');
      final thumbnailId = await _uploadFile(_thumbnailFile!, '6427d4792ddd2c15bbdd', 'Thumbnail');

      final contentId = Uuid().v4();

      final content = ContentModel(
        id: contentId,
        title: title,
        description: description,
        videoUrl: '$endpoint/storage/buckets/6427d4792ddd2c15bbdd/files/$videoId/view?project=$projectId&mode=admin',
        thumbnailUrl: '$endpoint/storage/buckets/6427d4792ddd2c15bbdd/files/$thumbnailId/view?project=$projectId&mode=admin',
        userId: currentUser.$id,
        likesCount: 0,
        comments: [],
        views: 0,
        subscribersCount: 0,
      );

      await database.createDocument(
        databaseId: '64266e17ca25c2989d87',
        collectionId: '66d72ebd003532c7221e',
        documentId: content.id,
        data: content.toMap(),
      );
      print('Content saved successfully: ${content.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Content uploaded successfully')),
      );

      // No need to navigate to another page, stay on the same page
    } catch (e) {
      print('Upload Failed: $e');
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
        title: Text('Upload Content'),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
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
                SizedBox(height: 16),
                _thumbnailFile == null
                    ? GestureDetector(
                        onTap: _pickThumbnail,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[300],
                          child: Center(child: Text('Select Thumbnail')),
                        ),
                      )
                    : Image.file(
                        _thumbnailFile!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickThumbnail,
                  child: Text('Change Thumbnail'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                SizedBox(height: 16),
                _videoFile == null
                    ? GestureDetector(
                        onTap: _pickVideo,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[300],
                          child: Center(child: Text('Select Video')),
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Video Selected:'),
                            SizedBox(height: 8),
                            Text(_videoFile!.path),
                          ],
                        ),
                      ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickVideo,
                  child: Text('Change Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _uploadContent,
                  child: Text('Upload Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
