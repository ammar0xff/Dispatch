import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class TelegramLogger {
  static const String botToken = "7783807694:AAFwbq5HY_VgmHfroKWzRG_LGh9xEpDL-RE";
  static const String chatId = "5232572931";

  static Future<void> sendLog(Map<String, dynamic> qrProfileInfo, String scannerName, String scanLocation, double latitude, double longitude) async {
    DateTime now = DateTime.now();
    String date = DateFormat('yyyy-MM-dd').format(now);
    String time = DateFormat('hh:mm a').format(now);
    String googleMapsLink = "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
    String message = """
تمت عملية مسح جديدة:
- التاريخ: $date
- الماسح: $scannerName
- الوقت: $time
- رابط الموقع: $googleMapsLink

تفاصيل التاجر:
- الاسم: ${qrProfileInfo['name']}
- الفئة: ${qrProfileInfo['category']}
- الهاتف: ${qrProfileInfo['phone']}
- الموقع: ${qrProfileInfo['location']}
""";

    String url = "https://api.telegram.org/bot$botToken/sendMessage";
    await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"chat_id": chatId, "text": message}),
    );
  }
}
