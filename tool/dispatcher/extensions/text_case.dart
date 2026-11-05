/// Changes the case of the first letter.
extension TextCase on String {
  String get lowerFirst => isEmpty ? this : '${this[0].toLowerCase()}${substring(1)}';
}
