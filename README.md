# json_bigint
This is a dart package that allows for the encoding and decoding of JSON strings to dart maps, with out-of-the-box support for [BigInt](https://api.flutter.dev/flutter/dart-core/BigInt-class.html).


## Usage
Below we show how decoding and encoding work:

```dart
import 'package:json_bigint/json_bigint.dart';

void main {
  String json =
    '{"sometext": "hello world!", "bignumber": 9999999999999999999}';

  // decoding
  var jsonMap = decodeJson(json) as Map<String, Object?>;
  print(jsonMap["sometext"]); //hello, world!
  print(jsonMap["bignumber"]); //9999999999999999999
  print(jsonMap["bignumber"] is BigInt); //true

  // encoding
  String jsonNew = encodeJson(jsonMap);
  print(jsonNew);
  //{"sometext": "hello world!", "bignumber": 9999999999999999999}
}
```

### Formatting
If you want to format the encoded JSON, use the `EncoderSettings` object. It has the following parameters:
- `indent`: how much to indent at each level of the JSON. Should usually be some number of consecutive <kbd>Space</kbd> or <kbd>Tab</kbd> characters. If the default (i.e. empty String) is used, no new lines will be added in the JSON.
- `singleLineLimit`: how long a map/list can be before its elements are indented. If the default (i.e. `null`) is used, all elements will always be indented.
- `afterKeyIndent`: how much to indent between the key and value in a map. The default is the empty String.

```dart
  // encoding w/ formatting
  EncoderSettings settings = EncoderSettings(indent: "  ",
    singleLineLimit: 30, afterKeyIndent: " ");

  String jsonFormatted = encodeJson(jsonMap);
  print(jsonFormatted);
  //{
  //  "sometext": "hello world!",
  //  "bignumber": 9999999999999999999
  //}
  
```

## Notes
- This package does not support [commented JSON](https://json5.org/), but neither does dart:convert...

## Why?
If you've ever used [dart:convert](https://api.dart.dev/dart-convert/dart-convert-library.html), dart's standard library implementation of a JSON serializer, you might have noticed that it treats any integer bigger than $2^{63}-1$ as a double. This is presumably because the int data type in dart has a range from $[-2^{63},2^{63}-1]$.

However the problem is, once these integers have been converted to doubles, they have irreversibly lost their precision. And unfortunately, there is currently no support to override this functionality to use the BigInt type.

### Why not use a third-party serializer
As it turns out, all the big JSON serialization packages (e.g. [json_serializable](https://pub.dev/packages/json_serializable), [dart_mappable](https://pub.dev/packages/dart_mappable), [build-value](https://pub.dev/packages/built_value), [JSON5](https://pub.dev/packages/json5), etc.) all use the dart:convert serializer under the hood. Meaning there is no way for those packages to override this behavior.

This is why I simply bit the bullet and made one myself that doesn't depend on dart:convert at all. *Encoding* JSON is relatively simple (although formatting/pretty print adds a bit of complexity) but *decoding* is another matter. Indeed, if it wasn't for the wonderful[petitparser](https://pub.dev/packages/petitparser) package, it would have been much more difficult.
