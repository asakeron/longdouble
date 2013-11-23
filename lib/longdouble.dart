library longdouble;

import 'dart:math' as math;
import 'math_ld.dart' as math_ld;

part 'src/parse.dart';

/**
  * Implementation of `106` bit precision floating point 
  * numbers.
  * 
  * [longdouble] values are not intended to provide more
  * precision than [double] values, although with judicious
  * use, it is possible to obtain more precision from 
  * a longdouble than from a [double] value. 
  * 
  * Since mainly intended to be constructed from existing double values, 
  * a [longdouble] literal will have the same ULP error as the
  * [double] value that it was constructed from. They can, however
  * be used to provide robustness of double calculations, in much
  * the same way that [double] values were originally intended to
  * provide robustness in calculations where data was stored in
  * float32 values.
  * 
  * Some extra precision (for longdoubles with numeric values in the range 1e-22 to 1e22)
  * is provided by the `longdouble.parse` method, for the purposes of constructing
  * accurate literal values.
  * 
  * The implmentation in this module is taken argely from  
  * Robert Munafo's implementation of quad precision doubles
  * http://mrob.com/pub/math/f161.html
  */

class longdouble implements Comparable<longdouble>{
  
  static const longdouble NAN =
      const longdouble(double.NAN, double.NAN);
  
  static const longdouble INFINITY = 
      const longdouble(double.INFINITY, double.INFINITY);
  
  static const longdouble NEGATIVE_INFINITY = 
      const longdouble(double.NEGATIVE_INFINITY, double.NEGATIVE_INFINITY);
  
  /**
   * Parse [input] as a longdouble literal.
   * 
   * A longdouble literal will match the same pattern as a double literal,
   * with an optional sign, followed by a mantissal and exponent.
   * 
   * Leading and trailing whitespace is ignored.
   */
  
  static longdouble parse(String input, [longdouble onError(String input)]) =>
      _parseLongdouble(input, onError);
  
  final double hi;
  final double lo;
  
  /**
   * Initialize a [longdouble] with the given [:hi:]
   * and [:lo:] double values.
   */
  const longdouble(double this.hi, [double this.lo = 0.0]);
  
  const longdouble.zero() : this(0.0, 0.0);
  
  /**
   * Return the value of `1.0 / this`. 
   * Since it's impossible to implement operators on double taking a left value of a [longdouble],
   * the only way to divide by a [longdouble] is to multiply by the reciprocal
   */
  longdouble get reciprocal => _longdouble_division(new longdouble(1.0), this);
  
  /**
   * Retrieve the result as a double value
   */
  double toDouble() => hi + lo;

  bool get isNaN => hi.isNaN;
  bool get isNegative => hi.isNegative || hi == 0.0 && lo.isNegative;
  bool get isInfinite => hi.isInfinite || lo.isInfinite;
  bool get isZero => hi == 0.0 && lo == 0.0;
  
  /**
   * Compares the longdouble to the num [:a:], 
   * returning a negative number if this is less than a, 
   * a positive number if this is equal to a and `0` otherwise.
   * 
   * For the purposes of comparison, a NaN value tests equal
   * to other NaN values and greater than any other value, 
   * including `Infinity`
   */
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
  
