class CountryItem {
  final String id;
  final String name;
  final String code;

  const CountryItem({
    required this.id,
    required this.name,
    required this.code,
  });
}

class ShippingPriceItem {
  final String type; // 'aérien' | 'maritime'
  final double minWeight;
  final double maxWeight;
  final double pricePerKg;

  const ShippingPriceItem({
    required this.type,
    required this.minWeight,
    required this.maxWeight,
    required this.pricePerKg,
  });
}

class ServicePriceItem {
  final String serviceType; // 'récupération' | 'livraison'
  final double price;

  const ServicePriceItem({
    required this.serviceType,
    required this.price,
  });
}

class CountryPricing {
  final CountryItem country;
  final List<ShippingPriceItem> shippingPrices;
  final List<ServicePriceItem> servicePrices;

  const CountryPricing({
    required this.country,
    required this.shippingPrices,
    required this.servicePrices,
  });
}
