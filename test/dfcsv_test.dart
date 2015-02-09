// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dfcsv_test;

import 'dart:io';
import '../lib/parser.dart';
import 'package:unittest/unittest.dart';

void main() => defineTests();

void defineTests() {

  var parser = new Parser(new Directory(Directory.current.path + '/../sample'));

  // TODO:CSV形式になっているかチェックする必要がある

  group('No Select.     ', () {

    var case1 = parser.search([]);

    test('range', () {
      var regExp = new RegExp(r'(\/common\/a.*\n)+(\/common\/b.*\n)+(\/common\/c.*\n)+(\/common\/d.*\n)');
      return case1.then((result) {
        expect(result.contains(regExp), true);
      });
    });

    test('contain test directory.', () =>
      case1.then((result) {
        expect(result.contains('test.txt'), true);
      })
    );

  });

  group('Select One.    ', () {

    var case2 = parser.search(['common/*/*']);

    test('range', () {
      var regExp = new RegExp(r'\n,\n(\/common\/a\/a\-2.*\n)+,\n');
      return case2.then((result) => expect(result.contains(regExp), true));
    });

    test('not contain test directory.', () =>
      case2.then((result) {
        expect(result.contains('test.txt'), false);
      })
    );

  });

  group('Multi Select.  ', () {

    var case3 = parser.search(['common/*/*', 'test']);

    test('range', () {
      var regExp1 = new RegExp(r'\n,\n(\/common\/a\/a\-2.*\n)+,\n');
      var regExp2 = new RegExp(r'\n,\n(\/test.*\n)');

      return case3.then((result) => expect(result.contains(regExp1) && result.contains(regExp2), true));
    });

    test('contain test directory.', () =>
      case3.then((result) {
        expect(result.contains('test.txt'), true);
      })
    );
  });
}
