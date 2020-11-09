enum Byte {
  ACK,
  SYN,
  NAK,
  ETB,
  CAN,
  Other,
}

extension ByteToIntConverter on Byte {
  int toInt() {
    switch (this) {
      case Byte.ACK:
        return 0x06;
      case Byte.SYN:
        return 0x16;
      case Byte.NAK:
        return 0x15;
      case Byte.ETB:
        return 0x17;
      case Byte.CAN:
        return 0x18;
      default:
        return 0;
    }
  }
}

extension IntToByteConverter on int {
  Byte toByte() {
    switch (this) {
      case 0x06:
        return Byte.ACK;
      case 0x16:
        return Byte.SYN;
      case 0x15:
        return Byte.NAK;
      case 0x17:
        return Byte.ETB;
      case 0x18:
        return Byte.CAN;
      default:
        return Byte.Other;
    }
  }
}
