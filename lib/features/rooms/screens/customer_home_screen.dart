import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_theme.dart';
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
  double _minPrice = _minRoomPrice;
  double _maxPrice = _maxRoomPrice;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
        title: const Text('HomeBooking'),
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
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                      return _RoomCard(
                        room: room,
                        currencyFormat: currencyFormat,
                        onTap: () => context.push('/rooms/${room.roomId}'),
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
    );
  }

  Widget _buildFilterPanel(
    AsyncValue<List<RoomType>> roomTypesAsync,
    NumberFormat currencyFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: _selectedCity.isEmpty ? null : _selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
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
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: roomTypesAsync.when(
                  data: (roomTypes) => DropdownButtonFormField<String>(
                    value: _selectedRoomTypeId.isEmpty ? null : _selectedRoomTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Room Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
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
                  loading: () => const InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Room Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: SizedBox(
                      height: 20,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                  error: (_, __) => DropdownButtonFormField<String>(
                    value: null,
                    decoration: const InputDecoration(
                      labelText: 'Room Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Tất cả loại phòng')),
                    ],
                    onChanged: (_) {},
                  ),
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
            itemCount: amenities.length.clamp(0, 10),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final amenity = amenities[index];
              return Chip(
                label: Text(amenity.name),
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
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: room.thumbnailUrl.startsWith('http')
                  ? Image.network(
                      room.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    )
                  : Image.file(
                      File(room.thumbnailUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image_outlined, size: 40),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          room.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${currencyFormat.format(room.pricePerNight)} / đêm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        room.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        ' (${room.reviewCount})',
                        style: const TextStyle(color: Colors.grey),
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
