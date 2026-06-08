import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';
import '../../domain/usecases/close_ticket_usecase.dart';
import '../../domain/usecases/create_ticket_usecase.dart';
import '../../domain/usecases/get_admin_tickets_usecase.dart';
import '../../domain/usecases/get_my_ticket_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final GetMyTicketUseCase _getMyTicket;
  final CreateTicketUseCase _createTicket;
  final SendMessageUseCase _sendMessage;
  final GetAdminTicketsUseCase _getAdminTickets;
  final CloseTicketUseCase _closeTicket;
  final SupportRepository _repository;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _adminTicketsSubscription;

  SupportCubit({
    required GetMyTicketUseCase getMyTicket,
    required CreateTicketUseCase createTicket,
    required SendMessageUseCase sendMessage,
    required GetAdminTicketsUseCase getAdminTickets,
    required CloseTicketUseCase closeTicket,
    required SupportRepository repository,
  })  : _getMyTicket = getMyTicket,
        _createTicket = createTicket,
        _sendMessage = sendMessage,
        _getAdminTickets = getAdminTickets,
        _closeTicket = closeTicket,
        _repository = repository,
        super(SupportInitial());

  // ─── ИНИЦИАЛИЗАЦИЯ ─────────────────────────────────────────

  Future<void> initialize(String role) async {
    emit(SupportLoading());
    try {
      if (role == 'admin') {
        await _initAdmin();
      } else {
        await _initUser();
      }
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }

  // ─── USER ──────────────────────────────────────────────────

  Future<void> _initUser() async {
    final ticket = await _getMyTicket();
    if (ticket == null) {
      emit(SupportNoTicket());
    } else {
      _openTicketChat(ticket, isAdmin: false);
    }
  }

  Future<void> createNewTicket() async {
    emit(SupportLoading());
    try {
      final ticket = await _createTicket();
      _openTicketChat(ticket, isAdmin: false);
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }

  // ─── ADMIN ─────────────────────────────────────────────────

  Future<void> _initAdmin() async {
    final tickets = await _getAdminTickets();
    emit(SupportAdminList(tickets));
    _subscribeAdminTickets();
  }

  void _subscribeAdminTickets() {
    _adminTicketsSubscription?.cancel();
    _adminTicketsSubscription =
        _repository.adminTicketsStream().listen((tickets) {
      // Обновляем список только если мы на экране списка
      if (state is SupportAdminList) {
        emit(SupportAdminList(tickets));
      }
    });
  }

  /// Вызывается когда админ тапает на тикет в списке
  void openAdminTicket(SupportTicket ticket) {
    _openTicketChat(ticket, isAdmin: true);
  }

  /// Возврат к списку тикетов
  void backToAdminList() {
    _messagesSubscription?.cancel();
    initialize('admin');
  }

  Future<void> closeTicket(String ticketId) async {
    try {
      await _closeTicket(ticketId);
      backToAdminList();
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }

  // ─── ОБЩИЙ ЧАТ ─────────────────────────────────────────────

  void _openTicketChat(SupportTicket ticket, {required bool isAdmin}) {
    _messagesSubscription?.cancel();

    _messagesSubscription =
        _repository.messagesStream(ticket.id).listen((messages) {
      if (isAdmin) {
        final current = state;
        emit(SupportAdminTicketOpen(
          ticket: ticket,
          messages: messages,
          isSending:
              current is SupportAdminTicketOpen ? current.isSending : false,
        ));
      } else {
        final current = state;
        emit(SupportTicketOpen(
          ticket: ticket,
          messages: messages,
          isSending: current is SupportTicketOpen ? current.isSending : false,
        ));
      }
    }, onError: (e) => emit(SupportError(e.toString())));
  }

  Future<void> sendMessage(String ticketId, String body) async {
    if (body.trim().isEmpty) return;

    // Оптимистичный isSending
    final current = state;
    if (current is SupportTicketOpen) {
      emit(current.copyWith(isSending: true));
    } else if (current is SupportAdminTicketOpen) {
      emit(current.copyWith(isSending: true));
    }

    try {
      await _sendMessage(ticketId, body);
      // Стрим обновит сообщения сам
      final updated = state;
      if (updated is SupportTicketOpen) {
        emit(updated.copyWith(isSending: false));
      } else if (updated is SupportAdminTicketOpen) {
        emit(updated.copyWith(isSending: false));
      }
    } catch (e) {
      emit(SupportError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    _adminTicketsSubscription?.cancel();
    return super.close();
  }
}
