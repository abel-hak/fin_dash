# Real SMS Test Cases - Expected Extraction

## 🧪 Test Cases from Your Actual SMS

---

### Test 1: Telebirr - Transfer to Person

#### Input SMS:
```
Dear Abel 
You have transferred ETB 125.00 to adenewo abiyo (2519****8495) on 06/10/2025 14:00:51. Your transaction number is CJ62BBQ8ME. The service fee is  ETB 1.74 and  15% VAT on the service fee is ETB 0.26. Your current E-Money Account  balance is ETB 105.55.
```

#### Expected Extraction:
```json
{
  "amount": 125.00,
  "merchant": "adenewo abiyo",
  "balance": 105.55,
  "transaction_id": "CJ62BBQ8ME",
  "currency": "ETB",
  "channel": "telebirr",
  "confidence": 1.0
}
```

#### Template Used: `telebirr_transfer_v3`

---

### Test 2: Telebirr - Payment for Package

#### Input SMS:
```
Dear Abel
You have paid ETB 13.00 for package Hourly unlimited Internet purchase made for 995527848 on 09/10/2025 10:45:59. Your transaction number is  CJ92D90APK. Your current balance is ETB 0.55.
```

#### Expected Extraction:
```json
{
  "amount": 13.00,
  "merchant": "Hourly unlimited Internet",
  "balance": 0.55,
  "transaction_id": "CJ92D90APK",
  "currency": "ETB",
  "channel": "telebirr",
  "confidence": 1.0
}
```

#### Template Used: `telebirr_transfer_v3`

---

### Test 3: Telebirr - Daily Package

#### Input SMS:
```
Dear Abel
You have paid ETB 63.00 for package Daily unlimited Internet purchase made for 995527848 on 07/10/2025 14:02:48. Your transaction number is  CJ78C0LO6A. Your current balance is ETB 29.55.
```

#### Expected Extraction:
```json
{
  "amount": 63.00,
  "merchant": "Daily unlimited Internet",
  "balance": 29.55,
  "transaction_id": "CJ78C0LO6A",
  "currency": "ETB",
  "channel": "telebirr",
  "confidence": 1.0
}
```

#### Template Used: `telebirr_transfer_v3`

---

### Test 4: CBE - Transfer with Merchant Name

#### Input SMS:
```
Dear Abel, You have transfered ETB 30.00 to Mukemil Hayredin on 16/10/2025 at 17:42:48 from your account 1*********8193. Your account has been debited with a S.charge of ETB 0.50 and  15% VAT of ETB0.08, with a total of ETB30.58. Your Current Balance is ETB 762.63.
```

#### Expected Extraction:
```json
{
  "amount": 30.00,
  "merchant": "Mukemil Hayredin",
  "account_alias": "1*********8193",
  "balance": 762.63,
  "currency": "ETB",
  "channel": "cbe",
  "confidence": 1.0
}
```

#### Template Used: `cbe_transfer_v3`

---

### Test 5: CBE - Transfer to Another Person

#### Input SMS:
```
Dear Abel, You have transfered ETB 100.00 to Kidus Yared on 17/10/2025 at 16:21:36 from your account 1*********8193. Your account has been debited with a S.charge of ETB 0.50 and  15% VAT of ETB0.08, with a total of ETB100.58. Your Current Balance is ETB 481.47.
```

#### Expected Extraction:
```json
{
  "amount": 100.00,
  "merchant": "Kidus Yared",
  "account_alias": "1*********8193",
  "balance": 481.47,
  "currency": "ETB",
  "channel": "cbe",
  "confidence": 1.0
}
```

#### Template Used: `cbe_transfer_v3`

---

### Test 6: CBE - Debit Without Merchant

#### Input SMS:
```
Dear Abel your Account 1*********8193 has been debited with ETB50.00 .Service charge of  ETB10 and VAT(15%) of ETB1.50 with a total of ETB61. Your Current Balance is ETB 28.24.
```

#### Expected Extraction:
```json
{
  "amount": 50.00,
  "merchant": "CBE",
  "account_alias": "1*********8193",
  "balance": 28.24,
  "currency": "ETB",
  "channel": "cbe",
  "confidence": 0.75
}
```

#### Template Used: `cbe_debit_v3`

---

## 📊 Pattern Breakdown

### Telebirr Patterns

#### Amount:
```regex
(?:transferred|paid)\s+ETB\s*([\d,]+(?:\.\d{2})?)
```
**Matches:**
- "transferred ETB 125.00"
- "paid ETB 13.00"

