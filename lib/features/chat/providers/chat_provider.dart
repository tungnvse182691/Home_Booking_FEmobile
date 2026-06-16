import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../models/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? error;
  final String? sessionId;

  ChatState({
    required this.messages,
    required this.isTyping,
    this.error,
    this.sessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? error,
    String? sessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      error: error, // Will clear error if not provided
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Dio _dio;

  ChatNotifier(this._dio)
      : super(ChatState(
          messages: [],
          isTyping: false,
          sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        ));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      role: Role.user,
      content: text,
      timestamp: DateTime.now(),
    );

    // Add user's message immediately and set typing state
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isTyping: true,
      error: null,
    );

    try {
      final response = await _dio.post(
        '/api/chat',
        data: {
          'message': text,
          'sessionId': state.sessionId,
        },
      );

      final data = response.data;
      if (data != null && data['success'] == true) {
        final reply = data['data']['reply'] as String;
        final responseSessionId = data['data']['sessionId'] as String?;

        List<SuggestedRoom>? suggestedRooms;
        final roomsRaw = data['data']['suggestedRooms'];
        if (roomsRaw is List) {
          suggestedRooms = roomsRaw
              .map((r) => SuggestedRoom.fromJson(r as Map<String, dynamic>))
              .toList();
        }

        final aiMessage = ChatMessage(
          role: Role.ai,
          content: reply,
          timestamp: DateTime.now(),
          suggestedRooms: suggestedRooms,
        );

        state = state.copyWith(
          messages: [...state.messages, aiMessage],
          isTyping: false,
          sessionId: responseSessionId ?? state.sessionId,
        );
      } else {
        throw DioException(
          requestOptions: RequestOptions(path: '/api/chat'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/chat'),
            data: data,
            statusCode: 500,
          ),
          message: data?['message'] ?? 'Lỗi hệ thống không xác định',
        );
      }
    } catch (e) {
      String errorMessage = 'Không thể gửi tin nhắn. Vui lòng kiểm tra lại kết nối.';
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          errorMessage = e.response?.data['message']?.toString() ?? errorMessage;
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
      }
      
      state = state.copyWith(
        isTyping: false,
        error: errorMessage,
      );
    }
  }

  void clearError() {
    state = ChatState(
      messages: state.messages,
      isTyping: state.isTyping,
      sessionId: state.sessionId,
      error: null,
    );
  }

  void clearChat() {
    state = ChatState(
      messages: [],
      isTyping: false,
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final dio = ref.watch(dioProvider);
  return ChatNotifier(dio);
});
