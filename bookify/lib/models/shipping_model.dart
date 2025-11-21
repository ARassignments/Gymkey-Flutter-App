import 'package:flutter/material.dart';

class ShippingModel {
  final String id;
  final String title;
  final int minDays;
  final int maxDays;
  final double price;
  final IconData icon;

  ShippingModel({
    required this.id,
    required this.title,
    required this.minDays,
    required this.maxDays,
    required this.price,
    required this.icon,
  });

  /// Formatted arrival (e.g. "Estimated Arrival, Dec 20–23")
  String getArrivalDate() {
    final now = DateTime.now();
    final start = now.add(Duration(days: minDays));
    final end = now.add(Duration(days: maxDays));
    return "Estimated Arrival, ${_formatDate(start)}–${_formatDate(end)}";
  }

  String _formatDate(DateTime dt) {
    const months = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    final mon = months[dt.month - 1];
    return "$mon ${dt.day}";
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'minDays': minDays,
      'maxDays': maxDays,
      'price': price,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
    };
  }
}
