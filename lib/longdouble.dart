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

library longdouble;

import 'dart:math' as math;
import 'math.dart' as math_ld;

part 'src/parse.dart';

/// Implementation of `106` bit precision floating point
/// numbers.
///
/// [LongDouble] values are not intended to provide more
/// precision than [double] values, although with judicious
/// use, it is possible to obtain more precision from
/// a longdouble than from a [double] value.
///
/// Since mainly intended to be constructed from existing double values,
/// a [LongDouble] literal will have the same ULP error as the
/// [double] value that it was constructed from. They can, however
/// be used to provide robustness of double calculations, in much
/// the same way that [double] values were originally intended to
/// provide robustness in calculations where data was stored in
/// float32 values.
///
/// Some extra precision (for longdoubles with numeric values in the range 1e-22 to 1e22)
/// is provided by the `longdouble.parse` method, for the purposes of constructing
/// accurate literal values.
///
/// The implmentation in this module is taken largely from
/// Robert Munafo's implementation of quad precision doubles
/// http://mrob.com/pub/math/f161.html

class LongDouble implements Comparable<LongDouble> {
  static const LongDouble nan = LongDouble(double.nan, double.nan);

  static const LongDouble infinity =
      LongDouble(double.infinity, double.infinity);

  static const LongDouble negativeInfinity =
      LongDouble(double.negativeInfinity, double.negativeInfinity);

  /// Parse [input] as a longdouble literal.
  ///
  /// A longdouble literal will match the same pattern as a double literal,
  /// with an optional sign, followed by a mantissal and exponent.
  ///
  /// Leading and trailing whitespace is ignored.

  static LongDouble parse(String input,
          [LongDouble Function(String input)? onError]) =>
      _parseLongdouble(input, onError);

  final double hi;
  final double lo;

  /// Initialize a [LongDouble] with the given [:hi:]
  /// and [:lo:] double values.
  const LongDouble(this.hi, [this.lo = 0.0]);

  const LongDouble.zero() : this(0.0, 0.0);

  /// Return the value of `1.0 / this`.
  /// Since it's impossible to implement operators on double taking a left value of a [LongDouble],
  /// the only way to divide by a [LongDouble] is to multiply by the reciprocal
  LongDouble get reciprocal => longDoubleDivision(LongDouble(1.0), this);

  /// Retrieve the result as a double value
  double toDouble() => hi + lo;

  bool get isNaN => hi.isNaN;
  bool get isNegative => hi.isNegative || hi == 0.0 && lo.isNegative;
  bool get isInfinite => hi.isInfinite || lo.isInfinite;
  bool get isZero => hi == 0.0 && lo == 0.0;

  /// Compares the longdouble to the num [:a:],
  /// returning a negative number if this is less than a,
  /// a positive number if this is equal to a and `0` otherwise.
  ///
  /// For the purposes of comparison, a NaN value tests equal
  /// to other NaN values and greater than any other value,
  /// including `Infinity`
  int compareToNum(num a) {
    if (isInfinite) {
      if (isNegative) {
        return a.isNegative ? 0 : -1;
      } else {
        return a.isNegative ? 1 : 0;
      }
    }
    if (isNaN) {
      if (a.isNaN) return 0;
      return 1;
    }
    if (a.isNaN) return -1;
    var cmpHi = hi.compareTo(a);
    if (cmpHi != 0) return cmpHi;
    return lo.compareTo(0.0);
  }

  /// Compares the longdouble to the num [:a:],
  /// returning a negative number if this is less than a,
  /// a positive number if this is equal to a and `0` otherwise.
  ///
  /// For the purposes of comparison, a NaN value tests equal
  /// to other NaN values and greater than any other value,
  /// including `Infinity`
  @override
  int compareTo(LongDouble ld) {
    if (isInfinite) {
      if (isNegative) {
        return ld.isNegative ? 0 : -1;
      } else {
        return ld.isNegative ? 1 : 0;
      }
    }
    if (isNaN) {
      if (ld.isNaN) return 0;
      return 1;
    }
    var cmpHi = hi.compareTo(ld.hi);
    if (cmpHi != 0) return cmpHi;
    return lo.compareTo(ld.lo);
  }

