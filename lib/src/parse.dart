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

const int plusSymbol = 0x2B /* + */;
const int minusSymbol = 0x2D /* - */;
const int pointSymbol = 0x2E /* . */;
const List<int> expSymbols = [0x45, 0x65] /* e|E */;

const int zeroSymbol = 0x30 /* 0 */;
const int nineSymbol = 0x39 /* 9 */;

final RegExp ldRegexp = RegExp(r"(\+|-)?(\d*.)?\d+(e|E(\+|-)?\d+)?");
final RegExp infRegexp = RegExp(r"(\+|-)?Infinity");
final RegExp nanRegexp = RegExp(r"(\+|-)?NaN");

//All positive powers of ten up to 22 are exact as doubles
//Cache the negative powers of ten up to 22 so that our
//parser can output the closest longdouble value for
//negative powers up to 22 too
const List<LongDouble> negPowersOfTen = [
  LongDouble.zero(),
  LongDouble(1.0e-1, -5.551115123125783e-18),
  LongDouble(1.0e-2, -2.0816681711721684e-19),
  LongDouble(1.0e-3, -2.0816681711721686e-20),
  LongDouble(1.0e-4, -4.79217360238593e-21),
  LongDouble(1.0e-5, -8.180305391403131e-22),
  LongDouble(1.0e-6, 4.525188817411374e-23),
  LongDouble(1.0e-7, 4.525188817411374e-24),
  LongDouble(1.0e-8, -2.092256083012847e-25),
  LongDouble(1.0e-9, -6.228159145777985e-26),
  LongDouble(1.0e-10, -3.643219731549774e-27),
  LongDouble(1.0e-11, 6.050303071806019e-28),
  LongDouble(1.0e-12, 2.0113352370744385e-29),
  LongDouble(1.0e-13, -3.037374556340037e-30),
  LongDouble(1.0e-14, 1.1806906454401013e-32),
  LongDouble(1.0e-15, -7.770539987666108e-32),
  LongDouble(1.0e-16, 2.0902213275965398e-33),
  LongDouble(1.0e-17, -7.154242405462192e-34),
  LongDouble(1.0e-18, -7.154242405462193e-35),
  LongDouble(1.0e-19, 2.475407316473987e-36),
  LongDouble(1.0e-20, 5.484672854579043e-37),
  LongDouble(1.0e-21, 9.246254777210363e-38),
  LongDouble(1.0e-22, -4.859677432657087e-39),
];

/// Returns the value of the digit if the rune represents
/// the code point of a decimal digit, else returns -1;
_digitValue(int rune) {
  if (rune >= zeroSymbol && rune < nineSymbol) {
    return rune - zeroSymbol;
  }
  return -1;
}

LongDouble _parseLongdouble(String source,
    [LongDouble Function(String source)? onError]) {
  //Remove leading and trailing whitespace chars.
  source = source.trim();
  var match = infRegexp.matchAsPrefix(source);
  if (match != null) {
    return source.startsWith('-')
        ? LongDouble.negativeInfinity
        : LongDouble.infinity;
  }
  match = nanRegexp.matchAsPrefix(source);
  if (match != null) {
    return LongDouble.nan;
  }
  match = ldRegexp.matchAsPrefix(source);
  if (match == null) {
    if (onError != null) {
      return onError(source);
    }
    throw FormatException(source);
  }
  bool inExponent = false;
  bool isMantissaPositive = true;
  bool isExponentPositive = true;
  //The position of the decimal point, if one exists in the source.
  int pointPosition = -1;
  List<int> significandDigits = [];
  List<int> exponentDigits = [];
  int i = 0;
  for (var rune in source.runes) {
    i++;
    if (rune == plusSymbol) {
      continue;
    } else if (rune == minusSymbol) {
      if (inExponent) {
        isExponentPositive = false;
      } else {
        isMantissaPositive = false;
      }
      continue;
    } else if (expSymbols.contains(rune)) {
      inExponent = true;
      continue;
    } else if (rune == pointSymbol) {
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
  LongDouble significand = LongDouble.zero();

  for (var i = 0; i < significandDigits.length; i++) {
    significand = significand * 10 + significandDigits[i];
  }

  int exponentSign = isExponentPositive ? 1 : -1;
  int exponent =
      exponentSign * exponentDigits.fold(0, (exp, d) => 10 * exp + d);

  LongDouble exponentMultiplier;

  if (exponent >= 0) {
    if (pointPosition >= 0) {
      exponent -= (pointPosition +
          significandDigits.takeWhile((d) => d == 0).length -
          1);
    }
    exponentMultiplier = math_ld.intpow(LongDouble(10.0), exponent);
  } else {
    exponent -= (significandDigits.length - pointPosition + 1);

    //Positive powers of 10 up to 22 are exact as doubles
    //But the same isn't true for negative powers of 10.
    //Rectify this by providing the closest longdouble value (cached in _NEG_POWERS_OF_TEN),
    //rather than using the double value.
    if (exponent >= -22) {
      exponentMultiplier = negPowersOfTen[exponent.abs()];
    } else {
      exponentMultiplier =
          negPowersOfTen[22] * math_ld.intpow(LongDouble(10.0), exponent + 22);
    }
  }

  return significand * exponentMultiplier * sign;
}
