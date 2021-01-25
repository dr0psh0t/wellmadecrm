class QrCode {
  final int qrCodeId;
  final String qrCode;

  QrCode({this.qrCodeId, this.qrCode});

  Map<String, dynamic> toMap() {
    return {'qrcode_id': qrCodeId, 'qrcode': qrCode};
  }

  @override
  String toString() {
    return 'QrCode{qrCodeId: $qrCodeId, qrCode: $qrCode}';
  }
}