import '../entities/country_pricing.dart';
import '../repositories/colis_repository.dart';

class GetCountries {
  final ColisRepository repository;
  const GetCountries(this.repository);

  Future<List<CountryItem>> call() => repository.getCountries();
}
