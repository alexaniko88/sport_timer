extension DateTimeExtension on DateTime {
  // Formats the year, month and day of this value as yyyy-MM-dd, with no timezone conversion.
  String get asIsoDate => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
