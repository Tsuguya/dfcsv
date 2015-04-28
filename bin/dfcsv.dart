// Copyright (c) 2015, Tsuguya Toma. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dfcsv;

import 'dart:io';
import 'package:dfcsv/parser.dart';
import 'package:args/args.dart';

const String APP_VERSION = '0.1.3';

main(List<String> args) {

  var parser = new ArgParser()
    ..addOption('in',    abbr: 'i', defaultsTo: Directory.current.path)
    ..addOption('out',   abbr: 'o', defaultsTo: Directory.current.path + '/export.csv')
    ..addOption('group', abbr: 'g', allowMultiple: true)
    ..addOption('ignore', allowMultiple: true)
    ..addFlag('version', abbr: 'v');

  var argResults = parser.parse(args);

  if(argResults['version']) {
    return print('dfcsv version: ${APP_VERSION}');
  }

  var _root =  argResults['in'][0] == '/' ? '' : Directory.current.path + '/';

  Directory rootDir = new Directory(_root + argResults['in']);

  var ignoreHome = new File(Platform.environment['HOME'] + '/.dfcsvignore');
  var ignoreProject = new File(rootDir.path + '/.dfcsvignore');

  List<String> ignores = new List();

  if(ignoreHome.existsSync()) {
    ignores.addAll(ignoreHome.readAsLinesSync());
  }

  if(ignoreProject.existsSync()) {
    ignores.addAll(ignoreProject.readAsLinesSync());
  }

  ignores
    ..addAll(argResults['ignore'])
    ..removeWhere((ignore) => ignore[0] == '#');

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