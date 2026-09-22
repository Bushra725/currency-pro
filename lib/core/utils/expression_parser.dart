import 'dart:math' as math;

/// Raised when an expression cannot be evaluated.
class ExpressionError implements Exception {
  ExpressionError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A small recursive-descent evaluator powering the scientific calculator.
///
/// Supports:
///   * `+ - × ÷ % ^` and parentheses
///   * unary minus, postfix `!` (factorial) and `%` (percent-of)
///   * `sin cos tan asin acos atan sinh cosh tanh ln log sqrt cbrt abs exp`
///   * constants `pi` and `e`
///   * degree or radian mode for trigonometry
class ExpressionParser {
  ExpressionParser({this.degrees = true});

  /// When true trigonometric functions take and return degrees.
  final bool degrees;

  late String _src;
  late int _pos;

  double evaluate(String input) {
    _src = _normalise(input);
    _pos = 0;
    final double value = _parseExpression();
    _skipSpaces();
    if (_pos < _src.length) {
      throw ExpressionError('Unexpected "${_src[_pos]}"');
    }
    if (value.isNaN) throw ExpressionError('Not a number');
    return value;
  }

  /// Returns null instead of throwing — handy for live previews.
  double? tryEvaluate(String input) {
    try {
      return evaluate(input);
    } catch (_) {
      return null;
    }
  }

  static String _normalise(String input) {
    return input
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('π', 'pi')
        .replaceAll('√', 'sqrt')
        .replaceAll(',', '')
        .replaceAll(' ', '');
  }

  // -- grammar ------------------------------------------------------------
  // expression := term (('+' | '-') term)*
  // term       := factor (('*' | '/' | '%') factor)*
  // factor     := unary ('^' factor)?
  // unary      := ('-' | '+')? postfix
  // postfix    := primary ('!' | '%')*
  // primary    := number | constant | function '(' expression ')'
  //             | '(' expression ')'

