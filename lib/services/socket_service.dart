// lib/services/socket_service.dart
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class SocketService {
  static IO.Socket? _socket;
  static final StreamController<Map<String, dynamic>> _notificationController = 
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _commentController = 
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _statsController = 
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _suggestionNewController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _suggestionResolvedController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<Map<String, dynamic>> _chapterContentUpdatedController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notifications => _notificationController.stream;
  static Stream<Map<String, dynamic>> get comments => _commentController.stream;
  static Stream<Map<String, dynamic>> get statsUpdates => _statsController.stream;
  static Stream<Map<String, dynamic>> get suggestionNew => _suggestionNewController.stream;
  static Stream<Map<String, dynamic>> get suggestionResolved => _suggestionResolvedController.stream;
  static Stream<Map<String, dynamic>> get chapterContentUpdated => _chapterContentUpdatedController.stream;

  static Future<void> init() async {
    if (_socket != null && _socket!.connected) return;

    final token = await AuthService.getToken();
    if (token == null) return;

    // Use your backend URL
    const String baseUrl = "http://localhost:8000"; 

    _socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to Socket.io server');
    });

    _socket!.on('notification', (data) {
      print('New real-time notification: $data');
      _notificationController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('new_comment', (data) {
      print('New real-time comment: $data');
      _commentController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('comment_deleted', (data) {
      print('Comment deleted: $data');
      _commentController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('review_deleted', (data) {
      print('Review deleted: $data');
      _commentController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('stats_update', (data) {
      print('Real-time stats update: $data');
      _statsController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('suggestion_new', (data) {
      print('New suggestion event: $data');
      _suggestionNewController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('suggestion_resolved', (data) {
      print('Suggestion resolved event: $data');
      _suggestionResolvedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('chapter_content_updated', (data) {
      print('Chapter content updated event: $data');
      _chapterContentUpdatedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.onDisconnect((_) => print('Disconnected from Socket.io server'));
    _socket!.onConnectError((err) => print('Socket connection error: $err'));
  }

  static void joinChapter(int chapterId) {
    _socket?.emit('join_chapter', chapterId.toString());
  }

  static void leaveChapter(int chapterId) {
    _socket?.emit('leave_chapter', chapterId.toString());
  }

  static void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
