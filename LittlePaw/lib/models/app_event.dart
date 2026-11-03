class AppEvent {
  final DateTime ts;
  final String utcDay;
  final String event;
  final Map<String, dynamic> props;

  AppEvent({
    required this.ts,
    required this.utcDay,
    required this.event,
    this.props = const {},
  });

  Map<String, dynamic> toJson() => {
        'ts': ts.toIso8601String(),
        'utc_day': utcDay,
        'event': event,
        'props': props,
      };

  factory AppEvent.fromJson(Map<String, dynamic> j) => AppEvent(
        ts: DateTime.parse(j['ts'] as String),
        utcDay: j['utc_day'] as String,
        event: j['event'] as String,
        props: Map<String, dynamic>.from(j['props'] as Map? ?? {}),
      );

  String toExportLine() {
    final propsStr = props.isEmpty ? '{}' : props.toString();
    return '$utcDay\t$event\t$propsStr\tts=${ts.toIso8601String()}';
  }
}
