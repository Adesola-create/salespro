class TransactionLog {
  final List<Map<String, dynamic>> cart;
  final double total;
  final DateTime timestamp;
  final String name;
  final String phone;
  final String salesID;
  final String servedBy;
  final String payMethod;
  final bool sent;

  TransactionLog({
    required this.cart,
    required this.total,
    required this.name,
    required this.phone,
    required this.salesID,
    required this.sent,
    required this.servedBy,
    required this.payMethod,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'servedBy': servedBy,
      'payMethod': payMethod,
      'sent': false,
      'name': name,
      'phone': phone,
      'cart': cart,
      'total': total,
      'salesID': salesID,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static TransactionLog fromJson(Map<String, dynamic> json) {
    return TransactionLog(
      servedBy: json['servedBy'],
      payMethod: json['payMethod'],
      sent: json['sent'],
      name: json['name'],
      phone: json['phone'],
      cart: List<Map<String, dynamic>>.from(json['cart']),
      total: json['total'],
      salesID: json['salesID'],
    );
  }
}
