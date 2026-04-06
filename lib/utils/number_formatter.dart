class NumberFormatter {
  static String format(int number) {
    if (number >= 1000000) {
      double millions = number / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}M';
    } else if (number >= 1000) {
      double thousands = number / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}k';
    } else {
      return number.toString();
    }
  }
}