  double _parseExpression() {
    double value = _parseTerm();
    while (true) {
      _skipSpaces();
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    double value = _parseFactor();
    while (true) {
      _skipSpaces();
      if (_match('*')) {
        value *= _parseFactor();
      } else if (_match('/')) {
        final double d = _parseFactor();
        if (d == 0) throw ExpressionError('Division by zero');
        value /= d;
      } else if (_peek() == '%' && !_isPercentPostfix()) {
        _pos++;
        final double d = _parseFactor();
        if (d == 0) throw ExpressionError('Division by zero');
        value = value % d;
      } else {
        return value;
      }
    }
  }

  double _parseFactor() {
    final double base = _parseUnary();
    _skipSpaces();
    if (_match('^')) {
      final double exponent = _parseFactor();
      return math.pow(base, exponent).toDouble();
    }
    return base;
  }

  double _parseUnary() {
    _skipSpaces();
    if (_match('-')) return -_parseUnary();
    if (_match('+')) return _parseUnary();
    return _parsePostfix();
  }

  double _parsePostfix() {
    double value = _parsePrimary();
    while (true) {
      _skipSpaces();
      if (_peek() == '!') {
        _pos++;
        value = _factorial(value);
      } else if (_peek() == '%' && _isPercentPostfix()) {
        _pos++;
        value = value / 100;
      } else {
        return value;
      }
    }
  }

  double _parsePrimary() {
    _skipSpaces();
    if (_pos >= _src.length) throw ExpressionError('Unexpected end');

    if (_match('(')) {
      final double value = _parseExpression();
      if (!_match(')')) throw ExpressionError('Missing ")"');
      return value;
    }

    // number
    final int start = _pos;
    while (_pos < _src.length &&
        (_isDigit(_src[_pos]) || _src[_pos] == '.')) {
      _pos++;
    }
    if (_pos > start) {
      final String text = _src.substring(start, _pos);
      final double? parsed = double.tryParse(text);
      if (parsed == null) throw ExpressionError('Bad number "$text"');
      // Scientific notation: 1.2e5
      if (_pos < _src.length &&
          (_src[_pos] == 'e' || _src[_pos] == 'E') &&
          _pos + 1 < _src.length &&
          (_isDigit(_src[_pos + 1]) ||
              _src[_pos + 1] == '-' ||
              _src[_pos + 1] == '+')) {
        final int expStart = _pos;
        _pos++;
        if (_src[_pos] == '-' || _src[_pos] == '+') _pos++;
        while (_pos < _src.length && _isDigit(_src[_pos])) {
          _pos++;
        }
        final double? full =
            double.tryParse(text + _src.substring(expStart, _pos));
        if (full != null) return full;
      }
      return parsed;
    }

    // identifier: constant or function
    final int idStart = _pos;
    while (_pos < _src.length && _isLetter(_src[_pos])) {
      _pos++;
    }
    if (_pos == idStart) throw ExpressionError('Unexpected "${_src[_pos]}"');
    final String name = _src.substring(idStart, _pos).toLowerCase();

    if (name == 'pi') return math.pi;
    if (name == 'e') return math.e;

    if (!_match('(')) throw ExpressionError('Missing "(" after $name');
    final double arg = _parseExpression();
    if (!_match(')')) throw ExpressionError('Missing ")"');
    return _applyFunction(name, arg);
  }

  double _applyFunction(String name, double x) {
    final double rad = degrees ? x * math.pi / 180 : x;
    switch (name) {
      case 'sin':
        return _clean(math.sin(rad));
      case 'cos':
        return _clean(math.cos(rad));
      case 'tan':
        return _clean(math.tan(rad));
      case 'asin':
        return _fromRad(math.asin(x));
      case 'acos':
        return _fromRad(math.acos(x));
      case 'atan':
        return _fromRad(math.atan(x));
      case 'sinh':
        return (math.exp(x) - math.exp(-x)) / 2;
      case 'cosh':
        return (math.exp(x) + math.exp(-x)) / 2;
      case 'tanh':
        final double a = math.exp(x);
        final double b = math.exp(-x);
        return (a - b) / (a + b);
      case 'ln':
        if (x <= 0) throw ExpressionError('ln needs a positive number');
        return math.log(x);
      case 'log':
        if (x <= 0) throw ExpressionError('log needs a positive number');
        return math.log(x) / math.ln10;
      case 'sqrt':
        if (x < 0) throw ExpressionError('√ of a negative number');
        return math.sqrt(x);
      case 'cbrt':
        return x.isNegative
            ? -math.pow(-x, 1 / 3).toDouble()
            : math.pow(x, 1 / 3).toDouble();
      case 'abs':
        return x.abs();
      case 'exp':
        return math.exp(x);
      default:
        throw ExpressionError('Unknown function "$name"');
    }
  }

  double _fromRad(double value) => degrees ? value * 180 / math.pi : value;

  /// Rounds values like 1.2246e-16 (sin 180°) down to a clean zero.
  static double _clean(double value) =>
      value.abs() < 1e-12 ? 0 : double.parse(value.toStringAsFixed(12));

  static double _factorial(double value) {
    if (value < 0 || value != value.roundToDouble()) {
      throw ExpressionError('! needs a whole number ≥ 0');
    }
    if (value > 170) throw ExpressionError('Too large for !');
    double out = 1;
    for (int i = 2; i <= value.toInt(); i++) {
      out *= i;
    }
    return out;
  }

  // -- lexer helpers ------------------------------------------------------
  String _peek() => _pos < _src.length ? _src[_pos] : '';

  bool _match(String ch) {
    _skipSpaces();
    if (_pos < _src.length && _src[_pos] == ch) {
      _pos++;
      return true;
    }
    return false;
  }

  void _skipSpaces() {
    while (_pos < _src.length && _src[_pos] == ' ') {
      _pos++;
    }
  }

  /// `50%` is a postfix percent; `50 % 7` is a modulo. Treat the symbol as a
  /// postfix when nothing that could start a number follows it.
  bool _isPercentPostfix() {
    int i = _pos + 1;
    while (i < _src.length && _src[i] == ' ') {
      i++;
    }
    if (i >= _src.length) return true;
    final String next = _src[i];
    return !(_isDigit(next) || _isLetter(next) || next == '(' || next == '.');
  }

  static bool _isDigit(String ch) => ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;

  static bool _isLetter(String ch) {
    final int c = ch.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
  }
}
