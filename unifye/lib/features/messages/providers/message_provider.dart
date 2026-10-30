import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../repositories/i_message_repository.dart';
import '../repositories/message_respository.dart';

final httpClientProvider =
Provider<http.Client>((ref) {
  return http.Client();
});

final messageRepositoryProvider =
Provider<IMessageRepository>((ref) {
  return MessageRepository(
    client: ref.watch(httpClientProvider),

    // Replace with your real API URL
    baseUrl: 'https://your-api-url.com/api',
  );
});