#### Merchant:
```regex
(?:to|for package)\s+([A-Za-z][A-Za-z\s]{2,50})(?:\s*\([0-9*]{8,}\)|\s+purchase|\s+on)
```
**Matches:**
- "to adenewo abiyo (2519****8495)" → "adenewo abiyo"
- "for package Hourly unlimited Internet purchase" → "Hourly unlimited Internet"
- "for package Daily unlimited Internet purchase" → "Daily unlimited Internet"

#### Balance:
```regex
(?:current|E-Money Account)\s+balance\s+is\s+ETB\s*([\d,]+(?:\.\d{2})?)
```
**Matches:**
- "current balance is ETB 0.55"
- "E-Money Account balance is ETB 105.55"

#### Transaction ID:
```regex
transaction\s+number\s+is\s+([A-Z0-9]{6,})
```
**Matches:**
- "transaction number is CJ62BBQ8ME"
- "transaction number is  CJ92D90APK" (handles extra spaces)

---

### CBE Patterns

#### Transfer Amount:
```regex
(?:transfered|transferred)\s+ETB\s*([\d,]+(?:\.\d{2})?)
```
**Matches:**
- "transfered ETB 30.00"
- "transferred ETB 100.00"

#### Transfer Merchant:
```regex
(?:transfered|transferred)\s+ETB\s*[\d,]+(?:\.\d{2})?\s+to\s+([A-Za-z][A-Za-z\s]{2,40})\s+on
```
**Matches:**
- "transfered ETB 30.00 to Mukemil Hayredin on" → "Mukemil Hayredin"
- "transfered ETB 100.00 to Kidus Yared on" → "Kidus Yared"

#### Debit Amount:
```regex
(?:debited with|has been debited with)\s+ETB\s*([\d,]+(?:\.\d{2})?)
```
**Matches:**
- "has been debited with ETB50.00"
- "debited with ETB 100.00"

#### Account:
```regex
(?:from\s+your\s+)?account\s+([0-9*]+)
```
**Matches:**
- "from your account 1*********8193"
- "your Account 1*********8193"

#### Balance:
```regex
(?:Your\s+)?Current\s+Balance\s+is\s+ETB\s*([\d,]+(?:\.\d{2})?)
```
**Matches:**
- "Your Current Balance is ETB 762.63"
- "Current Balance is ETB 28.24"

---

## ✅ Confidence Scores

| Test Case | Fields Extracted | Confidence | Quality |
|-----------|------------------|------------|---------|
| Telebirr Transfer | 5/5 (amount, merchant, balance, tx_id, currency) | 100% | Excellent |
| Telebirr Payment | 5/5 (amount, merchant, balance, tx_id, currency) | 100% | Excellent |
| CBE Transfer | 5/5 (amount, merchant, account, balance, currency) | 100% | Excellent |
| CBE Debit | 4/5 (amount, account, balance, currency) | 75% | Good |

---

## 🎯 Dashboard Impact

### Before (Old Templates):
```json
{
  "merchant": "Dear Abel You have transferred ETB 125.00 to adenewo abiyo...",
  "balance": null,
  "account_alias": null
}
```

### After (New Templates v3):
```json
{
  "merchant": "adenewo abiyo",
  "balance": 105.55,
  "account_alias": "1*********8193",
  "transaction_id": "CJ62BBQ8ME"
}
```

---

## 🧪 How to Test

1. **Hot restart** the app
2. **Send these exact SMS** from emulator console
3. **Check logs** for:
   ```
   🔍 Parser [telebirr_transfer_v3]: ✓ Matched merchant: adenewo abiyo
   🔍 Parser [telebirr_transfer_v3]: ✓ Matched balance: 105.55
   🔍 Parser [telebirr_transfer_v3]: ✓ Matched transaction_id: CJ62BBQ8ME
   ```
4. **Verify database** - Check parsed transactions table

---

## 📝 Template Priority Order

The parser will try templates in this order:

### For Telebirr:
1. `telebirr_transfer_v3` → Handles both transfers and payments

### For CBE:
1. `cbe_transfer_v3` → Try transfer format first (has merchant name)
2. `cbe_debit_v3` → Fallback for debits without merchant
3. General Parser → Ultimate fallback

---

## 🚀 Expected Results

After hot restart, all your real SMS should parse with:
- ✅ Clean merchant names
- ✅ Correct balances
- ✅ Account numbers
- ✅ Transaction IDs
- ✅ 75-100% confidence scores

---

**Status:** ✅ Templates Optimized for Real SMS  
**Next:** Test with actual SMS messages!