  /// The absolute value of `this`
  LongDouble abs() {
    if (isNaN) return this;
    if (hi < 0.0) {
      return LongDouble(-hi, -lo);
    } else if (hi > 0.0) {
      return this;
    } else if (lo < 0.0) {
      return LongDouble(-hi, -lo);
    } else {
      return this;
    }
  }

  int floor() => toDouble().floor();
  double floorToDouble() => toDouble().floorToDouble();

  int ceil() => toDouble().ceil();
  double ceilToDouble() => toDouble().ceilToDouble();

  /// Unary negation operator
  LongDouble operator -() => LongDouble(-hi, -lo);

  /// Multiply the value of `this` by the num or longdouble value [:v:].
  LongDouble operator *(dynamic v) {
    if (v is num) {
      if (isNaN || v.isNaN) return nan;
      if (isInfinite || v.isInfinite) {
        if (isNegative) {
          return v.isNegative ? infinity : negativeInfinity;
        } else {
          return v.isNegative ? negativeInfinity : infinity;
        }
      }
      var t0 = _multDoubles(hi, v.toDouble());
      var d = _multDoubles(lo, v.toDouble());

      var t1 = _addDoubles(t0.lo, d.hi);
      var t2 = d.lo + t1.lo;

      return _normalizeThree(t0.hi, t1.hi, t2);
    } else if (v is LongDouble) {
      if (isNaN || v.isNaN) return nan;
      if (isInfinite || v.isInfinite) {
        if (isZero || v.isZero) return nan;
        if (isNegative) {
          return v.isNegative ? infinity : negativeInfinity;
        } else {
          return v.isNegative ? negativeInfinity : infinity;
        }
      }
      var multHiHi = _multDoubles(hi, v.hi);
      var multHiLo = _multDoubles(hi, v.lo);
      var multLoHi = _multDoubles(lo, v.hi);
      double multLoLo = lo * v.lo;

      var t1 = _addDoubles(multHiHi.lo, multHiLo.hi, multLoHi.hi);
      var t2 = multHiLo.lo + multLoHi.lo + multLoLo + t1.lo;

      return _normalizeThree(multHiHi.hi, t1.hi, t2);
    } else if (v == null) {
      throw ArgumentError("right multiplicand null");
    } else {
      throw ArgumentError(
          "right multiplicand of '*' must be a num or longdouble");
    }
  }

  /// Add the value of `this` to the num or longdouble value [:v:].
  LongDouble operator +(dynamic v) {
    if (v is num) {
      if (isNaN || v.isNaN) return nan;
      if (isInfinite) {
        if (isNegative) {
          //-inf + inf == NaN
          if (v.isInfinite && !v.isNegative) return nan;
          return negativeInfinity;
        } else {
          //inf + (-inf) == NaN
          if (v.isInfinite && v.isNegative) return nan;
          return infinity;
        }
      } else if (v.isInfinite) {
        if (v.isNegative) return negativeInfinity;
        return infinity;
      }

      var t0 = _addDoubles(hi, v.toDouble());
      var t1 = _addDoubles(lo, t0.lo);

      return _normalizeThree(t0.hi, t1.hi, t1.lo);
    } else if (v is LongDouble) {
      if (isNaN || v.isNaN) return nan;
      if (isInfinite) {
        if (isNegative) {
          //-inf + inf == NaN
          if (v.isInfinite && !v.isNegative) return nan;
          return negativeInfinity;
        } else {
          //inf + (-inf) == NaN
          if (v.isInfinite && v.isNegative) return nan;
          return infinity;
        }
      } else if (v.isInfinite) {
        if (isNegative) return negativeInfinity;
        return infinity;
      }

      var t0 = _addDoubles(hi, v.hi);
      var d = _addDoubles(lo, v.lo);
      var t1 = _addDoubles(t0.lo, d.hi);
      double t2 = d.lo + t1.lo;

      return _normalizeThree(t0.hi, t1.hi, t2);
    } else if (v == null) {
      throw ArgumentError("null summand");
    } else {
      throw ArgumentError("right summand must be num or longdouble");
    }
  }

