class TimeControl {
  final int minutes;
  final int seconds;
  final int increment;
  final bool enabled;

  const TimeControl({
    this.minutes = 5,
    this.seconds = 0,
    this.increment = 0,
    this.enabled = true,
  });

  const TimeControl.disabled()
      : minutes = 0, seconds = 0, increment = 0, enabled = false;

  factory TimeControl.parse(String raw) {
    if (raw.isEmpty) return const TimeControl.disabled();

    final parts = raw.split('|');
    final timePart = parts[0].split(':');

    return TimeControl(
      minutes: int.parse(timePart[0]),
      seconds: timePart.length > 1 ? int.parse(timePart[1]) : 0,
      increment: parts.length > 1 ? int.parse(parts[1]) : 0,
    );
  }

  String get code => '$minutes:${seconds.toString().padLeft(2, '0')}|$increment';
  String get display => '$minutes|$increment';
  String get displayFull => '$minutes:${seconds.toString().padLeft(2, '0')} +$increment';

  Duration get initial => Duration(minutes: minutes, seconds: seconds);
  Duration get incrementDuration => Duration(seconds: increment);

  bool get isEnabled => enabled;
}