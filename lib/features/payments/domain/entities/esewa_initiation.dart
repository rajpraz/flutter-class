class EsewaInitiation {
  final String productCode;
  final String totalAmount;
  final String transactionUuid;
  final String signature;
  final String signedFieldNames;

  const EsewaInitiation({
    required this.productCode,
    required this.totalAmount,
    required this.transactionUuid,
    required this.signature,
    required this.signedFieldNames,
  });

  factory EsewaInitiation.fromMap(Map<String, dynamic> map) => EsewaInitiation(
        productCode: map['productCode'] as String? ?? '',
        totalAmount: map['totalAmount'] as String? ?? '0',
        transactionUuid: map['transactionUuid'] as String? ?? '',
        signature: map['signature'] as String? ?? '',
        signedFieldNames: map['signedFieldNames'] as String? ?? '',
      );
}