  /// Subtract the value of [:v:] from the value of `this`.
  LongDouble operator -(dynamic v) {
    if (v is num) {
      if (isNaN || v.isNaN) return nan;
      if (isInfinite) {
        if (isNegative) {
          // -Inf - (-Inf)
          if (v.isInfinite && v.isNegative) return nan;
          return negativeInfinity;
        } else {
          // Inf - Inf
          if (v.isInfinite && !v.isNegative) return nan;
          return infinity;
        }
      } else if (v.isInfinite) {
        return v.isNegative ? infinity : negativeInfinity;
      }

      final t0 = _subtractDoubles(hi, v.toDouble());
      final t1 = _subtractDoubles(lo, t0.lo);
      return _normalizeThree(t0.hi, t1.hi, t1.lo);
    } else if (v is LongDouble) {
      if (isNaN || v.isNaN) return nan;
      if (isInfinite) {
        if (isNegative) {
          // -Inf - (-Inf)
          if (v.isInfinite && v.isNegative) return nan;
          return negativeInfinity;
        } else {
          // Inf - Inf
          if (v.isInfinite && !v.isNegative) return nan;
          return infinity;
        }
      } else if (v.isInfinite) {
        return v.isNegative ? infinity : negativeInfinity;
      }
      final t0 = _subtractDoubles(hi, v.hi);
      final d = _subtractDoubles(lo, v.lo);

      final t1 = _addDoubles(t0.lo, d.hi);
      double t2 = d.lo + t1.lo;

      return _normalizeThree(t0.hi, t1.hi, t2);
    } else if (v == null) {
      throw ArgumentError("null subtrahend");
    } else {
      throw ArgumentError("subtrahend must be num or longdouble");
    }
  }

  LongDouble operator /(dynamic v) {
    if (v is num) {
      if (isNaN || v.isNaN) return nan;
      if (isInfinite) {
        if (v.isInfinite) return nan;
        if (isNegative) {
          return v.isNegative ? infinity : negativeInfinity;
        } else {
          return v.isNegative ? negativeInfinity : infinity;
        }
      } else if (v.isInfinite) {
        return LongDouble.zero();
      } else if (v == 0.0) {
        return isNegative ? negativeInfinity : infinity;
      }
      return longDoubleDivision(this, LongDouble(v.toDouble()));
    } else if (v is LongDouble) {
      if (isNaN || v.isNaN) return nan;
      if (isInfinite) {
        if (v.isInfinite) return nan;
        if (isNegative) {
          return v.isNegative ? infinity : negativeInfinity;
        } else {
          return v.isNegative ? negativeInfinity : infinity;
        }
      } else if (v.isInfinite) {
        return LongDouble.zero();
      } else if (v == LongDouble.zero()) {
        return isNegative ? negativeInfinity : infinity;
      }
      return longDoubleDivision(this, v);
    } else {
      throw ArgumentError("right operand of '/' must be num or longdouble");
    }
  }

  /// Test whether `this` is numerically equal to [:o:].
  @override
  bool operator ==(Object o) {
    if (o is num) {
      if (isZero && o == 0.0) return true;
      if (isNaN || o.isNaN) return false;
      return compareToNum(o) == 0;
    } else if (o is LongDouble) {
      if (isNaN || o.isNaN) return false;
      if (isInfinite) {
        if (!isNegative) {
          return o.isInfinite && !o.isNegative;
        } else {
          return o.isInfinite && o.isNegative;
        }
      }
      var n1 = _normalizeTwo(hi, lo);
      var n2 = _normalizeTwo(o.hi, o.lo);
      return n1.hi == n2.hi && n1.lo == n2.lo;
    }
    return false;
  }

