import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/locale_provider.dart';

/// Authoritative Chess Clock Widget
class ChessClock extends StatefulWidget {
  final Duration whiteTime;
  final Duration blackTime;
  final bool isWhiteTurn;
  final DateTime? lastMoveAt;
  final Duration increment;
  final bool isGameOver;
  final VoidCallback? onTimeout;

  const ChessClock({
    super.key,
    required this.whiteTime,
    required this.blackTime,
    required this.isWhiteTurn,
    this.lastMoveAt,
    this.increment = Duration.zero,
    this.isGameOver = false,
    this.onTimeout,
  });

  @override
  State<ChessClock> createState() => _ChessClockState();
}

class _ChessClockState extends State<ChessClock> {
  Timer? _timer;
  Duration _localWhiteTime = Duration.zero;
  Duration _localBlackTime = Duration.zero;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _localWhiteTime = widget.whiteTime;
    _localBlackTime = widget.blackTime;
    _lastSyncTime = widget.lastMoveAt ?? DateTime.now();
    _startClock();
  }

  @override
  void didUpdateWidget(ChessClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.whiteTime != widget.whiteTime ||
        oldWidget.blackTime != widget.blackTime ||
        oldWidget.lastMoveAt != widget.lastMoveAt) {
      _syncWithServer();
    }
    
    if (widget.isGameOver && !oldWidget.isGameOver) {
      _stopClock();
    } else if (!widget.isGameOver && oldWidget.isGameOver) {
      _startClock();
    }
  }

  void _syncWithServer() {
    setState(() {
      _localWhiteTime = widget.whiteTime;
      _localBlackTime = widget.blackTime;
      _lastSyncTime = widget.lastMoveAt ?? DateTime.now();
    });
  }

  void _startClock() {
    _stopClock();
    if (widget.isGameOver) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !widget.isGameOver) {
        setState(() {
          if (widget.isWhiteTurn) {
            _localWhiteTime = _localWhiteTime > Duration.zero
                ? _localWhiteTime - const Duration(seconds: 1)
                : Duration.zero;
          } else {
            _localBlackTime = _localBlackTime > Duration.zero
                ? _localBlackTime - const Duration(seconds: 1)
                : Duration.zero;
          }
        });

        if (_localWhiteTime == Duration.zero || _localBlackTime == Duration.zero) {
          _stopClock();
          widget.onTimeout?.call();
        }
      }
    });
  }

  void _stopClock() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopClock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ClockDisplay(
          time: _localWhiteTime,
          isActive: widget.isWhiteTurn && !widget.isGameOver,
          label: locale.get('openings_white'),
          isLowTime: _localWhiteTime.inSeconds <= 30,
        ),
        _ClockDisplay(
          time: _localBlackTime,
          isActive: !widget.isWhiteTurn && !widget.isGameOver,
          label: locale.get('openings_black'),
          isLowTime: _localBlackTime.inSeconds <= 30,
        ),
      ],
    );
  }
}

class _ClockDisplay extends StatelessWidget {
  final Duration time;
  final bool isActive;
  final String label;
  final bool isLowTime;

  const _ClockDisplay({
    required this.time,
    required this.isActive,
    required this.label,
    required this.isLowTime,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = time.inMinutes.remainder(60);
    final seconds = time.inSeconds.remainder(60);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isActive 
            ? (isLowTime ? Colors.red.shade100 : Colors.green.shade100)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isActive 
              ? (isLowTime ? Colors.red : Colors.green)
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '$minutes:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isActive 
                  ? (isLowTime ? Colors.red : Colors.black87)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider for authoritative clock state
class AuthoritativeClockProvider extends Cubit<AuthoritativeClockState> {
  Timer? _syncTimer;
  static const _syncInterval = Duration(seconds: 5);

  AuthoritativeClockProvider() : super(AuthoritativeClockState.initial());

  void updateFromServer({
    required Duration whiteTime,
    required Duration blackTime,
    required DateTime lastMoveAt,
    required bool isWhiteTurn,
  }) {
    emit(state.copyWith(
      whiteTime: whiteTime,
      blackTime: blackTime,
      lastMoveAt: lastMoveAt,
      isWhiteTurn: isWhiteTurn,
      lastSyncAt: DateTime.now(),
    ));
  }

  void startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      _syncWithServer();
    });
  }

  void stopSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  void _syncWithServer() {
    emit(state.copyWith(lastSyncAt: DateTime.now()));
  }

  Duration calculateLocalTime(Duration serverTime, DateTime serverTimestamp) {
    final elapsed = DateTime.now().difference(serverTimestamp);
    final localTime = serverTime - elapsed;
    return localTime > Duration.zero ? localTime : Duration.zero;
  }

  @override
  Future<void> close() {
    stopSync();
    return super.close();
  }
}

class AuthoritativeClockState {
  final Duration whiteTime;
  final Duration blackTime;
  final DateTime? lastMoveAt;
  final bool isWhiteTurn;
  final DateTime? lastSyncAt;
  final bool isSyncing;

  const AuthoritativeClockState({
    required this.whiteTime,
    required this.blackTime,
    this.lastMoveAt,
    required this.isWhiteTurn,
    this.lastSyncAt,
    this.isSyncing = false,
  });

  factory AuthoritativeClockState.initial() {
    return AuthoritativeClockState(
      whiteTime: Duration.zero,
      blackTime: Duration.zero,
      isWhiteTurn: true,
    );
  }

  AuthoritativeClockState copyWith({
    Duration? whiteTime,
    Duration? blackTime,
    DateTime? lastMoveAt,
    bool? isWhiteTurn,
    DateTime? lastSyncAt,
    bool? isSyncing,
  }) {
    return AuthoritativeClockState(
      whiteTime: whiteTime ?? this.whiteTime,
      blackTime: blackTime ?? this.blackTime,
      lastMoveAt: lastMoveAt ?? this.lastMoveAt,
      isWhiteTurn: isWhiteTurn ?? this.isWhiteTurn,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}
