import '/Models/scrap_model.dart';

class ScrapsResponse {
  final List<ScrapModel> scraps;
  final bool success;

  ScrapsResponse({required this.scraps, required this.success});

  factory ScrapsResponse.fromJson(Map<String, dynamic> json) {
    return ScrapsResponse(
      scraps: (json['ScrapList'] as List)
          .map((item) => ScrapModel.fromJson(item))
          .toList(),
      success: json['Success'],
    );
  }
}
