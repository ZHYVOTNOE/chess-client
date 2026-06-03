import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/repositories/friend_repository_impl.dart';
import 'data/services/friend_service.dart';
import 'domain/repositories/friend_repository.dart';
import 'presentation/cubits/social_cubit.dart';

final sl = GetIt.instance;

void initSocialDI() {
  // Repositories
  sl.registerLazySingleton<FriendRepository>(() => FriendRepositoryImpl(Supabase.instance.client));

  // Services
  sl.registerLazySingleton<FriendService>(() => FriendService(sl(), Supabase.instance.client));

  // Cubits
  sl.registerFactory<SocialCubit>(() => SocialCubit(sl(), sl()));
}
