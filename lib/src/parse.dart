//    This file is part of longdouble.
//
//    longdouble is free software: you can redistribute it and/or modify
//    it under the terms of the Lesser GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    longdoulbe is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    Lesser GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with longdouble.  If not, see <http://www.gnu.org/licenses/>.

part of longdouble;

const int _PLUS_SYMBOL = 0x2B /* + */;
const int _MINUS_SYMBOL = 0x2D /* - */;
const int _POINT_SYMBOL   = 0x2E /* . */;
const List<int> _EXP_SYMBOLS   = const[0x45,0x65] /* e|E */;

const int _ZERO_SYMBOL = 0x30 /* 0 */;
const int _NINE_SYMBOL = 0x39 /* 9 */;

const String _STR_INFINITY = "Infinity";
const String _STR_NAN = "NaN";

//The maximum number of digits to print
const int _MAX_PRINT_DIGITS = 32;

final RegExp _LD_REGEXP = 
    new RegExp(r"(\+|-)?(\d*.)?\d+(e|E(\+|-)?\d+)?");
final RegExp _INF_REGEXP = 
    new RegExp(r"(\+|-)?Infinity");
final RegExp _NAN_REGEXP =
    new RegExp(r"(\+|-)?NaN");

//All positive powers of ten up to 22 are exact as doubles
//Cache the negative powers of ten up to 22 so that our
//parser can output the closest longdouble value for
//negative powers up to 22 too
const List<longdouble> _NEG_POWERS_OF_TEN = 
  const [ const longdouble.zero(),
          const longdouble(1.0e-1, -5.551115123125783e-18),
          const longdouble(1.0e-2, -2.0816681711721684e-19),
          const longdouble(1.0e-3, -2.0816681711721686e-20),
          const longdouble(1.0e-4, -4.79217360238593e-21),
          const longdouble(1.0e-5, -8.180305391403131e-22),
          const longdouble(1.0e-6, 4.525188817411374e-23),
          const longdouble(1.0e-7, 4.525188817411374e-24),
          const longdouble(1.0e-8, -2.092256083012847e-25),
          const longdouble(1.0e-9, -6.228159145777985e-26),
          const longdouble(1.0e-10, -3.643219731549774e-27),
          const longdouble(1.0e-11, 6.050303071806019e-28),
          const longdouble(1.0e-12, 2.0113352370744385e-29),
          const longdouble(1.0e-13, -3.037374556340037e-30),
          const longdouble(1.0e-14, 1.1806906454401013e-32),
          const longdouble(1.0e-15, -7.770539987666108e-32),
          const longdouble(1.0e-16, 2.0902213275965398e-33),
          const longdouble(1.0e-17, -7.154242405462192e-34),
          const longdouble(1.0e-18, -7.154242405462193e-35),
          const longdouble(1.0e-19, 2.475407316473987e-36),
          const longdouble(1.0e-20, 5.484672854579043e-37),
          const longdouble(1.0e-21, 9.246254777210363e-38),
          const longdouble(1.0e-22, -4.859677432657087e-39),
        ];
  


/**
 * Returns the value of the digit if the rune represents
 * the code point of a decimal digit, else returns -1;
 */
_digitValue(int rune) {
  if (rune >= _ZERO_SYMBOL && rune < _NINE_SYMBOL) {
    return rune - _ZERO_SYMBOL;
  }
  return -1;
}

longdouble _parseLongdouble(String source, [longdouble onError(String source)]) {
  //Remove leading and trailing whitespace chars.
  source = source.trim();
  var match = _INF_REGEXP.matchAsPrefix(source);
  if (match != null) {
    return source.startsWith('-') ? longdouble.NEGATIVE_INFINITY : longdouble.INFINITY;
  }
  match = _NAN_REGEXP.matchAsPrefix(source);
  if (match != null) {
    return longdouble.NAN;
  }
  match = _LD_REGEXP.matchAsPrefix(source);
  if (match == null) {
    if (onError != null) {
      return onError(source);
    }
    throw new FormatException(source);
  }
  bool inExponent = false;
  bool isMantissaPositive = true;
  bool isExponentPositive = true;
  //The position of the decimal point, if one exists in the source.
  int pointPosition = -1;
  List<int> significandDigits = new List<int>();
  List<int> exponentDigits = new List<int>();
  int i=0;
  for (var rune in source.runes) {
    i++;
    if (rune == _PLUS_SYMBOL) {
      continue;
    } else if (rune == _MINUS_SYMBOL) {
      if (inExponent) {
        isExponentPositive = false;
      } else {
        isMantissaPositive = false;
      }
      continue;
    } else if (_EXP_SYMBOLS.contains(rune)) {
      inExponent = true;
      continue;
    } else if (rune == _POINT_SYMBOL) {
      pointPosition = i;
    }
    var digit = _digitValue(rune);
    if (digit >= 0) {
      if (inExponent) {
        exponentDigits.add(digit);
      } else {
        significandDigits.add(digit);
      }
    }
  }
  

  var sign = isMantissaPositive ? 1.0 : -1.0;
  longdouble significand = new longdouble.zero();
  
  for (var i=0;i<significandDigits.length;i++) {
    significand = significand * 10 + significandDigits[i];
  }
  
  int exponentSign = isExponentPositive ? 1 : -1;
  int exponent = exponentSign * exponentDigits.fold(0, (exp, d) => 10*exp + d);

  var exponentMultiplier;
  
  if (exponent >= 0) {
    if (pointPosition >= 0) {
      exponent -= ( pointPosition 
                  + significandDigits.takeWhile((d) => d == 0).length
                  - 1);
    }
    exponentMultiplier = 
        math_ld.intpow(new longdouble(10.0), exponent);
  } else if (exponent < 0) {
    exponent -= (significandDigits.length - pointPosition + 1);
    
    //Positive powers of 10 up to 22 are exact as doubles
    //But the same isn't true for negative powers of 10.
    //Rectify this by providing the closest longdouble value (cached in _NEG_POWERS_OF_TEN), 
    //rather than using the double value.
    if (exponent >= -22) {
      exponentMultiplier = _NEG_POWERS_OF_TEN[exponent.abs()];
    } else {
      exponentMultiplier = 
          _NEG_POWERS_OF_TEN[22] * math_ld.intpow(new longdouble(10.0), exponent + 22);
    }
  }
  
  return significand * exponentMultiplier * sign;
}
