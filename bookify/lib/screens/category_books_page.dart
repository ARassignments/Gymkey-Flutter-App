import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/bookcard.dart';
import 'book_detail_page.dart';

class CategoryBooksPage extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const CategoryBooksPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final booksQuery = FirebaseFirestore.instance
        .collection('books')
        .where('categoryId', isEqualTo: categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: MyColors.primary,
      ),
      backgroundColor: const Color(0xFFeeeeee),
      body: StreamBuilder<QuerySnapshot>(
        stream: booksQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No books found.'));
          }

          final books = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final data = books[index].data() as Map<String, dynamic>;
              final bookId = books[index].id;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailPage(bookId: bookId),
                    ),
                  );
                },
                child: BookCard(
                  bookId: bookId,
                  title: data['title'] ?? '',
                  author: data['author'] ?? '',
                  imagePath: data['cover_image_url'] ?? '',
                  category: data['genre'] ?? '',
                  price: (data['price'] ?? 0).toDouble(),
                  rating: (data['rating'] ?? 0).toDouble(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
