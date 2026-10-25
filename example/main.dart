// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_crisp/otel_crisp.dart';

/// Traces Crisp calls with OpenTelemetry.
///
/// `otel_crisp` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Crisp call in
/// [tracedCrisp]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'crisp-example');

  // Wraps a Crisp REST API call in a CLIENT span.
  final crispId = await tracedCrisp<String>(
    operation: 'website.conversation.create',
    websiteId: 'website_8f3a2c',
    invoke: () async {
      // Make the Crisp call here, then report what it returned.
      const id = 'crisp_8f3a2c';
      return const CrispCallResult(
          value: id,
          result: CrispResult(
              itemCount: 3,
              websiteId: 'website_id',
              state: 'pending',
              deliveryChannel: 'chat',
              magicType: 'bot',
              assignedOperatorId: 'assignedoperator_8f3a2c',
              unreadCount: 3,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedCrisp website.conversation.create returned $crispId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCrispInstrumentationAsync.
  await runWithoutCrispInstrumentationAsync(
    () => tracedCrisp<String>(
      operation: 'website.conversation.create',
      websiteId: 'website_8f3a2c',
      invoke: () async {
        const id = 'crisp_8f3a2c';
        return const CrispCallResult(
            value: id,
            result: CrispResult(
                itemCount: 3,
                websiteId: 'website_id',
                state: 'pending',
                deliveryChannel: 'chat',
                magicType: 'bot',
                assignedOperatorId: 'assignedoperator_8f3a2c',
                unreadCount: 3,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
