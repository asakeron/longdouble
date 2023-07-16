library test_longdouble;

import 'package:test/test.dart';
import 'package:longdouble/longdouble.dart';

void main() {
  testLongdouble();
  testLongdoubleParse();
}

void testLongdouble() {
  final ld0 = LongDouble(0.0);
  final ld1 = LongDouble(1.0);
  final ldneg1 = LongDouble(-1.0);
  final ld2 = LongDouble(2.0);

  final nan = LongDouble.nan;
  final inf = LongDouble.infinity;
  final negInf = LongDouble.negativeInfinity;

  group("operations", () {
    group("addition", () {
      test("1.0 + (num) 0.0", () => expect(ld1 + 0.0, equals(ld1)));
      test("0.0 + 0.0", () => expect(ld0 + ld0, equals(ld0)));
      test("1.0 + 1.0", () => expect(ld1 + ld1, equals(ld2)));
      test("1.0 + inf", () => expect(ld1 + inf, equals(inf)));
      test("inf + 1.0", () => expect(inf + 1.0, equals(inf)));
      test("-inf + inf", () => expect((inf + negInf).isNaN, isTrue));
    });
    group("subtraction", () {
      test("0.0 - 0.0", () => expect(ld0 - ld0, equals(ld0)));
      test("negation", () => expect(-ld1, equals(ldneg1)));
      test("1.0 - 1.0", () => expect(ld1 - ld1, equals(ld0)));

      test("1.0 - inf", () => expect(ld1 - inf, equals(negInf)));
      test("inf - 1.0", () => expect(inf - 1.0, equals(inf)));
      test("inf - inf", () => expect((inf - inf).isNaN, isTrue));
    });
    group("multiplication", () {
      test("0.0 * 1.0", () => expect(ld0 * ld1, equals(ld0)));
      test("1.0 * 1.0", () => expect(ld1 * ld1, equals(ld1)));
      final ld4 = LongDouble(4.0);
      test("4.0 * 1.0", () => expect(ld4 * ld1, equals(ld4)));
      test("4.0 * -1.0", () => expect(ld4 * ldneg1, equals(-ld4)));
      test("4.0 * 4.0", () => expect(ld4 * ld4, equals(LongDouble(16.0))));

      test("1.0 * inf", () => expect(ld1 * inf, equals(inf)));
      test("inf * 1.0", () => expect(inf * 1.0, equals(inf)));
      test("inf * inf", () => expect((inf * inf), equals(inf)));

      test(
          "100 * 12.34",
          () => expect(
              (LongDouble(100.0) * LongDouble(12.34)).toDouble(), 1234.0));
      test("0.34 * 10", () {
        expect((LongDouble.parse("0.34") * 10.0).toDouble(),
            equals(LongDouble(3.4)));
      });
    });
    group("division", () {
      test("2 / 1", () => expect(ld2 / ld1, equals(ld2)));
      test("1 / 2", () => expect(ld1 / 2, equals(LongDouble(0.5))));
      test("-1 / 0", () => expect(ldneg1 / ld0, equals(negInf)));
      test("1 / 0", () => expect(ld1 / ld0, equals(inf)));
      test("1 / inf = 0", () => expect(ld1 / inf, equals(ld0)));
    });

    group("comparison", () {
      test("0 < 1", () => expect(ld0 < ld1, isTrue));
      test("NaN > inf", () => expect(nan > inf, isTrue));
      test("1 < inf", () => expect(ld1 < inf, isTrue));
      test("1 <= 1", () => expect(ld1 <= ld1, isTrue));
      test("1 == (num) 1", () => expect(ld1 == LongDouble(1.0), isTrue));
    });
  });
}

void testLongdoubleParse() {
  group("parse", () {
    test(
        "-Infinity",
        () => expect(
            LongDouble.parse("-Infinity"), equals(-LongDouble.infinity)));
    test("NaN", () => expect(LongDouble.parse("-NaN").isNaN, isTrue));
    test("'0.34'", () {
      expect(LongDouble.parse("0.34"),
          equals(LongDouble(0.34, -2.4424906541753444e-17)));
    });
    test("'1234'", () {
      expect(LongDouble.parse("1234"), equals(LongDouble(1234.0)));
    });
    test("'-1234'", () {
      expect(LongDouble.parse("-1234"), equals(LongDouble(-1234.0)));
    });
    test("'12.34'", () {
      expect(LongDouble.parse("12.34").toDouble(), equals(12.34));
    });
    test("'1.234e-14", () {
      expect(LongDouble.parse("1.234e-14"),
          equals(LongDouble(1.234e-14, 6.425030031206563e-31)));
    });
  });
}
