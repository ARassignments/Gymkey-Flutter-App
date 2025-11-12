class CartItem {
  final String bookId;
  final String title;
  final String author;
  final String imageUrl;
  final double price;
  int quantity; // quantity in cart
  final int stock; // total available stock from product

  CartItem({
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.price,
    this.quantity = 1,
    this.stock = 10,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'stock': stock,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      bookId: map['bookId'],
      title: map['title'],
      author: map['author'],
      imageUrl: map['imageUrl'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      stock: map['stock'] ?? 10, // default to 10 if stock not provided
    );
  }
}