  /**
   * Compares the longdouble to the num [:a:], 
   * returning a negative number if this is less than a, 
   * a positive number if this is equal to a and `0` otherwise.
   * 
   * For the purposes of comparison, a NaN value tests equal
   * to other NaN values and greater than any other value, 
   * including `Infinity`
   */
  int compareTo(longdouble ld) {
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
  
  /**
   * The absolute value of `this`
   */
  longdouble abs() {
    if (isNaN) return this;
    if (hi < 0.0) {
      return new longdouble(-hi, -lo);
    } else if (hi > 0.0) {
      return this;
    } else if (lo < 0.0) {
      return new longdouble(-hi, -lo);
    } else {
      return this;
    }
  }
  
  int floor() => toDouble().floor();
  double floorToDouble() => toDouble().floorToDouble();
  
  int ceil() => toDouble().ceil();
  double ceilToDouble() => toDouble().ceilToDouble();
  
  /**
   * Unary negation operator
   */
  longdouble operator -() => new longdouble(-hi, -lo);
  
  /**
   * Multiply the value of `this` by the num or longdouble value [:v:].
   */
  longdouble operator *(dynamic v) {
    if (v is num) {
      if (isNaN || v.isNaN) return NAN; 
      if (isInfinite || v.isInfinite) {
        if (isNegative) {
          return v.isNegative ? INFINITY : NEGATIVE_INFINITY;
        } else {
          return v.isNegative ? NEGATIVE_INFINITY : INFINITY;
        }
      }
      var t0 = _multDoubles(hi, v.toDouble());
      var d  = _multDoubles(lo, v.toDouble());
      
      var t1 = _addDoubles(t0.lo, d.hi);
      var t2 = d.lo + t1.lo;
      
      return _normalizeThree(t0.hi, t1.hi, t2);
    } else if (v is longdouble) {
      if (isNaN || v.isNaN) return NAN; 
      if (isInfinite || v.isInfinite) {
        if (isZero || v.isZero) return NAN;
        if (isNegative) {
          return v.isNegative ? INFINITY : NEGATIVE_INFINITY;
        } else {
          return v.isNegative ? NEGATIVE_INFINITY : INFINITY;
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
      throw new ArgumentError("right multiplicand null");
    } else {
      throw new ArgumentError("right multiplicand of '*' must be a num or longdouble");
    }
  }
  
  /**
   * Add the value of `this` to the num or longdouble value [:v:].
   */
  longdouble operator +(dynamic v) {
    if (v is num) {
      if (isNaN || v.isNaN) return NAN; 
      if (isInfinite) {
        if (isNegative) {
          //-inf + inf == NaN
          if (v.isInfinite && !v.isNegative) return NAN;
          return NEGATIVE_INFINITY;
        } else {
          //inf + (-inf) == NaN
          if (v.isInfinite && v.isNegative) return NAN;
          return INFINITY;
        }
      } else if (v.isInfinite) {
        if (v.isNegative) return NEGATIVE_INFINITY;
        return INFINITY;
      }
      
      var t0 = _addDoubles(hi, v.toDouble());
      var t1 = _addDoubles(lo, t0.lo);
      
      return _normalizeThree(t0.hi, t1.hi, t1.lo);
    } else if (v is longdouble) {
      if (isNaN || v.isNaN) return NAN; 
      if (isInfinite) {
        if (isNegative) {
          //-inf + inf == NaN
          if (v.isInfinite && !v.isNegative) return NAN;
          return NEGATIVE_INFINITY;
        } else {
          //inf + (-inf) == NaN
          if (v.isInfinite && v.isNegative) return NAN;
          return INFINITY;
        }
      } else if (v.isInfinite) {
        if (isNegative) return NEGATIVE_INFINITY;
        return INFINITY;
      }
      
      var t0 = _addDoubles(hi, v.hi);
      var d  = _addDoubles(lo, v.lo);
      var t1 = _addDoubles(t0.lo, d.hi);
      double t2 = d.lo + t1.lo;
      
      return _normalizeThree(t0.hi, t1.hi, t2);
    } else if (v == null) { 
      throw new ArgumentError("null summand");
    } else {
      throw new ArgumentError("right summand must be num or longdouble");
    }
  }
  
  /**
   * Subtract the value of [:v:] from the value of `this`.
   */
  longdouble operator -(dynamic v) {
    if (v is num) {
      if (isNaN || v.isNaN) return NAN;
      if (isInfinite) {
        if (isNegative) {
          // -Inf - (-Inf)
          if (v.isInfinite && v.isNegative) return NAN; 
          return NEGATIVE_INFINITY;
        } else {
          // Inf - Inf
          if (v.isInfinite && !v.isNegative) return NAN;
          return INFINITY;
        }
      } else if (v.isInfinite) {
        return v.isNegative ? INFINITY : NEGATIVE_INFINITY;
      }
      
      final t0 = _subtractDoubles(hi, v.toDouble());
      final t1 = _subtractDoubles(lo, t0.lo);
      return _normalizeThree(t0.hi, t1.hi, t1.lo);
    } else if (v is longdouble) {
      if (isNaN || v.isNaN) return NAN;
      if (isInfinite) {
        if (isNegative) {
          // -Inf - (-Inf)
          if (v.isInfinite && v.isNegative) return NAN;
          return NEGATIVE_INFINITY;
        } else {
          // Inf - Inf
          if (v.isInfinite && !v.isNegative) return NAN; 
          return INFINITY;
        }
      } else if (v.isInfinite) {
        return v.isNegative ? INFINITY : NEGATIVE_INFINITY;
      }
      final t0 = _subtractDoubles(hi, v.hi);
      final d  = _subtractDoubles(lo, v.lo);
    
      final t1 = _addDoubles(t0.lo, d.hi);
      double t2 = d.lo + t1.lo;
      
      return _normalizeThree(t0.hi, t1.hi, t2);
    } else if (v == null) {
      throw new ArgumentError("null subtrahend");
    } else {
      throw new ArgumentError("subtrahend must be num or longdouble");
    }
  }
  
  longdouble operator /(dynamic v) {
    if (v is num) {
      if (isNaN || v.isNaN) return NAN;
      if (isInfinite) {
        if (v.isInfinite) return NAN;
        if (isNegative) {
          return v.isNegative ? INFINITY : NEGATIVE_INFINITY;
        } else {
          return v.isNegative ? NEGATIVE_INFINITY : INFINITY;
        }
      } else if (v.isInfinite) {
        return new longdouble.zero();
      } else if (v == 0.0) {
        return isNegative ? NEGATIVE_INFINITY : INFINITY;
      }
      return _longdouble_division(this, new longdouble(v.toDouble()));
    } else if (v is longdouble) {
      if (isNaN || v.isNaN) return NAN;
      if (isInfinite) {
        if (v.isInfinite) return NAN;
        if (isNegative) {
          return v.isNegative ? INFINITY : NEGATIVE_INFINITY;
        } else {
          return v.isNegative ? NEGATIVE_INFINITY : INFINITY;
        }
      } else if (v.isInfinite) {
        return new longdouble.zero();
      } else if (v == 0.0) {
        return isNegative ? NEGATIVE_INFINITY : INFINITY;
      }
      return _longdouble_division(this, v);
    } else {
      throw new ArgumentError("right operand of '/' must be num or longdouble");
    }
  }
  
  /**
   * Test whether `this` is numerically equal to [:o:].
   */
  bool operator ==(Object o) {
    if (o is num) {
      if (isZero && o == 0.0) return true;
      if (isNaN || o.isNaN) return false; 
      return compareToNum(o) == 0;
    } else if (o is longdouble) {
      
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
      (v is num && compareToNum(v) > 0)
      || (v is longdouble && compareTo(v) > 0);
  bool operator >=(dynamic v) => 
      (v is num && compareToNum(v) >= 0)
      || (v is longdouble && compareTo(v) >= 0);
  bool operator <(dynamic v) => 
      (v is num && compareToNum(v) < 0)
      || (v is longdouble && compareTo(v) < 0);
  bool operator <=(dynamic v) => 
      (v is num && compareToNum(v) <= 0)
      || (v is longdouble && compareTo(v) <= 0);
  
  int get hashCode => 17 * hi.hashCode + lo.hashCode;
  
  /**
   * A [String] representation of the double value.
   * 
   * Since bitwise operations aren't available for doubles in dart,
   * any attempt to print the double in a natural format would introduce
   * an error and produce unintuitive results.
   */
  String toString() => "longdouble($hi|$lo)";
  
}

/**
 * normalize two [double] values. 
 * [:a:] is assumed to be greater than [:b:]
 */
longdouble _normalizeTwo(double a, double b) {
  final sum = a + b;
  final err = b - (sum - a);
  return new longdouble(sum, err);
}

/**
 * normalize three double values, returning their sum
 * as a [longdouble]
 * [:a:] is assumed to be greater than [:b:]
 * and [:b:] is assumed to be greater than [:c:]
 */
longdouble _normalizeThree(double a, double b, double c) {
  var s0 = _normalizeTwo(b, c);
  var s1 = _normalizeTwo(a, s0.hi);
  double newLo;
  if (s1.lo != 0.0) {
    newLo = s1.lo + s0.lo;
  } else {
    s0 = _normalizeTwo(s1.hi, s0.lo);
    newLo = s0.lo;
  }
  return new longdouble(s1.hi, newLo);
}

//Cached constant used in split, to prevent recalculation
final _splitConst = math.pow(2, 27) + 1;

/**
 * Split the [double] value [:a:] into a new [longdouble] where 
 * the value returned has a [:hi:] value has the top `27` bits of precision
 * and the [:lo:] value has the bottom `27` bits of precision.
 */
longdouble _split(double a) {
  final y = _splitConst * a;
  final newHi = y - (y - a);
  return new longdouble(newHi, a - newHi);
}

/**
 * Multiply two doubles, returning the result as a normalized [longdouble]
 */
longdouble _multDoubles(double a, double b) {
  final newHi = a * b;
  //split both the doubles
  longdouble sa = _split(a);
  longdouble sb = _split(b);
  final newLo = 
      ((sa.hi * sb.hi - newHi) 
        + (sa.hi * sb.lo) + (sb.hi * sa.lo)) 
              + sa.lo * sb.lo;
  return new longdouble(newHi, newLo);
}

/**
 * Add two [double] values, returning the addition as a normalized [longdouble].
 */
longdouble _addDoubles(double a, double b, [double c = null]) {
  if (c == null) {
    //add_112
    final sum = a + b;
    final amtAdded = sum - a;
    final err = (a - (sum - amtAdded)) + (b - amtAdded);
    return new longdouble(sum, err);
  }
  //add_1113
  final sumTwo = _addDoubles(a, b);
  final sumThird = _addDoubles(sumTwo.hi, c);
  return new longdouble(sumThird.hi, sumTwo.lo + sumThird.lo);
}

/**
 * Subtract two [double] values, returning the difference as a normalized [longdouble]
 * //sub_112
 */
longdouble _subtractDoubles(double a, double b) {
  final diff = a - b;
  final amtSubtracted = diff - a;
  final err = (a - (diff - amtSubtracted)) - (b + amtSubtracted);
  return new longdouble(diff, err);
}

/**
 * The division algorithm begins with an approximation using the 
 * double division operation, then computes the error created and subtracts it out.
 */
longdouble _longdouble_division(longdouble a, longdouble b) {
  final initApprox = a.hi / b.hi;
  
  var result = b * initApprox;
  final s = _subtractDoubles(a.hi, result.hi);
  var slo = s.lo;
  slo -= result.lo;
  slo += a.lo;
  var newApprox = (s.hi + slo) / b.hi;
  
  return _normalizeTwo(initApprox, newApprox);
}