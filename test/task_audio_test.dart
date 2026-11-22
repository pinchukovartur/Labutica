import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labutica/games/kit.dart';

void main() {
  testWidgets('выполненное задание звучит один раз, включая последний раунд', (tester) async {
    const channel = MethodChannel('labutica/task_audio');
    final messenger = tester.binding.defaultBinaryMessenger;
    final sounds = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      sounds.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    var finished = 0;
    final rounds = GameCtl(2, (_) => finished++);
    addTearDown(rounds.dispose);
    rounds.bad('wrong');
    expect(sounds, isEmpty);

    rounds.ok('first', 10);
    rounds.ok('first', 10);
    await tester.pump(const Duration(milliseconds: 20));
    expect(sounds, ['playSuccess']);
    expect(finished, 0);

    rounds.ok('last', 10);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(sounds, ['playSuccess', 'playSuccess']);
    expect(finished, 1);

    final singleTask = GameCtl(1, (_) => finished++);
    addTearDown(singleTask.dispose);
    singleTask.finish(10);
    singleTask.finish(10);
    await tester.pump(const Duration(milliseconds: 20));
    expect(sounds, ['playSuccess', 'playSuccess', 'playSuccess']);
    expect(finished, 2);
    await tester.pump(const Duration(milliseconds: 700));
  });
}
