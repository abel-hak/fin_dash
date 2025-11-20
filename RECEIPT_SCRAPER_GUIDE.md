# 🧪 Receipt Scraper Test Tool - User Guide

## 🎯 What is This?

A **standalone test tool** to test receipt link scraping BEFORE integrating into the main app.

---

## 📱 How to Access

1. **Run your app**
2. **Go to Settings** (sidebar menu)
3. **Scroll to "Data Management"**
4. **Click "Test Receipt Scraper"**

---

## 🔧 How to Use

### **Step 1: Get a Receipt Link**
- Receive transaction SMS from any bank
- Copy the receipt URL (e.g., `https://transactioninfo.ethiotelecom.et/receipt/CJ99D8Z5WV`)

### **Step 2: Paste in Test Tool**
- Open Receipt Scraper Test screen
- Paste URL in the text field
- Or click **Paste** button to auto-paste from clipboard

### **Step 3: Scrape**
- Click **"Scrape Receipt"** button
- Wait for results (usually 2-5 seconds)

### **Step 4: Analyze Results**
- ✅ **Green checkmarks** = Data found
- ❌ **Red X** = Data not found
- View extracted data:
  - Transaction ID
  - Merchant name
  - Amount
  - Date & Time
  - Status
  - Payment method
  - Reference number
  - Description
  - Service charges

### **Step 5: Debug (Optional)**
- Click **"Show Raw HTML"** to see the actual page HTML
- Click **Copy** to copy HTML for analysis
- Use this to understand page structure

---

## 🧪 Testing Different Banks

### **Test with Multiple Banks:**
1. **Telebirr** - `https://transactioninfo.ethiotelecom.et/receipt/...`
2. **CBE** - Test with CBE receipt links
3. **Awash Bank** - Test with Awash receipt links
4. **M-PESA** - Test with M-PESA receipt links

### **What to Look For:**
- Which fields are successfully extracted?
- Which fields are missing?
- Is the HTML structure similar across banks?
- Are there common class names/IDs?

---

## 📊 Scraping Strategies Used

The tool uses **5 different strategies** to extract data:

### **Strategy 1: Common Class/ID Names**
Looks for standard HTML selectors:
- `.transaction-id`, `#transaction-id`
- `.merchant-name`, `.merchant`
- `.amount`, `.total`, `.price`
- `.date`, `.time`, `.timestamp`
- etc.

### **Strategy 2: Full Text Extraction**
Extracts all text from the page for AI analysis fallback.

### **Strategy 3: Table Data**
Extracts key-value pairs from HTML tables.

### **Strategy 4: Meta Tags**
Extracts data from `<meta>` tags.

### **Strategy 5: Structured Data**
Looks for JSON-LD structured data.

---

## ✅ Success Criteria

### **Good Results:**
- ✅ Transaction ID extracted
- ✅ Merchant name extracted
- ✅ Amount extracted
- ✅ Date/Time extracted
- **→ Ready to integrate!**

### **Partial Results:**
- ✅ Some fields extracted
- ❌ Some fields missing
- **→ Need to adjust selectors or use AI fallback**

### **Poor Results:**
- ❌ Most fields missing
- **→ Use AI parsing as primary method**

---

## 🔄 Next Steps Based on Results

### **If Scraping Works Well (70%+ fields extracted):**
1. ✅ Integrate scraper into SMS parser
2. ✅ Auto-fetch receipt data on SMS receive
3. ✅ Use scraped data to verify SMS data
4. ✅ Increase confidence scores

### **If Scraping Partially Works (30-70% fields):**
1. ✅ Use scraper for available fields
2. ✅ Use AI parsing for missing fields
3. ✅ Combine both methods

### **If Scraping Doesn't Work (<30% fields):**
1. ✅ Use AI parsing as primary
2. ✅ Keep scraper as fallback
3. ✅ Store receipt links for manual viewing

---

## 🚀 Integration Plan

### **Phase 1: Store Receipt Links** (Immediate)
```dart
// Extract link from SMS
final receiptUrl = extractReceiptLink(smsBody);

// Store in database
await db.insertTransaction({
  'receipt_url': receiptUrl,
  'has_receipt': receiptUrl != null ? 1 : 0,
});
```

### **Phase 2: Auto-Scrape on Background** (Next)
```dart
// After SMS is parsed, scrape receipt in background
if (transaction.hasReceipt) {
  _scrapeReceiptInBackground(transaction.receiptUrl);
}
```

### **Phase 3: Verify & Enrich** (Later)
```dart
// Compare SMS data with receipt data
final match = compareWithReceipt(smsData, receiptData);
if (match) {
  transaction.confidence = 99; // Verified!
}
```

---

## 💡 Tips

1. **Test with real receipts** from your actual transactions
2. **Test multiple banks** to see patterns
3. **Check "Show Raw HTML"** if data is missing
4. **Look for common patterns** across different banks
5. **Document which banks work best**

---

## 🐛 Troubleshooting

### **Error: "Failed to load receipt"**
- Check internet connection
- Receipt link might be expired
- Receipt page might require authentication

### **Error: "Permission denied"**
- Some receipts might be private
- Try with different receipt link

### **All fields show "Not found"**
- Page structure is different than expected
- Click "Show Raw HTML" to analyze
- May need AI parsing instead

---

## 📝 Example Test Workflow

```
1. Open app → Settings → Test Receipt Scraper
2. Paste: https://transactioninfo.ethiotelecom.et/receipt/CJ99D8Z5WV
3. Click "Scrape Receipt"
4. Results:
   ✅ Transaction ID: CJ99D8Z5WV
   ✅ Merchant: Ethio Telecom
   ✅ Amount: ETB 500.00
   ✅ Date: Nov 12, 2025
   ✅ Status: Successful
5. Conclusion: Scraping works! Ready to integrate.
```

---

## 🎯 Decision Matrix

| Extraction Rate | Action |
|----------------|--------|
| 70-100% | ✅ Use scraping as primary |
| 30-70% | ⚠️ Use hybrid (scraping + AI) |
| 0-30% | ❌ Use AI as primary |

---

## 🚀 Ready to Integrate?

Once you've tested with multiple banks and confirmed scraping works:

1. **Update SMS parser** to extract receipt links
2. **Update database** to store receipt URLs
3. **Add background scraper** to fetch receipt data
4. **Update UI** to show "Receipt Verified" badge
5. **Add "View Receipt"** button to transactions

---

**Happy Testing!** 🎉
