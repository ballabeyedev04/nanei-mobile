import '../entities/country_pricing.dart';
import '../repositories/colis_repository.dart';

class GetPricingByCountry {
  final ColisRepository repository;
  const GetPricingByCountry(this.repository);

  Future<CountryPricing> call(String countryId) =>
      repository.getPricingByCountry(countryId);
}
