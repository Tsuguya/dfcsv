// Copyright (c) 2015, Tsuguya Toma. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dfcsv;

import 'dart:io';
import 'package:dfcsv/parser.dart';
import 'package:args/args.dart';

main(List<String> args) {

  var parser = new ArgParser();
  parser.addOption('in',    abbr: 'i', defaultsTo: Directory.current.path);
  parser.addOption('out',   abbr: 'o', defaultsTo: Directory.current.path + '/export.csv');
  parser.addOption('group', abbr: 'g', allowMultiple: true);

  var argResults = parser.parse(args);

  Directory rootDir = new Directory(argResults['in']);

  print(rootDir.path);
  print('');

  if(!rootDir.existsSync()) {
    print('No such Directory!');
    exit(1);
  }

  Parser csvParser = new Parser(rootDir);

  csvParser.search(argResults['group']).then((String csv) {

    File exportFile = new File(argResults['out']);
    print('');
    exportFile.writeAsString(csv)
    .catchError((err) {
      print(err);
      print('break.');
      exit(1);
    })
    .then((t) {
      print('complete!');
    });
  });

}