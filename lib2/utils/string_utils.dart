extension StringExtensions on String {
  bool get _isNumeric => num.tryParse(this) != null;

  String capitalizefirst() {
    if (isEmpty || _isNumeric) return this;

    return this[0].toUpperCase() + substring(1).toLowerCase();
  }

  String toTitle() {
    if (isEmpty) return this;

    return split(' ').map((word) {
      if (word.isEmpty || num.tryParse(word) != null) return word;

      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}