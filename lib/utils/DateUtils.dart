import 'package:intl/intl.dart';

class DateUtils {

  static String formatDate(DateTime dateTime) {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(Duration(days: 1));

    if (dateTime.day == today.day && dateTime.month == today.month && dateTime.year == today.year) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (dateTime == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

}