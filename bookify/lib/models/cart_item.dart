class CartItem {
  final String bookId;
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;
  final int stock;

  CartItem({
    required this.bookId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.stock,
  });

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'title': title,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': quantity,
        'stock': stock,
      };

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      bookId: map['bookId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      stock: map['stock'] ?? 0,
    );
  }
}