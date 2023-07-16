library test_longdouble;

import 'package:test/test.dart';
import 'package:longdouble/longdouble.dart';

void main() {
  testLongdouble();
  testLongdoubleParse();
}

void testLongdouble() {

  final ld0 = new longdouble(0.0);
  final ld1 = new longdouble(1.0);
  final ldneg1 = new longdouble(-1.0);
  final ld2 = new longdouble(2.0);
  
  final nan = longdouble.nan;
  final inf = longdouble.infinity;
  final neg_inf = longdouble.negativeInfinity;
  
  
  
  group("operations", () {
    group("addition", () {
      test("1.0 + (num) 0.0", () => expect(ld1 + 0.0, equals(ld1)));
      test("0.0 + 0.0", () => expect(ld0 + ld0, equals(ld0)));
      test("1.0 + 1.0", () => expect(ld1 + ld1, equals(ld2)));
      test("1.0 + inf", () => expect(ld1 + inf, equals(inf)));
      test("inf + 1.0", () => expect(inf + 1.0, equals(inf)));
      test("-inf + inf", () => expect((inf + neg_inf).isNaN, isTrue));
    });
    group("subtraction", () {
      test("0.0 - 0.0", () => expect(ld0 - ld0, equals(ld0)));
      test("negation", () => expect(-ld1, equals(ldneg1)));
      test("1.0 - 1.0", () => expect(ld1 - ld1, equals(ld0)));
      
      test("1.0 - inf", () => expect(ld1 - inf, equals(neg_inf)));
      test("inf - 1.0", () => expect(inf - 1.0, equals(inf)));
      test("inf - inf", () => expect((inf - inf).isNaN, isTrue));
    });
    group("multiplication", () {
      test("0.0 * 1.0", () => expect(ld0 * ld1, equals(ld0)));
      test("1.0 * 1.0", () => expect(ld1 * ld1, equals(ld1)));
      final ld4 = new longdouble(4.0);
      test("4.0 * 1.0", () => expect(ld4 * ld1, equals(ld4)));
      test("4.0 * -1.0", () => expect(ld4 * ldneg1, equals(-ld4)));
      test("4.0 * 4.0", () => expect(ld4 * ld4, equals(new longdouble(16.0))));
      

      test("1.0 * inf", () => expect(ld1 * inf, equals(inf)));
      test("inf * 1.0", () => expect(inf * 1.0, equals(inf)));
      test("inf * inf", () => expect((inf * inf), equals(inf)));
      
      test("100 * 12.34", () => expect((new longdouble(100.0) * new longdouble(12.34)).toDouble(), 1234.0));
      test("0.34 * 10", () {
        expect((longdouble.parse("0.34") * 10.0).toDouble(), equals(new longdouble(3.4)));
      });
    });
    group("division", () {
      test("2 / 1", () => expect(ld2 / ld1, equals(ld2)));
      test("1 / 2", () => expect(ld1 / 2, equals(new longdouble(0.5))));
      test("-1 / 0", () => expect(ldneg1 / ld0, equals(neg_inf)));
      test("1 / 0", () => expect(ld1 / ld0, equals(inf)));
      test("1 / inf = 0", () => expect(ld1 / inf, equals(ld0)));
    });
    
    group("comparison", () {
      test("0 < 1", 
          () => expect(ld0 < ld1, isTrue));
      test("NaN > inf", () => expect(nan > inf, isTrue));
      test("1 < inf", () => expect(ld1 < inf, isTrue));
      test("1 <= 1", () => expect(ld1 <= ld1, isTrue));
      test("1 == (num) 1", () => expect(ld1 == 1.0, isTrue));
    });
  });
}

void testLongdoubleParse() {
  group("parse", () {
    test("-Infinity", 
        () => expect(longdouble.parse("-Infinity"), equals(-longdouble.infinity)));
    test("NaN", () => expect(longdouble.parse("-NaN").isNaN, isTrue));
    test("\'0.34\'", () {
      expect(longdouble.parse("0.34"), equals(new longdouble(0.34, -2.4424906541753444e-17)));
    });
    test("\'1234\'", () {
      expect(longdouble.parse("1234"), equals(new longdouble(1234.0)));
    });
    test("\'-1234\'", () {
      expect(longdouble.parse("-1234"), equals(new longdouble(-1234.0)));
    });
    test("\'12.34\'", () {
      expect(longdouble.parse("12.34").toDouble(), equals(12.34));
    });
    test("\'1.234e-14", () {
      expect(longdouble.parse("1.234e-14"), equals(new longdouble(1.234e-14, 6.425030031206563e-31)));
    });
  });
}