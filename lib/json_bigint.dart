/// A package that implements [decodeJson] and
/// [encodeJson] methods that natively support [BigInt].
library json_bigint;

export 'src/decoder.dart' show decodeJson;
export 'src/encoder.dart' show encodeJson, EncoderSettings;
