/// This class defines a complete (I think) implementation of a [JSON](https://json.org/) parser for dart. Complete with [BigInt] support.

import 'package:json_bigint/src/encoder.dart';
import 'package:meta/meta.dart';
import 'package:petitparser/definition.dart';
import 'package:petitparser/parser.dart';

import 'constants.dart';

bool useIntWhenValid(BigInt bi) => bi.isValidInt;

@immutable
class DecoderSettings {
  final bool Function(BigInt bi) whetherUseInt;

  /// Whether to treat exponentials (e.g. 12e+20) as integers when possible.
  final bool treatExpAsIntWhenPossible;

  const DecoderSettings({
    this.whetherUseInt = useIntWhenValid,
    this.treatExpAsIntWhenPossible = false,
  });

  @override
  bool operator ==(Object other) {
    return other is DecoderSettings &&
        whetherUseInt == other.whetherUseInt &&
        treatExpAsIntWhenPossible == other.treatExpAsIntWhenPossible;
  }

  @override
  int get hashCode => Object.hash(whetherUseInt, treatExpAsIntWhenPossible);
}

/// Converts the given JSON-string [input] to its corresponding object.
///
/// For example:
///
///     final result = parseJson('{"a": 1, "b": [2, 3.4], "c": false}');
///     print(result.value);  // {a: 1, b: [2, 3.4], c: false}
///
/// Pass in decoder [settings] to change how integers are deserialized.
Object? decodeJson(
  String input, {
  DecoderSettings? settings,
}) {
  if (settings == null) {
    return JSONBigIntConfig._parser.parse(input).value;
  } else {
    return _JsonDefinition(settings).build<Object?>().parse(input).value;
  }
}

/// Object? grammar definition.
class _JsonDefinition extends GrammarDefinition<Object?> {
  final DecoderSettings settings;

  const _JsonDefinition(this.settings);

  @override
  Parser<Object?> start() => ref0(value).end();

  Parser<Object?> value() => [
        ref0(stringToken),
        // ref0(integralToken),
        ref0(numberToken),
        ref0(object),
        ref0(array),
        ref0(trueToken),
        ref0(falseToken),
        ref0(nullToken),
      ].toChoiceParser(failureJoiner: selectFarthestJoined);

  Parser<Map<String, Object?>> object() => seq3(
        char('{').trim(),
        ref0(objectElements),
        char('}').trim(),
      ).map3((_, elements, __) => elements);

  Parser<Map<String, Object?>> objectElements() => ref0(objectElement)
      .starSeparated(char(',').trim())
      .map((list) => Map.fromEntries(list.elements));

  Parser<MapEntry<String, Object?>> objectElement() =>
      seq3(ref0(stringToken), char(':').trim(), ref0(value))
          .map3((key, _, value) => MapEntry(key, value));

  Parser<List<Object?>> array() => seq3(
        char('[').trim(),
        ref0(arrayElements),
        char(']').trim(),
      ).map3((_, elements, __) => elements);

  Parser<List<Object?>> arrayElements() =>
      ref0(value).starSeparated(char(',').trim()).map((list) => list.elements);

  Parser<bool> trueToken() => string('true').trim().map((_) => true);

  Parser<bool> falseToken() => string('false').trim().map((_) => false);

  Parser<Object?> nullToken() => string('null').trim().map((_) => null);

  Parser<String> stringToken() => seq3(
        char('"'),
        ref0(characterPrimitive).star(),
        char('"'),
      ).trim().map3((_, chars, __) => chars.join());

  Parser<String> characterPrimitive() => [
        ref0(characterNormal),
        ref0(characterEscape),
        ref0(characterUnicode),
      ].toChoiceParser();

  Parser<String> characterNormal() => pattern('^"\\');

  Parser<String> characterEscape() => seq2(
        char('\\'),
        anyOf(jsonEscapeChars.keys.join()),
      ).map2((_, char) => jsonEscapeChars[char]!);

  Parser<String> characterUnicode() => seq2(
        string('\\u'),
        pattern('0-9A-Fa-f').times(4).flatten('4-digit hex number expected'),
      ).map2((_, value) => String.fromCharCode(int.parse(value, radix: 16)));

  // Parser<BigInt> integralToken() => (char('-').optional() & digit().plus())
  //     .flatten('number expected')
  //     .map(BigInt.parse);
  Parser<Object> numberToken() => ref0(numberPrimitive)
      .flatten('number expected')
      .trim()
      .map((s) => _numOrBigInt(s, settings));

  Parser<void> numberPrimitive() =>
      char('-').optional() &
      char('0').or(digit().plus()) &
      char('.').seq(digit().plus()).optional() &
      anyOf('eE').seq(anyOf('-+').optional()).seq(digit().plus()).optional();
}

BigInt? _tryBigIntExp(String str) {
  try {
    final match = _exp.firstMatch(str);
    if (match != null) {
      //calc coef
      final sign = match.group(1) == '-' ? -1 : 1;
      final coefStr = match.group(2)!;
      var coef = int.tryParse(coefStr);
      if (coef == null) return null; //coef too big
      if (coef == 0) return BigInt.zero; //zero coefs work with any exponent
      coef = sign * coef;

      //calc exp
      final expSign = match.group(3) == '-' ? -1 : 1;
      var exp = int.tryParse(match.group(4)!);
      if (exp == null) return null; //exp too big
      exp = expSign * exp;

      //check if still integer despite negative exponent
      if (exp < 0) {
        exp = coefStr.length + exp; //new reduced exp

        //vvv exp > 0 (0 was handled)
        //vvv must be valid substring index, because 0 < exp < coef.length
        if (exp < 1 || int.tryParse(coefStr.substring(exp)) != 0) return null;

        coef = int.tryParse(coefStr.substring(0, exp - 1))!; //new reduced coef
      }
      return BigInt.from(coef) * BigInt.tryParse('1${'0' * exp}')!;
    }
  } catch (e) {
    return null; //shouldn't happen but failsafe...
  }
  return null; //not exp notation int
}

Object _numOrBigInt(String str, DecoderSettings settings) {
  var biVal = BigInt.tryParse(str); //try as bigint

  //if didn't work as bigint, try as exp->bigint
  if (biVal == null && settings.treatExpAsIntWhenPossible) {
    biVal = _tryBigIntExp(str);
  }
  //return as int, if possible (& desired)
  if (biVal != null && settings.whetherUseInt(biVal)) {
    return biVal.toInt();
  }

  return biVal ?? num.parse(str);
}

/// Internal regex for integers in scientific notation
final _exp = RegExp(r'^([-,+]?)0*(\d+)[e,E]([-,+]?)(\d+)$');

// ===== ===== ===== ===== ===== ===== ===== ===== ===== =====

/// global settings for the JSONBigInt library.
abstract class JSONBigIntConfig {
  static EncoderSettings encoderSettings = const EncoderSettings();

  static DecoderSettings _decoderSettings = const DecoderSettings();

  /// To avoid rebuilding the parser every time decodeJson is called, a parser is cached internally and updated every time the setting is modified.
  /// However, since Dart does not have access control as granular as Rust's `pub(crate)`, I have to define this class here (not very elegant but effective).
  static Parser<Object?> _parser =
      const _JsonDefinition(DecoderSettings()).build<Object?>();

  static DecoderSettings get decoderSettings => _decoderSettings;

  static set decoderSettings(DecoderSettings settings) {
    _decoderSettings = settings;
    // rebuild parser with new settings
    _parser = _JsonDefinition(settings).build<Object?>();
  }
}
