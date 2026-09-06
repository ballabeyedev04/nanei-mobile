import '../../domain/entities/prix_calcule.dart';

class PrixCalculeModel extends PrixCalcule {
  const PrixCalculeModel({
    required super.shippingPrice,
    required super.pickupPrice,
    required super.deliveryPrice,
    required super.total,
  });

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  factory PrixCalculeModel.fromJson(Map<String, dynamic> json) {
    return PrixCalculeModel(
      shippingPrice: _d(json['shippingPrice']),
      pickupPrice: _d(json['pickupPrice']),
      deliveryPrice: _d(json['deliveryPrice']),
      total: _d(json['total']),
    );
  }
}
