/// mathematical operations on [LongDouble] objects.
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

const LongDouble pi = LongDouble(math.pi, 1.224646799353209e-16);

const LongDouble e = LongDouble(math.e, 1.445646891729250158e-16);

LongDouble min(LongDouble dd1, LongDouble dd2) => dd1 >= dd2 ? dd2 : dd1;

LongDouble max(LongDouble dd1, LongDouble dd2) => dd1 >= dd2 ? dd1 : dd2;

/// Raises a [LongDouble] to a given integral [:exponent:].
/// In dart2js, where int is not yet implemneted, the value used will be the floor of
/// the exponent value
LongDouble intpow(LongDouble d, int exponent) {
  exponent = exponent.floor();
  LongDouble result = LongDouble(1.0);
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

LongDouble pow(LongDouble d, num exponent) {
  throw 'NotImplemented';
}

LongDouble sqrt(LongDouble d) {
  throw 'NotImplemented';
}

LongDouble sin(LongDouble d) {
  throw 'NotImplemented';
}

LongDouble cos(LongDouble d) {
  throw 'NotImplemented';
}

LongDouble tan(LongDouble d) {
  throw 'NotImplemented';
}

LongDouble sinh(LongDouble d) {
  throw 'NotImplemented';
}

LongDouble cosh(LongDouble d) {
  throw 'NotImplemented';
}

LongDouble tanh(LongDouble d) {
  throw 'NotImplemented';
}
