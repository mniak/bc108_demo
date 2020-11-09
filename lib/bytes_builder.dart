import 'bytes.dart';

class BytesBuilder {
  List<int> _bytes = List<int>();

  BytesBuilder addByte(int byte) {
    _bytes.add(byte);
    return this;
  }

  BytesBuilder addByte2(Byte byte) {
    _bytes.add(byte.toInt());
    return this;
  }

  BytesBuilder addBytes(Iterable<int> bytes) {
    bytes.forEach((b) {
      this.addByte(b);
    });
    return this;
  }

  BytesBuilder addString(String string) {
    string.codeUnits.forEach((b) {
      if (b >= 0x20 && b <= 0x7e) {
        this.addByte(b);
      }
    });
    return this;
  }

  Iterable<int> build() => this._bytes;
}
