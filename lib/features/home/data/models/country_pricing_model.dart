import '../../domain/entities/country_pricing.dart';

class CountryItemModel extends CountryItem {
  const CountryItemModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory CountryItemModel.fromJson(Map<String, dynamic> json) =>
      CountryItemModel(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
      );
}

class ShippingPriceItemModel extends ShippingPriceItem {
  const ShippingPriceItemModel({
    required super.type,
    required super.minWeight,
    required super.maxWeight,
    required super.pricePerKg,
  });

  factory ShippingPriceItemModel.fromJson(Map<String, dynamic> json) =>
      ShippingPriceItemModel(
        type: json['type'] as String,
        minWeight: (json['minWeight'] as num).toDouble(),
        maxWeight: (json['maxWeight'] as num).toDouble(),
        pricePerKg: (json['pricePerKg'] as num).toDouble(),
      );
}

class ServicePriceItemModel extends ServicePriceItem {
  const ServicePriceItemModel({
    required super.serviceType,
    required super.price,
  });

  factory ServicePriceItemModel.fromJson(Map<String, dynamic> json) =>
      ServicePriceItemModel(
        serviceType: json['serviceType'] as String,
        price: (json['price'] as num).toDouble(),
      );
}

class CountryPricingModel extends CountryPricing {
  const CountryPricingModel({
    required super.country,
    required super.shippingPrices,
    required super.servicePrices,
  });

  factory CountryPricingModel.fromJson(Map<String, dynamic> json) {
    final countryJson = json['country'] as Map<String, dynamic>;
    final shippingList = (json['shippingPrices'] as List? ?? [])
        .map((e) => ShippingPriceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final serviceList = (json['servicePrices'] as List? ?? [])
        .map((e) => ServicePriceItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return CountryPricingModel(
      country: CountryItemModel.fromJson(countryJson),
      shippingPrices: shippingList,
      servicePrices: serviceList,
    );
  }
}
