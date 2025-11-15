import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatelessWidget {
  final String categoryTitle;

  const ProductsPage({
    super.key,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle)),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("books")
           .where("category", isEqualTo: categoryTitle) 
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];

              return Card(
                elevation: 3,
                child: ListTile(
                  leading: Image.network(
                    p["cover_image_url"],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(p["title"]),
                  subtitle: Text("Rs ${p["price"]}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
