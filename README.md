# json_bigint

This is a dart package that provides methods for encoding and decoding JSON strings from/to dart maps, with
out-of-the-box support for [BigInt](https://api.flutter.dev/flutter/dart-core/BigInt-class.html).

## Usage

The examples will make use of the following common code:

```dart
import 'package:json_bigint/json_bigint.dart';

String json = '''{
          "sometext": "hello world!",
          "bignumber": 999999999999999999,
          "expnumber": 2e3
        }''';

void printObj(String key, Object? val) =>
    print("$key is of type ${val.runtimeType} and has value: $val.");
```

### Decoding

Below is an example of how the decoder method works:

```dart
print("Decoding:");
print("------------------------");
var jsonMap = decodeJson(json) as Map<String, Object?>;
printObj("sometext", jsonMap["sometext"]);
printObj("bignumber", jsonMap["bignumber"]);
printObj("expnumber", jsonMap["expnumber"]);

print("\nDecoding w/ settings:");
print("------------------------");
var decSettings = DecoderSettings(
treatExpAsIntWhenPossible: true,
);
var jsonMap2 = decodeJson(
json,
settings: decSettings,
) as Map<String, Object?>;
printObj("bignumber", jsonMap2["bignumber"]);
printObj("expnumber", jsonMap2["expnumber"]);
```

It prints out:

```
Decoding:
------------------------
sometext is of type String and has value: hello world!.
bignumber is of type _BigIntImpl and has value: 999999999999999999.
expnumber is of type double and has value: 2000.0.
```

### Decoding Settings

If you want to change how certain numbers are cast to integers, pass a `DecoderSettings` object. It has the following
parameters:

- `whetherUseInt`: controls whether to use `int` rather than `BigInt` when possible.
  - By default, it uses `BigInt.isValidInt` to judge whether to use `int` or `BigInt`.
  - If you want to interpret **all** numbers as `BigInt`, use something like`(_) => false` 
  - If your project targets both native and web, it is recommended that you control it yourself (for example, use `(v) => v <= BigInt.parse('9007199254740991')`)
- `treatExpAsIntWhenPossible`: By default, the decoder treats values written in exponential notation (e.g. 1e12) as
  doubles. To treat these as integers when possible (i.e. if they evaluate to an integer), set this to true.

```dart
print("\nDecoding w/ settings:");
print("------------------------");
var decSettings = DecoderSettings(treatExpAsIntWhenPossible: true);
var jsonMap2 = decodeJson(
json,
settings: decSettings,
) as Map<String, Object?>;
printObj("bignumber", jsonMap2["bignumber"]);
printObj("expnumber", jsonMap2["expnumber"]);
```

It prints out:

```
Decoding w/ settings:
------------------------
bignumber is of type int and has value: 999999999999999999.
expnumber is of type int and has value: 2000.
```

### Encoding

Below is an example of how the encoder method works:

```dart
print("\nEncoding:");
print("------------------------");
String jsonNew = encodeJson(jsonMap);
print(jsonNew);
```

It prints out:

```
Encoding:
------------------------
{"sometext":"hello world!","bignumber":999999999999999999,"expnumber":2000.0}
```

### Encoder Settings

If you want to format the encoded JSON, use the `EncoderSettings` object. It has the following parameters:

- `indent`: how much to indent at each level of the JSON. Should usually be some number of consecutive <kbd>Space</kbd>
  or <kbd>Tab</kbd> characters. If the default (i.e. empty String) is used, no new lines will be added in the JSON.
- `singleLineLimit`: how long a map/list can be before its elements are indented. If the default (i.e. `null`) is used,
  all elements will always be indented.
- `afterKeyIndent`: how much to indent between the key and value in a map. The default is the empty String.

```dart
print("\nEncoding w/ Settings:");
print("------------------------");
final encSettings = EncoderSettings(
indent: "  ",
singleLineLimit: 30,
afterKeyIndent: " ",
);
String jsonFormatted = encodeJson(jsonMap2, settings: encSettings);
print(jsonFormatted);
```

It prints out:

```
Encoding w/ Settings:
------------------------
{
  "sometext": "hello world!",
  "bignumber": 999999999999999999,
  "expnumber": 2000
}
```

## Notes

This package does not support [commented JSON](https://json5.org/), but neither does dart:convert...

## Rationale

If you've ever used the JSON serializer provided by dart's standard
library, [dart:convert](https://api.dart.dev/dart-convert/dart-convert-library.html), you might have noticed that it
treats any integer that cannot fit in a 64 bit signed integer as a double. This is a consequence of the library being
written back when dart only had one `num` type.

This means that any integers in the JSON will irreversibly lose their precision should they not be too large (or small).
And, unfortunately, there is currently no support to override the converter to make use the BigInt type in those cases.
This makes the library unsuitable for applications in which large integers need to be (de)serialized exactly.

### Why not use a third-party serializer?

As it turns out, all the big JSON serialization packages (
e.g. [json_serializable](https://pub.dev/packages/json_serializable), [dart_mappable](https://pub.dev/packages/dart_mappable), [build-value](https://pub.dev/packages/built_value), [JSON5](https://pub.dev/packages/json5),
etc.) use the dart:convert serializer under the hood. Meaning there is no way for those packages to override this
behavior either.

This is why I simply bit the bullet and made one myself. One that doesn't depend on dart:convert at all.

*Encoding* JSON is relatively simple (although formatting/pretty print adds a bit of complexity) but *decoding* is
another matter. Indeed, if it wasn't for the wonderful [petitparser](https://pub.dev/packages/petitparser) package, it
would have been much more difficult.
