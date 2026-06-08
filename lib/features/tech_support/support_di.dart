import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/support_remote_datasource.dart';
import 'data/repositories/support_repository_impl.dart';
import 'domain/repositories/support_repository.dart';
import 'domain/usecases/close_ticket_usecase.dart';
import 'domain/usecases/create_ticket_usecase.dart';
import 'domain/usecases/get_admin_tickets_usecase.dart';
import 'domain/usecases/get_my_ticket_usecase.dart';
import 'domain/usecases/send_message_usecase.dart';
import 'presentation/cubits/support_cubit.dart';

void setupSupportDI(GetIt sl) {
  // DataSource
  sl.registerLazySingleton<SupportRemoteDataSource>(
    () => SupportRemoteDataSource(Supabase.instance.client),
  );

  // Repository
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositoryImpl(sl<SupportRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMyTicketUseCase(sl<SupportRepository>()));
  sl.registerLazySingleton(() => CreateTicketUseCase(sl<SupportRepository>()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl<SupportRepository>()));
  sl.registerLazySingleton(
      () => GetAdminTicketsUseCase(sl<SupportRepository>()));
  sl.registerLazySingleton(() => CloseTicketUseCase(sl<SupportRepository>()));

  // Cubit (factory — каждый раз новый экземпляр)
  sl.registerFactory(() => SupportCubit(
        getMyTicket: sl<GetMyTicketUseCase>(),
        createTicket: sl<CreateTicketUseCase>(),
        sendMessage: sl<SendMessageUseCase>(),
        getAdminTickets: sl<GetAdminTicketsUseCase>(),
        closeTicket: sl<CloseTicketUseCase>(),
        repository: sl<SupportRepository>(),
      ));
}
