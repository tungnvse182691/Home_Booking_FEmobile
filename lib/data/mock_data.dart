class User {
  String name;
  String phone;
  bool isLoggedIn;

  User({
    required this.name,
    required this.phone,
    this.isLoggedIn = false,
  });
}

class Homestay {
  final String id;
  final String name;
  final String location;
  final double price;
  final double rating;
  final String imageUrl;

  Homestay({
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });
}

class MockData {
  static User currentUser = User(
    name: 'Khách hàng',
    phone: '',
    isLoggedIn: false,
  );

  static List<String> categories = ['Tất cả', 'Căn hộ', 'Nhà riêng', 'Villa', 'Studio'];

  static List<Homestay> homestays = [
    Homestay(
      id: '1',
      name: 'Cozy Forest House',
      location: 'Đà Lạt, Lâm Đồng',
      price: 1200000,
      rating: 4.8,
      imageUrl: 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=500&q=80',
    ),
    Homestay(
      id: '2',
      name: 'Ocean View Villa',
      location: 'Vũng Tàu, Bà Rịa',
      price: 2500000,
      rating: 4.9,
      imageUrl: 'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=500&q=80',
    ),
    Homestay(
      id: '3',
      name: 'Modern City Studio',
      location: 'Quận 1, TP. HCM',
      price: 850000,
      rating: 4.5,
      imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=500&q=80',
    ),
  ];
}
