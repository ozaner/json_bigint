import 'package:json_bigint/json_bigint.dart';

void printObj(String key, Object? val) =>
    print("$key is of type ${val.runtimeType} and has value: $val.");

void main() {
  String json = '''{
          "sometext": "hello world!",
          "bignumber": 999999999999999999,
          "expnumber": 2e3
        }''';

  print("Decoding:");
  print("------------------------");
  final jsonMap = decodeJson(json) as Map<String, Object?>;
  printObj("sometext", jsonMap["sometext"]);
  printObj("bignumber", jsonMap["bignumber"]);
  printObj("expnumber", jsonMap["expnumber"]);

  print("\nDecoding w/ settings:");
  print("------------------------");
  final decSettings = DecoderSettings(
    treatExpAsIntWhenPossible: true,
  );
  final jsonMap2 = decodeJson(
    json,
    settings: decSettings,
  ) as Map<String, Object?>;
  printObj("bignumber", jsonMap2["bignumber"]);
  printObj("expnumber", jsonMap2["expnumber"]);

  print("\nEncoding:");
  print("------------------------");
  String jsonNew = encodeJson(jsonMap);
  print(jsonNew);

  print("\nEncoding w/ Settings:");
  print("------------------------");
  final encSettings = EncoderSettings(
    indent: "  ",
    singleLineLimit: 30,
    afterKeyIndent: " ",
  );
  String jsonFormatted = encodeJson(jsonMap2, settings: encSettings);
  print(jsonFormatted);

  // control whether to use int
  final result = decodeJson(
    '{"a": 1, "b": [2, 3.4], "c": false, "d": 123}',
    // use int only when value is less than 10, otherwise use BigInt
    settings: DecoderSettings(whetherUseInt: (v) => v < BigInt.from(10)),
  ) as Map;
  print(result['a'].runtimeType); // int
  print(result['d'].runtimeType); // _BigIntImpl
}
