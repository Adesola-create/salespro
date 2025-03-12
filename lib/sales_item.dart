class SalesItem {
  final String id;
  final String title;
  final String note;
  final String category;
  final double price;
  final String qty;
  final String barcode;
  final String photo;

  SalesItem({
    required this.id,
    required this.title,
    required this.note,
    required this.category,
    required this.price,
    required this.qty,
    required this.barcode,
    required this.photo,
  });

  factory SalesItem.fromJson(Map<String, dynamic> json) {
    return SalesItem(
      id: json['id'],
      title: json['title'],
      note: json['note'],
      category: json['category'],
      price: json['price'].toDouble(),
      qty: json['qty'],
      barcode: json['barcode'],
      photo: json['photo'],
    );
  }
}
