import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../utils/app_theme.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 250), _scrollToBottom);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuad,
      );
    }
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    ref.read(chatProvider.notifier).sendMessage(text);

    // Scroll to bottom immediately after state updates
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Watch for errors and display SnackBar
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.error!,
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(12),
          ),
        );
        ref.read(chatProvider.notifier).clearError();
      }

      // Auto scroll when new messages arrive
      if (previous?.messages.length != next.messages.length ||
          previous?.isTyping != next.isTyping) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Clean premium off-white background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shape: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_outlined, // Material Symbols Outlined
            color: Color(0xFF111827),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined, // Material Symbols Outlined
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lễ Tân AI',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Hỗ trợ đặt phòng & thông tin 24/7',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (chatState.messages.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline, // Material Symbols Outlined
                color: Color(0xFF6B7280),
              ),
              tooltip: 'Xóa cuộc trò chuyện',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Xóa lịch sử?',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Bạn có chắc chắn muốn xóa toàn bộ lịch sử tin nhắn của phiên này?',
                      style: GoogleFonts.dmSans(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Hủy',
                          style: GoogleFonts.dmSans(color: const Color(0xFF6B7280)),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(chatProvider.notifier).clearChat();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Xóa',
                          style: GoogleFonts.dmSans(color: const Color(0xFFE57373), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chatState.messages.isEmpty
                  ? _buildWelcomeMessage()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == chatState.messages.length) {
                          return _buildTypingIndicator();
                        }
                        final message = chatState.messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
            ),
            _buildInputSection(chatState.isTyping),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_outlined,
                  color: AppTheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Xin chào! Tôi có thể giúp gì cho bạn?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tôi là Trợ lý Lễ tân AI. Bạn có thể hỏi tôi về các phòng trống ở Đà Nẵng, Hà Nội, TP.HCM, xem các đánh giá của homestay hoặc tư vấn đặt phòng phù hợp.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSuggestionChip('Tìm phòng ở Đà Nẵng cho 2 người'),
                  const SizedBox(height: 10),
                  _buildSuggestionChip('Homestay nào giá dưới 1 triệu?'),
                  const SizedBox(height: 10),
                  _buildSuggestionChip('Cho tôi xem đánh giá của Homestay Biển'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _focusNode.requestFocus();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.04),
          border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedRoomsList(List<SuggestedRoom> rooms) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Container(
      height: 200,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                        child: room.thumbnailUrl != null
                            ? CachedNetworkImage(
                                imageUrl: room.thumbnailUrl!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFFF3F4F6),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFFF3F4F6),
                                  child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9CA3AF)),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9CA3AF)),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                room.ratingAvg.toStringAsFixed(1),
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Color(0xFF6B7280), size: 12),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              room.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${currencyFormat.format(room.pricePerNight)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () {
                                context.push('/room-detail/${room.roomId}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Đặt ngay',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == Role.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            margin: EdgeInsets.only(
              left: isUser ? 48 : 16,
              right: isUser ? 16 : 48,
              top: 4,
              bottom: 4,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? AppTheme.primary : Colors.white,
              border: isUser ? null : Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              boxShadow: isUser
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: SelectableText(
              message.content,
              style: GoogleFonts.dmSans(
                color: isUser ? Colors.white : const Color(0xFF1F2937),
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
          ),
          if (!isUser && message.suggestedRooms != null && message.suggestedRooms!.isNotEmpty)
            _buildSuggestedRoomsList(message.suggestedRooms!),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 20,
              right: isUser ? 20 : 0,
              bottom: 12,
            ),
            child: Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: GoogleFonts.dmSans(
                color: const Color(0xFF9CA3AF),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Đang xử lý',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                LoadingAnimationWidget.threeArchedCircle(
                  color: AppTheme.primary,
                  size: 16,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 12),
            child: Text(
              'Lễ Tân AI...',
              style: GoogleFonts.dmSans(
                color: const Color(0xFF9CA3AF),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isTyping) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _focusNode.hasFocus ? AppTheme.primary : const Color(0xFFE5E7EB),
                  width: _focusNode.hasFocus ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: isTyping ? null : (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn của bạn...',
                        hintStyle: GoogleFonts.dmSans(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        filled: false,
                      ),
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF1F2937),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isTyping ? const Color(0xFFE5E7EB) : AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: isTyping ? null : _handleSend,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
