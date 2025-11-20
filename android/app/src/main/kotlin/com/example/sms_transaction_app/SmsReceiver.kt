package com.example.sms_transaction_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log
import io.flutter.plugin.common.EventChannel
import java.text.SimpleDateFormat
import java.util.*

class SmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "SmsReceiver"
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            return
        }

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) {
            return
        }

        // Reassemble multipart SMS if needed
        val senderAddress = messages[0].originatingAddress ?: "Unknown"
        val timestamp = messages[0].timestampMillis
        val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.getDefault())
        dateFormat.timeZone = TimeZone.getTimeZone("UTC")
        val formattedTimestamp = dateFormat.format(Date(timestamp))

        val stringBuilder = StringBuilder()
        for (message in messages) {
            stringBuilder.append(message.messageBody)
        }
        val fullMessageBody = stringBuilder.toString()

        Log.d(TAG, "SMS received from: $senderAddress")

        // Create event data map to send to Flutter
        val eventData = mapOf(
            "sender" to senderAddress,
            "body" to fullMessageBody,
            "timestamp" to formattedTimestamp,
            "timestampMillis" to timestamp
        )

        // Send event to Flutter via EventChannel
        eventSink?.success(eventData)
    }
}
