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
  parser.addOption('ignore', allowMultiple: true);

  var argResults = parser.parse(args);

  var _root =  argResults['in'][0] == '/' ? '' : Directory.current.path + '/';

  Directory rootDir = new Directory(_root + argResults['in']);

  var ignoreFile = new File(Platform.environment['HOME'] + '/.dfcsvignore');

  List<String> ignores;

  if(ignoreFile.existsSync()) {
    ignores = ignoreFile.readAsLinesSync();
    ignores.addAll(argResults['ignore']);
  } else {
    ignores = argResults['ignore'];
  }

  print(ignores);

  print(rootDir.path);
  print('');

  if(!rootDir.existsSync()) {
    print('No such Directory!');
    exit(1);
  }

  Parser csvParser = new Parser(rootDir, ignores);

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