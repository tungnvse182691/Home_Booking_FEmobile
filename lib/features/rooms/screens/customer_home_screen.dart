import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_theme.dart';
import '../../../widgets/animated_pressable_card.dart';
import '../models/room_model.dart';
import '../providers/room_list_provider.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  Offset? _fabPosition;

  static const List<String> _cities = [
    'Tất cả',
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Đà Nẵng',
    'Đà Lạt',
    'Nha Trang',
    'Vũng Tàu',
  ];

  static const double _minRoomPrice = 0;
  static const double _maxRoomPrice = 10000000;

  String _selectedCity = '';
  String _selectedRoomTypeId = '';
  final List<String> _selectedAmenities = [];
  double _minPrice = _minRoomPrice;
  double _maxPrice = _maxRoomPrice;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Đặt lại thanh tìm kiếm và bộ lọc mỗi khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.clear();
      setState(() {
        _selectedCity = '';
        _selectedRoomTypeId = '';
        _selectedAmenities.clear();
        _minPrice = _minRoomPrice;
        _maxPrice = _maxRoomPrice;
      });
      // Tải lại danh sách phòng không có bộ lọc
      ref.read(roomListProvider.notifier).applyFilters(RoomListFilter());
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(roomListProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(roomListProvider.notifier).refresh();
  }

  void _applyFilters() {
    final notifier = ref.read(roomListProvider.notifier);
    notifier.applyFilters(
      RoomListFilter(
        searchQuery: _searchController.text.trim(),
        city: _selectedCity,
        roomTypeId: _selectedRoomTypeId,
        selectedAmenities: List.from(_selectedAmenities),
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _applyFilters);
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomListProvider);
    final roomTypesAsync = ref.watch(roomTypesProvider);
    final amenitiesAsync = ref.watch(amenitiesProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('StayEase'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Tìm kiếm homestay...',
              leading: const Icon(Icons.search),
          onChanged: (value) {
            setState(() {});
            _onSearchChanged(value);
          },
              onSubmitted: (_) => _applyFilters(),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _applyFilters();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;

          if (_fabPosition == null || _fabPosition!.dx <= 0 || _fabPosition!.dy <= 0) {
            _fabPosition = Offset(maxWidth - 72, maxHeight - 72);
          } else if (_fabPosition!.dx > maxWidth - 72 || _fabPosition!.dy > maxHeight - 72) {
            _fabPosition = Offset(
              _fabPosition!.dx.clamp(16.0, maxWidth - 72.0),
              _fabPosition!.dy.clamp(16.0, maxHeight - 72.0),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _refresh,
                child: AnimationLimiter(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: _buildFilterPanel(roomTypesAsync, currencyFormat),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: amenitiesAsync.when(
                            data: (amenities) => _buildAmenitiesStrip(amenities),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      if (roomState.isLoading && roomState.items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (roomState.error != null && roomState.items.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                roomState.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        )
                      else if (roomState.items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text('Không tìm thấy phòng nào phù hợp'),
                          ),
                        )
                      else ...[
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              mainAxisExtent: 360,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final room = roomState.items[index];
                                return AnimationConfiguration.staggeredGrid(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  columnCount: 1,
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: _RoomCard(
                                        room: room,
                                        currencyFormat: currencyFormat,
                                        onTap: () => context.push('/rooms/${room.roomId}'),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: roomState.items.length,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: roomState.isLoadMore
                                ? const Center(child: CircularProgressIndicator())
                                : roomState.hasMore
                                    ? Center(
                                        child: TextButton(
                                          onPressed: () => ref.read(roomListProvider.notifier).loadMore(),
                                          child: const Text('Load More'),
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned(
                left: _fabPosition!.dx,
                top: _fabPosition!.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      double newX = _fabPosition!.dx + details.delta.dx;
                      double newY = _fabPosition!.dy + details.delta.dy;

                      newX = newX.clamp(16.0, maxWidth - 72.0);
                      newY = newY.clamp(16.0, maxHeight - 72.0);

                      _fabPosition = Offset(newX, newY);
                    });
                  },
                  onTap: () => context.push('/chat'),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.forum_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPanel(
    AsyncValue<List<RoomType>> roomTypesAsync,
    NumberFormat currencyFormat,
  ) {
    final hasActiveFilters = _selectedCity.isNotEmpty ||
        _selectedRoomTypeId.isNotEmpty ||
        _selectedAmenities.isNotEmpty ||
        _minPrice != _minRoomPrice ||
        _maxPrice != _maxRoomPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasActiveFilters) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCity = '';
                  _selectedRoomTypeId = '';
                  _selectedAmenities.clear();
                  _minPrice = _minRoomPrice;
                  _maxPrice = _maxRoomPrice;
                });
                _applyFilters();
              },
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text(
                'Xóa tất cả bộ lọc',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none, // Ngăn chặn cắt khi cuộn ngang
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Thành phố',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                      ),
                      icon: _selectedCity.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                setState(() => _selectedCity = '');
                                _applyFilters();
                              },
                              child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            )
                          : const Icon(Icons.arrow_drop_down),
                      items: _cities
                          .map(
                            (city) => DropdownMenuItem(
                              value: city == 'Tất cả' ? '' : city,
                              child: Text(city),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedCity = value ?? '');
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'Loại phòng',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    roomTypesAsync.when(
                      data: (roomTypes) => DropdownButtonFormField<String>(
                        value: _selectedRoomTypeId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                        ),
                        icon: _selectedRoomTypeId.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  setState(() => _selectedRoomTypeId = '');
                                  _applyFilters();
                                },
                                child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              )
                            : const Icon(Icons.arrow_drop_down),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Tất cả loại phòng')),
                          ...roomTypes.map(
                            (roomType) => DropdownMenuItem(
                              value: roomType.roomTypeId,
                              child: Text(roomType.name),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRoomTypeId = value ?? '');
                          _applyFilters();
                        },
                      ),
                      loading: () => InputDecorator(
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                        ),
                        child: const SizedBox(
                          height: 20,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      ),
                      error: (_, __) => DropdownButtonFormField<String>(
                        value: _selectedRoomTypeId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                        ),
                        icon: _selectedRoomTypeId.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  setState(() => _selectedRoomTypeId = '');
                                  _applyFilters();
                                },
                                child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                              )
                            : const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('Tất cả loại phòng')),
                        ],
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Giá: ${currencyFormat.format(_minPrice)} - ${currencyFormat.format(_maxPrice)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        RangeSlider(
          values: RangeValues(_minPrice, _maxPrice),
          min: _minRoomPrice,
          max: _maxRoomPrice,
          divisions: 20,
          labels: RangeLabels(
            currencyFormat.format(_minPrice),
            currencyFormat.format(_maxPrice),
          ),
          onChanged: (values) {
            setState(() {
              _minPrice = values.start;
              _maxPrice = values.end;
            });
          },
          onChangeEnd: (_) => _applyFilters(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesStrip(List<Amenity> amenities) {
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiện ích nổi bật',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: amenities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final amenity = amenities[index];
              final isSelected = _selectedAmenities.contains(amenity.amenityId);

              return FilterChip(
                label: Text(amenity.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity.amenityId);
                    } else {
                      _selectedAmenities.remove(amenity.amenityId);
                    }
                  });
                  _applyFilters();
                },
                selectedColor: AppTheme.primary.withOpacity(0.12),
                checkmarkColor: AppTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? AppTheme.primary : const Color(0xFFEEEEEE),
                    width: 1,
                  ),
                ),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomListItem room;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPressableCard(
      onTap: onTap,
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'room_image_${room.roomId}',
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: room.thumbnailUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const Icon(Icons.home_outlined, size: 48, color: AppTheme.textHint),
                      )
                    : room.thumbnailUrl.startsWith('http')
                        ? Image.network(
                            room.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF3F4F6),
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined, size: 40, color: AppTheme.textHint),
                            ),
                          )
                        : Image.file(
                            File(room.thumbnailUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFF3F4F6),
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined, size: 40, color: AppTheme.textHint),
                            ),
                          ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          room.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currencyFormat.format(room.pricePerNight)} / đêm',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            room.rating.toStringAsFixed(1),
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            ' (${room.reviewCount})',
                            style: GoogleFonts.dmSans(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
