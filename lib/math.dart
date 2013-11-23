/**
 * mathematical operations on [longdouble] objects.
 */
//    This file is part of longdouble.
//
//    Copyright (C) 2013 Thomas Stephenson <ovangle@gmail.com>
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

library longdouble.math;

import 'dart:math' as math;
import 'package:longdouble/longdouble.dart';

const longdouble PI = 
    const longdouble(math.PI, 1.224646799353209e-16);

const longdouble E =
    const longdouble(math.E, 1.445646891729250158e-16);

longdouble min(longdouble dd1, longdouble dd2) =>
    dd1 >= dd2 ? dd2 : dd1;

longdouble max(longdouble dd1, longdouble dd2) =>
    dd1 >= dd2 ? dd1 : dd2;

/**
 * Raises a [longdouble] to a given integral [:exponent:].
 * In dart2js, where int is not yet implemneted, the value used will be the floor of 
 * the exponent value
 */
longdouble intpow(longdouble d, int exponent) {
  exponent = exponent.floor();
  longdouble result = new longdouble(1.0);
  var takeReciprocal = (exponent < 0);
  exponent = exponent.abs();
  var pow2 = d;
  while (exponent > 0) {
    //If the exponent is odd
    if (exponent & 1 == 1) {
      result = result * pow2;
    }
    exponent >>= 1;
    pow2 = pow2 * pow2;
  }
  return takeReciprocal ? result.reciprocal : result;
}

longdouble pow(longdouble d, num exponent) {
  throw 'NotImplemented';
}

longdouble sqrt(longdouble d) {
  throw 'NotImplemented';
}

longdouble sin(longdouble d) {
  throw 'NotImplemented';
}

longdouble cos(longdouble d) {
  throw 'NotImplemented';
}

longdouble tan(longdouble d) {
  throw 'NotImplemented';
}

longdouble sinh(longdouble d) {
  throw 'NotImplemented';
}

longdouble cosh(longdouble d) {
  throw 'NotImplemented';
}

longdouble tanh(longdouble d) {
  throw 'NotImplemented';
}