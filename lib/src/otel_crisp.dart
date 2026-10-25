// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_crisp_suppression.dart';

const _tracerName = 'dartastic_otel_libs_crisp';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class CrispResult {
  /// Creates a result.
  const CrispResult({
    this.itemCount,
    this.websiteId,
    this.state,
    this.deliveryChannel,
    this.magicType,
    this.assignedOperatorId,
    this.unreadCount,
    this.requestId,
    this.statusCode,
  });

  /// Items returned in `data`.
  final int? itemCount;

  /// `website_id` — Crisp's per-tenant routing key.
  final String? websiteId;

  /// `pending` / `unresolved` / `resolved`.
  final String? state;

  /// `chat` / `email` / `telegram` / `messenger` / `whatsapp` /
  /// `instagram` / `twitter` — Crisp's omnichannel routing dim.
  final String? deliveryChannel;

  /// `bot` / `human` / `none` — distinguishes MagicReply-handled
  /// conversations from human-handled.
  final String? magicType;

  /// Operator id when assigned.
  final String? assignedOperatorId;

  /// `unread` count.
  final int? unreadCount;

  /// `X-Request-Id` (when present).
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class CrispCallResult<T> {
  /// Creates a call result.
  const CrispCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final CrispResult? result;
}

/// Wraps a Crisp REST API call in a CLIENT span. [operation] is one of
/// `website.conversations.list`, `website.conversation.get`,
/// `website.conversation.create`, `website.conversation.send_message`,
/// `website.conversation.set_state`, `website.conversation.assign`,
/// `website.conversation.read`, `website.people.profiles.list`,
/// `website.people.profile.get`, `website.people.profile.update`,
/// `website.operators.list`, `bucket.url.upload`, `plugin.list`,
/// `webhook.register`.
Future<T> tracedCrisp<T>({
  required String operation,
  required Future<CrispCallResult<T>> Function() invoke,
  String? websiteId,
}) async {
  if (crispInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'crisp',
    'rpc.method': operation,
    'crisp.operation': operation,
  };
  if (websiteId != null) m['crisp.website.id'] = websiteId;

  final span = _tracer().startSpan(
    'crisp $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'crisp.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.websiteId != null) {
        extras.add(OTelAPI.attributeString(
          'crisp.website.id',
          r.result!.websiteId!,
        ));
      }
      if (r.result!.state != null) {
        extras.add(OTelAPI.attributeString(
          'crisp.conversation.state',
          r.result!.state!,
        ));
      }
      if (r.result!.deliveryChannel != null) {
        extras.add(OTelAPI.attributeString(
          'crisp.conversation.channel',
          r.result!.deliveryChannel!,
        ));
      }
      if (r.result!.magicType != null) {
        extras.add(OTelAPI.attributeString(
          'crisp.magic_type',
          r.result!.magicType!,
        ));
      }
      if (r.result!.assignedOperatorId != null) {
        extras.add(OTelAPI.attributeString(
          'crisp.assigned_operator.id',
          r.result!.assignedOperatorId!,
        ));
      }
      if (r.result!.unreadCount != null) {
        extras.add(OTelAPI.attributeInt(
          'crisp.unread_count',
          r.result!.unreadCount!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'crisp.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Crisp HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
