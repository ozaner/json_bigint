/// This class defines a complete (I think) implementation of a [JSON](https://json.org/) parser for dart. Complete with [BigInt] support.

import 'package:petitparser/definition.dart';
import 'package:petitparser/parser.dart';

import 'constants.dart';

/// Internal singleton JSON parser.
final _jsonParser = _JsonDefinition().build<Object?>();

/// Converts the given JSON-string [input] to its corresponding object.
///
/// For example:
///
///     final result = parseJson('{"a": 1, "b": [2, 3.4], "c": false}');
///     print(result.value);  // {a: 1, b: [2, 3.4], c: false}
Object? decodeJson(String input) => _jsonParser.parse(input).value;

/// Object? grammar definition.
class _JsonDefinition extends GrammarDefinition<Object?> {
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

  Parser<Object> numberToken() =>
      ref0(numberPrimitive).flatten('number expected').trim().map(_numOrBigInt);
  Parser<void> numberPrimitive() =>
      char('-').optional() &
      char('0').or(digit().plus()) &
      char('.').seq(digit().plus()).optional() &
      anyOf('eE').seq(anyOf('-+').optional()).seq(digit().plus()).optional();
}

// BigInt _maxInt = BigInt.parse("9223372036854775807");
// BigInt _minInt = BigInt.parse("-9223372036854775808");
BigInt? _tryBigInt(String str) {
  var val = BigInt.tryParse(str);
  if (val == null) return null; //non-integral
  return val;

  //uncomment if you want to return ints when possible
  // if (val > _maxInt || val < _minInt) return val; //bigint
  // return null; //63 bit signed int
}

Object _numOrBigInt(String str) {
  var biVal = _tryBigInt(str);
  if (biVal != null) return biVal;
  return num.parse(str);
}
