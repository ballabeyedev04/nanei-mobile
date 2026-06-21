import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/env.dart';
import 'core/services/token_service.dart';
import 'core/utils/dio_logger_interceptor.dart';
import 'core/theme/theme_notifier.dart';

// Contacts
import 'features/contacts/data/datasources/contact_remote_datasource.dart';
import 'features/contacts/data/repositories/contact_repository_impl.dart';
import 'features/contacts/domain/repositories/contact_repository.dart';
import 'features/contacts/domain/usecases/get_contacts.dart';
import 'features/contacts/domain/usecases/create_contact.dart';
import 'features/contacts/domain/usecases/delete_contact.dart';
import 'features/contacts/presentation/cubit/contacts_cubit.dart';

// Réclamations
import 'features/reclamations/data/datasources/reclamation_remote_datasource.dart';
import 'features/reclamations/data/repositories/reclamation_repository_impl.dart';
import 'features/reclamations/domain/repositories/reclamation_repository.dart';
import 'features/reclamations/presentation/cubit/reclamations_cubit.dart';

// Avis
import 'features/avis/data/datasources/avis_remote_datasource.dart';
import 'features/avis/presentation/cubit/avis_cubit.dart';

// Auth
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Home / Colis
import 'features/home/data/datasources/colis_remote_datasource.dart';
import 'features/home/data/repositories/colis_repository_impl.dart';
import 'features/home/domain/repositories/colis_repository.dart';
import 'features/home/domain/usecases/envoyer_colis.dart';
import 'features/home/domain/usecases/get_colis_envoyes.dart';
import 'features/home/domain/usecases/get_colis_recus.dart';
import 'features/home/domain/usecases/get_statistiques_colis.dart';
import 'features/home/domain/usecases/get_notifications.dart';
import 'features/home/domain/usecases/marquer_notification_lue.dart';
import 'features/home/domain/usecases/rechercher_client.dart';
import 'features/home/domain/usecases/get_countries.dart';
import 'features/home/domain/usecases/get_pricing_by_country.dart';
import 'features/home/presentation/bloc/colis_bloc.dart';

// Paiement
import 'features/paiement/data/datasources/paiement_remote_datasource.dart';
import 'features/paiement/data/repositories/paiement_repository_impl.dart';
import 'features/paiement/domain/repositories/paiement_repository.dart';
import 'features/paiement/domain/usecases/get_mes_paiements.dart';
import 'features/paiement/domain/usecases/initier_paiement.dart';
import 'features/paiement/presentation/bloc/paiement_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Dotenv ─────────────────────────────────────────────────────────────────
  await dotenv.load(fileName: '.env');

  // ── Services externes ──────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);

  sl.registerLazySingleton(() => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ));

  // ── Core ───────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => TokenService(secureStorage: sl()));

  // ── Dio ────────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 60),
        contentType: 'application/json',
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final path = options.path.split('?')[0].trim();
        final isAuth = path.endsWith(Env.authLogin) ||
            path.endsWith(Env.authRegister);
        if (!isAuth) {
          final token = await sl<TokenService>().getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));

    dio.interceptors.add(AppDioInterceptor());

    return dio;
  });

  // ── Feature : Auth ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerFactory(
    () => AuthBloc(loginUser: sl(), registerUser: sl()),
  );

  // ── Feature : Home / Colis ─────────────────────────────────────────────────
  sl.registerLazySingleton<ColisRemoteDataSource>(
    () => ColisRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ColisRepository>(
    () => ColisRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetColisEnvoyes(sl()));
  sl.registerLazySingleton(() => GetColisRecus(sl()));
  sl.registerLazySingleton(() => GetStatistiquesColis(sl()));
  sl.registerLazySingleton(() => EnvoyerColis(sl()));
  sl.registerLazySingleton(() => RechercherClient(sl()));
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarquerNotificationLue(sl()));
  sl.registerLazySingleton(() => GetCountries(sl()));
  sl.registerLazySingleton(() => GetPricingByCountry(sl()));
  // ── Feature : Paiement ────────────────────────────────────────────────────
  sl.registerLazySingleton<PaiementRemoteDataSource>(
    () => PaiementRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<PaiementRepository>(
    () => PaiementRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetMesPaiements(sl()));
  sl.registerLazySingleton(() => InitierPaiement(sl()));
  sl.registerFactory(() => PaiementBloc(
    getMesPaiements: sl(),
    initierPaiement: sl(),
  ));

  sl.registerFactory(() => ColisBloc(
        getColisEnvoyes: sl(),
        getColisRecus: sl(),
        getStatistiques: sl(),
        envoyerColis: sl(),
        rechercherClient: sl(),
        getNotifications: sl(),
        marquerNotificationLue: sl(),
      ));

  // ── Feature : Contacts ────────────────────────────────────────────────────
  sl.registerLazySingleton<ContactRemoteDataSource>(
    () => ContactRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ContactRepository>(
    () => ContactRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetContacts(sl()));
  sl.registerLazySingleton(() => CreateContact(sl()));
  sl.registerLazySingleton(() => DeleteContact(sl()));
  sl.registerFactory(() => ContactsCubit(
        getContacts: sl(),
        createContact: sl(),
        deleteContact: sl(),
      ));

  // ── Feature : Réclamations ────────────────────────────────────────────────
  sl.registerLazySingleton<ReclamationRemoteDataSource>(
    () => ReclamationRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<ReclamationRepository>(
    () => ReclamationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory(() => ReclamationsCubit(repository: sl()));

  // ── Feature : Avis ────────────────────────────────────────────────────────
  sl.registerLazySingleton<AvisRemoteDataSource>(
    () => AvisRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerFactory(() => AvisCubit(dataSource: sl()));

  // ── Theme ─────────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ThemeNotifier());
}
