import 'package:json_bigint/json_bigint.dart';

void main() {
  String json = '{"sometext": "hello world!", "bignumber": 9999999999999999999';

  // decoding
  var jsonMap = decodeJson(json) as Map<String, Object?>;
  print(jsonMap["sometext"]); //hello, world!
  print(jsonMap["bignumber"]); //9999999999999999999
  print(jsonMap["bignumber"] is BigInt); //true

  // encoding
  String jsonNew = encodeJson(jsonMap);
  print(jsonNew);
  //{"sometext": "hello world!", "bignumber": 9999999999999999999}

  // encoding w/ formatting
  EncoderSettings settings =
      EncoderSettings(indent: "  ", singleLineLimit: 30, afterKeyIndent: " ");

  String jsonFormatted = encodeJson(jsonMap);
  print(jsonFormatted);
  //{
  //  "sometext": "hello world!",
  //  "bignumber": 9999999999999999999
  //}
}