  bool operator >(dynamic v) =>
      (v is num && compareToNum(v) > 0) ||
      (v is LongDouble && compareTo(v) > 0);
  bool operator >=(dynamic v) =>
      (v is num && compareToNum(v) >= 0) ||
      (v is LongDouble && compareTo(v) >= 0);
  bool operator <(dynamic v) =>
      (v is num && compareToNum(v) < 0) ||
      (v is LongDouble && compareTo(v) < 0);
  bool operator <=(dynamic v) =>
      (v is num && compareToNum(v) <= 0) ||
      (v is LongDouble && compareTo(v) <= 0);

  @override
  int get hashCode => 17 * hi.hashCode + lo.hashCode;

  /// A [String] representation of the double value.
  ///
  /// Since bitwise operations aren't available for doubles in dart,
  /// any attempt to print the double in a natural format would introduce
  /// an error and produce unintuitive results.
  @override
  String toString() => "longdouble($hi|$lo)";
}

/// normalize two [double] values.
/// [:a:] is assumed to be greater than [:b:]
LongDouble _normalizeTwo(double a, double b) {
  final sum = a + b;
  final err = b - (sum - a);
  return LongDouble(sum, err);
}

/// normalize three double values, returning their sum
/// as a [LongDouble]
/// [:a:] is assumed to be greater than [:b:]
/// and [:b:] is assumed to be greater than [:c:]
LongDouble _normalizeThree(double a, double b, double c) {
  var s0 = _normalizeTwo(b, c);
  var s1 = _normalizeTwo(a, s0.hi);
  double newLo;
  if (s1.lo != 0.0) {
    newLo = s1.lo + s0.lo;
  } else {
    s0 = _normalizeTwo(s1.hi, s0.lo);
    newLo = s0.lo;
  }
  return LongDouble(s1.hi, newLo);
}

//Cached constant used in split, to prevent recalculation
final _splitConst = math.pow(2, 27) + 1;

/// Split the [double] value [:a:] into a new [LongDouble] where
/// the value returned has a [:hi:] value has the top `27` bits of precision
/// and the [:lo:] value has the bottom `27` bits of precision.
LongDouble _split(double a) {
  final y = _splitConst * a;
  final newHi = y - (y - a);
  return LongDouble(newHi, a - newHi);
}

/// Multiply two doubles, returning the result as a normalized [LongDouble]
LongDouble _multDoubles(double a, double b) {
  final newHi = a * b;
  //split both the doubles
  LongDouble sa = _split(a);
  LongDouble sb = _split(b);
  final newLo = ((sa.hi * sb.hi - newHi) + (sa.hi * sb.lo) + (sb.hi * sa.lo)) +
      sa.lo * sb.lo;
  return LongDouble(newHi, newLo);
}

/// Add two [double] values, returning the addition as a normalized [LongDouble].
LongDouble _addDoubles(double a, double b, [double? c]) {
  if (c == null) {
    //add_112
    final sum = a + b;
    final amtAdded = sum - a;
    final err = (a - (sum - amtAdded)) + (b - amtAdded);
    return LongDouble(sum, err);
  }
  //add_1113
  final sumTwo = _addDoubles(a, b);
  final sumThird = _addDoubles(sumTwo.hi, c);
  return LongDouble(sumThird.hi, sumTwo.lo + sumThird.lo);
}

/// Subtract two [double] values, returning the difference as a normalized [LongDouble]
/// //sub_112
LongDouble _subtractDoubles(double a, double b) {
  final diff = a - b;
  final amtSubtracted = diff - a;
  final err = (a - (diff - amtSubtracted)) - (b + amtSubtracted);
  return LongDouble(diff, err);
}

/// The division algorithm begins with an approximation using the
/// double division operation, then computes the error created and subtracts it out.
LongDouble longDoubleDivision(LongDouble a, LongDouble b) {
  final initApprox = a.hi / b.hi;

  var result = b * initApprox;
  final s = _subtractDoubles(a.hi, result.hi);
  var slo = s.lo;
  slo -= result.lo;
  slo += a.lo;
  var newApprox = (s.hi + slo) / b.hi;

  return _normalizeTwo(initApprox, newApprox);
}
