void main() {
  print("Testing sender matching:");
  print("Template sender: 'CBE'");
  print("Test sender: 'cbe'");
  print("Match (case insensitive): ${'CBE'.toLowerCase() == 'cbe'.toLowerCase()}");
  print("=" * 50);
  
  // Test real CBE SMS patterns
  final cbeTransfer = "Dear Abel, You have transferred ETB 100.00 to Kidus Yared on 17/10/2025 at 16:21:36 from your account 1*********8193. Your Current Balance is ETB 481.47. Thank you for Banking with CBE!";
  final cbeCredit = "Dear Abel your Account 1*********8193 has been Credited with ETB 100.00 from Nathnael Adinew. on 15/10/2025 at 13:49:25 with Ref No FT2528885KX6 Your Current Balance is ETB 273.79. Thank you for Banking with CBE!";
  final cbeDebit = "Dear Abel your Account 1*********8193 has been debited with ETB11.00 .Service charge of ETB10 and VAT(15%) of ETB1.50 with a total of ETB22. Your Current Balance is ETB 173.79. Thank you for Banking with CBE!";
  
  print("Testing CBE Transfer:");
  print("SMS: $cbeTransfer\n");
  
  // Test transfer patterns
  final transferAmountPattern = RegExp(r"transferred ETB\s*([0-9,]+(?:\.\d{2})?)", caseSensitive: false);
  final transferAmountMatch = transferAmountPattern.firstMatch(cbeTransfer);
  print("Transfer Amount: ${transferAmountMatch?.group(1)}");
  
  final transferMerchantPattern = RegExp(r"to\s+([^\s]+(?:\s+[^\s]+)*?)\s+on", caseSensitive: false);
  final transferMerchantMatch = transferMerchantPattern.firstMatch(cbeTransfer);
  print("Transfer Merchant: ${transferMerchantMatch?.group(1)}");
  
  final transferBalancePattern = RegExp(r"Your Current Balance is ETB\s*([0-9,]+(?:\.\d{2})?)", caseSensitive: false);
  final transferBalanceMatch = transferBalancePattern.firstMatch(cbeTransfer);
  print("Transfer Balance: ${transferBalanceMatch?.group(1)}");
  
  final transferTimestampPattern = RegExp(r"at\s+(\d{2}:\d{2}:\d{2})", caseSensitive: false);
  final transferTimestampMatch = transferTimestampPattern.firstMatch(cbeTransfer);
  print("Transfer Timestamp: ${transferTimestampMatch?.group(1)}\n");
  
  print("=" * 50);
  
  print("Testing CBE Credit:");
  print("SMS: $cbeCredit\n");
  
  // Test credit patterns
  final creditAmountPattern = RegExp(r"Credited with ETB\s*([0-9,]+(?:\.\d{2})?)", caseSensitive: false);
  final creditAmountMatch = creditAmountPattern.firstMatch(cbeCredit);
  print("Credit Amount: ${creditAmountMatch?.group(1)}");
  
  final creditMerchantPattern = RegExp(r"from\s+([^.]+?)(?:\.|on)", caseSensitive: false);
  final creditMerchantMatch = creditMerchantPattern.firstMatch(cbeCredit);
  print("Credit Merchant: ${creditMerchantMatch?.group(1)}");
  
  final creditBalancePattern = RegExp(r"Your Current Balance is ETB\s*([0-9,]+(?:\.\d{2})?)", caseSensitive: false);
  final creditBalanceMatch = creditBalancePattern.firstMatch(cbeCredit);
  print("Credit Balance: ${creditBalanceMatch?.group(1)}");
  
  final creditRefPattern = RegExp(r"Ref No\s+([A-Z0-9]+)", caseSensitive: false);
  final creditRefMatch = creditRefPattern.firstMatch(cbeCredit);
  print("Credit Ref: ${creditRefMatch?.group(1)}");
  
  final creditTimestampPattern = RegExp(r"at\s+(\d{2}:\d{2}:\d{2})", caseSensitive: false);
  final creditTimestampMatch = creditTimestampPattern.firstMatch(cbeCredit);
  print("Credit Timestamp: ${creditTimestampMatch?.group(1)}\n");
  
  print("=" * 50);
  
  print("Testing CBE Debit:");
  print("SMS: $cbeDebit\n");
  
  // Test debit patterns
  final debitAmountPattern = RegExp(r"debited with ETB\s*([0-9,]+(?:\.\d{2})?)", caseSensitive: false);
  final debitAmountMatch = debitAmountPattern.firstMatch(cbeDebit);
  print("Debit Amount: ${debitAmountMatch?.group(1)}");
  
  final debitBalancePattern = RegExp(r"Your Current Balance is ETB\s*([0-9,]+(?:\.\d{2})?)", caseSensitive: false);
  final debitBalanceMatch = debitBalancePattern.firstMatch(cbeDebit);
  print("Debit Balance: ${debitBalanceMatch?.group(1)}");
}
