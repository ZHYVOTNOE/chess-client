class EngineConfig {
  final int timeLimitMs;
  final int timeBufferMs;
  final int? maxDepth;

  const EngineConfig({
    this.timeLimitMs = 1000,
    this.timeBufferMs = 500,
    this.maxDepth,
  });

  factory EngineConfig.fromBotLevel(String level) => switch (level) {
    'beginner'    => const EngineConfig(timeLimitMs: 300,  maxDepth: 3),
    'intermediate'=> const EngineConfig(timeLimitMs: 800,  maxDepth: 5),
    'advanced'    => const EngineConfig(timeLimitMs: 1500, maxDepth: 6),
    'expert'      => const EngineConfig(timeLimitMs: 2500, maxDepth: 8),
    'master'      => const EngineConfig(timeLimitMs: 4000, maxDepth: 10),
    _             => const EngineConfig(),
  };

  Duration get thinkingTime => Duration(milliseconds: timeLimitMs);
}