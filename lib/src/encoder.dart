import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'constants.dart';

@immutable
class EncoderSettings {
  final String indent;
  final String afterKeyIndent;

  /// How long a list/map can be before its elements are indented.
  /// If set to null (the default), elements will always be indented.
  /// Has no effect if [indent] is "".
  final int? singleLineLimit;

  const EncoderSettings({
    this.indent = "",
    this.singleLineLimit,
    this.afterKeyIndent = "",
  });
}

String encodeJson(
  Object? val, {
  int level = 1,
  EncoderSettings settings = const EncoderSettings(),
}) {
  if (val is Map) {
    return encodeMap(val, level: level, settings: settings);
  }
  if (val is List) {
    return encodeList(val, level: level, settings: settings);
  }
  if (val is String) return encodeStr(val);
  if (val is num || val is BigInt || val is bool || val == null) return '$val';
  throw ArgumentError.value(val, "Unsupported JSON type."); //Unknown type
}

String encodeStr(String val) {
  //Deal with JSON escape characters
  for (var kvp in jsonEscapeChars.entries) {
    val = val.replaceAll(kvp.value, "\\${kvp.key}");
  }
  return '"$val"';
}

String encodeList(
  List val, {
  int level = 1,
  EncoderSettings settings = const EncoderSettings(),
}) {
  return _encodeComposite(
      val.map((v) {
        return encodeJson(v, level: level + 1, settings: settings);
      }).toList(),
      "[",
      "]",
      level,
      settings);
}

String encodeMap(
  Map val, {
  int level = 1,
  EncoderSettings settings = const EncoderSettings(),
}) {
  return _encodeComposite(
      val.entries.map((kvp) {
        return '"${kvp.key}":${settings.afterKeyIndent}${encodeJson(kvp.value, level: level + 1, settings: settings)}';
      }).toList(),
      "{",
      "}",
      level,
      settings);
}

String _encodeComposite(List<String> valsEnc, String dL, String dR, int level,
    EncoderSettings settings) {
  if (valsEnc.isEmpty) return "$dL$dR";

  var finalStr = dL;
  int totalChars = valsEnc.fold(0, (prevVal, str) => prevVal + str.length);
  bool doIndent = settings.indent != "" && //indent enabled
      (settings.singleLineLimit == null || //has no single line limit
          totalChars > settings.singleLineLimit!); //limit isnt't exceeded

  valsEnc.forEachIndexed((i, str) {
    if (doIndent) finalStr += "\n${settings.indent * level}";
    finalStr += str;
    if (i != valsEnc.length - 1) {
      //not last item
      finalStr += ",";
    } else if (doIndent) {
      //last item with indent
      finalStr += "\n${settings.indent * (level - 1)}$dR";
    } else {
      //last item w/o indent
      finalStr += dR;
    }
  });
  return finalStr;
}
