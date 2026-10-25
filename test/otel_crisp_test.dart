// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_crisp/otel_crisp.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_crisp-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('conversation.send_message records channel + magic_type', () async {
    await tracedCrisp<String>(
      operation: 'website.conversation.send_message',
      websiteId: 'w-1',
      invoke: () async => const CrispCallResult(
        value: 'ok',
        result: CrispResult(
          websiteId: 'w-1',
          state: 'unresolved',
          deliveryChannel: 'whatsapp',
          magicType: 'bot',
          unreadCount: 0,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('crisp website.conversation.send_message')!,
    );
    expect(a['crisp.website.id'], 'w-1');
    expect(a['crisp.conversation.state'], 'unresolved');
    expect(a['crisp.conversation.channel'], 'whatsapp');
    expect(a['crisp.magic_type'], 'bot');
  });

  test('suppression skips spans', () async {
    await runWithoutCrispInstrumentationAsync(() async {
      await tracedCrisp<String>(
        operation: 'website.conversations.list',
        invoke: () async => const CrispCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('crisp '), isEmpty);
  });
}
