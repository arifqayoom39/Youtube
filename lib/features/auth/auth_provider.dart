import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import 'package:youtube/features/models/content_model.dart';

// Client setup
final client = Provider<Client>((ref) {
  return Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('641c98b6c77b8608f2e5');
});

// Providers for Appwrite services
final authProvider = Provider<Account>((ref) {
  return Account(ref.read(client));
});

final databaseProvider = Provider<Databases>((ref) {
  return Databases(ref.read(client));
});

final storageProvider = Provider<Storage>((ref) {
  return Storage(ref.read(client));
});

// Provider to fetch current user
final currentUserProvider = FutureProvider<models.User?>((ref) async {
  try {
    final auth = ref.read(authProvider);
    final user = await auth.get();
    return user;
  } catch (_) {
    return null;
  }
});


final authStateProvider = FutureProvider<models.User?>((ref) async {
  try {
    final user = await ref.read(authProvider).get();
    return user;
  } catch (_) {
    return null;
  }
});

// Provider for user login
final loginProvider = FutureProvider.family<void, Map<String, String>>((ref, credentials) async {
  final auth = ref.read(authProvider);
  await auth.createEmailPasswordSession(email: credentials['email']!, password: credentials['password']!);
});

// Provider for user signup
final signupProvider = FutureProvider.family<void, Map<String, String>>((ref, credentials) async {
  final auth = ref.read(authProvider);
  final database = ref.read(databaseProvider);

  // Create user in Appwrite authentication
  final user = await auth.create(
    email: credentials['email']!,
    password: credentials['password']!,
    userId: 'unique()',
    name: credentials['name']!,
  );

  // Save user data in the 'users' collection
  await database.createDocument(
    databaseId: '64266e17ca25c2989d87',
    collectionId: '64266e290b1360e8d4b5',
    documentId: user.$id,  // Using the user ID from Appwrite
    data: {
      'id': user.$id,
      'email': credentials['email']!,
      'name': credentials['name']!,
      
    },
  );
});

// Provider to fetch user content
final userContentProvider = FutureProvider<List<ContentModel>>((ref) async {
  final database = ref.read(databaseProvider);
  final currentUser = await ref.read(currentUserProvider.future);

  if (currentUser == null) {
    return [];
  }

  final response = await database.listDocuments(
    databaseId: '64266e17ca25c2989d87',
    collectionId: '66d72ebd003532c7221e',
    queries: [
      Query.equal('user_id', currentUser.$id),
    ],
  );

  return response.documents.map((doc) => ContentModel.fromMap(doc.data)).toList();
});

