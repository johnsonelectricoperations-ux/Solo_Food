import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fridge_item.dart';
import 'receipt_parser.dart';

/// 실제 영수증 파서: Supabase Edge Function(parse-receipt)이 비전 LLM을 호출한다.
/// LLM API 키는 서버에만 있다 (supabase/functions/parse-receipt).
class SupabaseReceiptParser implements ReceiptParser {
  SupabaseReceiptParser(this._client);

  final SupabaseClient _client;

  @override
  Future<ParseResult> parseText(String text) => _invoke({'text': text});

  @override
  Future<ParseResult> parsePhoto(Uint8List bytes, String mediaType) => _invoke({
        'imageBase64': base64Encode(bytes),
        'mediaType': mediaType,
      });

  Future<ParseResult> _invoke(Map<String, dynamic> body) async {
    final response = await _client.functions.invoke('parse-receipt', body: body);
    final json = response.data as Map<String, dynamic>;
    return ParseResult(
      items: [
        for (final j in json['items'] as List)
          ParsedItem(
            name: j['name'] as String,
            emoji: j['emoji'] as String,
            section: FridgeSection.values.byName(j['section'] as String),
            count: j['count'] as int,
            daysLeft: j['daysLeft'] as int,
          ),
      ],
      excluded: (json['excluded'] as List).cast<String>(),
    );
  }
}

/// 서버 호출이 실패하면(함수 미배포, 오프라인 등) 예비 파서로 넘긴다.
/// 폴백이 발생했는지는 [lastUsedFallback]으로 화면에서 안내한다.
class FallbackReceiptParser implements ReceiptParser {
  FallbackReceiptParser({required this.primary, required this.fallback});

  final ReceiptParser primary;
  final ReceiptParser fallback;

  bool lastUsedFallback = false;

  @override
  Future<ParseResult> parseText(String text) =>
      _tryBoth((p) => p.parseText(text));

  @override
  Future<ParseResult> parsePhoto(Uint8List bytes, String mediaType) =>
      _tryBoth((p) => p.parsePhoto(bytes, mediaType));

  Future<ParseResult> _tryBoth(
      Future<ParseResult> Function(ReceiptParser) run) async {
    try {
      final result = await run(primary);
      lastUsedFallback = false;
      return result;
    } catch (e) {
      debugPrint('영수증 서버 인식 실패, 임시 인식기로 폴백: $e');
      lastUsedFallback = true;
      return run(fallback);
    }
  }
}
