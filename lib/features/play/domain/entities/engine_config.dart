// class EngineConfig {
//   final int timeLimitMs;
//   final int timeBufferMs;
//   final int? maxDepth;
//
//   const EngineConfig({
//     this.timeLimitMs = 1000,
//     this.timeBufferMs = 500,
//     this.maxDepth,
//   });
//
//   factory EngineConfig.fromBotLevel(String level) => switch (level) {
//     'beginner'    => const EngineConfig(timeLimitMs: 300,  maxDepth: 3),
//     'intermediate'=> const EngineConfig(timeLimitMs: 800,  maxDepth: 5),
//     'advanced'    => const EngineConfig(timeLimitMs: 1500, maxDepth: 6),
//     'expert'      => const EngineConfig(timeLimitMs: 2500, maxDepth: 8),
//     'master'      => const EngineConfig(timeLimitMs: 4000, maxDepth: 10),
//     _             => const EngineConfig(),
//   };
//
//   Duration get thinkingTime => Duration(milliseconds: timeLimitMs);
// }
class EngineConfig {
  final int timeLimitMs;
  final int timeBufferMs;
  final int? maxDepth;

  const EngineConfig({
    this.timeLimitMs = 1000,
    this.timeBufferMs = 500,
    this.maxDepth,
  });

  factory EngineConfig.fromBotLevel(int level) => switch (level) {
    1  => const EngineConfig(timeLimitMs: 300,  maxDepth: 1),
    2  => const EngineConfig(timeLimitMs: 500,  maxDepth: 3),
    3  => const EngineConfig(timeLimitMs: 800,  maxDepth: 5),
    4  => const EngineConfig(timeLimitMs: 1200, maxDepth: 8),
    5  => const EngineConfig(timeLimitMs: 1500, maxDepth: 10),
    6  => const EngineConfig(timeLimitMs: 2000, maxDepth: 12),
    7  => const EngineConfig(timeLimitMs: 2500, maxDepth: 14),
    8  => const EngineConfig(timeLimitMs: 3000, maxDepth: 16),
    9  => const EngineConfig(timeLimitMs: 4000, maxDepth: 18),
    10 => const EngineConfig(timeLimitMs: 5000, maxDepth: 20),
    _  => const EngineConfig(timeLimitMs: 1000, maxDepth: 10),
  };

  Duration get thinkingTime => Duration(milliseconds: timeLimitMs);
}