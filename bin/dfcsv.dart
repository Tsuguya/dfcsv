// Copyright (c) 2015, Tsuguya Toma. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dfcsv;

import 'dart:io';
import 'dart:collection';
import 'dart:async';
import 'package:args/args.dart';

Directory rootDir;

main(List<String> args) {

  var parser = new ArgParser();
  parser.addOption('in',    abbr: 'i');
  parser.addOption('out',   abbr: 'o');
  parser.addOption('group', abbr: 'g');
  parser.addOption('gs');

  var argResults = parser.parse(args);

  if(argResults['in'] != null) {
    rootDir = new Directory(argResults['in']);
  } else {
    rootDir = Directory.current;
  }

  print(rootDir.path);
  print('');

  if(!rootDir.existsSync()) {
    print('No such Directory!');
    exit(1);
  }

  Future<String> csvResult;

  if(argResults['group'] == null) {
    csvResult = searchAll();
  } else {

    String gs = argResults['gs'] == null ? ',' : argResults['gs'];

    List<FileSystemEntity> targetFs = new List();
    argResults['group'].split(gs).forEach((dt) {
      targetFs.addAll(parseDirectory(dt, rootDir.path));
    });
    print(targetFs);

    csvResult = searchGroups(targetFs);
  }

  csvResult.then((String csv) {

    File exportFile;

    if(argResults['out'] == null) {
      exportFile = new File(rootDir.path + '/export.csv');
    } else {
      exportFile = new File(argResults['out']);
    }
    exportFile.writeAsStringSync(csv);
    print('');
    print('complete!');
  });

}

/**
 * groupオプションなしの場合
 */
Future<String> searchAll() =>
  search(rootDir).then((String csv) => csv.replaceAll(new RegExp(r'\n$'), ''));

/**
 * groupオプション付けた場合
 */
Future<String> searchGroups(List<FileSystemEntity> groups) {

  List<Future<String>> waitList = new List();
  groups.forEach((group) {
    if(group is File) {
      String fileSplit = pathSplitter(group.path);
      print('* File: ' + fileSplit);
      waitList.add(new Future.value(fileSplit + '\n'));
      return;
    }
    waitList.add(search(group));

  });

  return Future.wait(waitList).then((List<String> result) => result.join(',\n,\n'));
}

/**
 * ファイル探索
 */
Future<String> search(Directory targetDir) {
  print('* Search: ' + targetDir.path);

  return targetDir.list(recursive: true, followLinks: false).map((entity) {
    if(entity is Directory) return '';

    String consolidated = pathSplitter(entity.path);
    print(consolidated);
    return consolidated + '\n';

  }).join();
}

/**
 * rootDirより上の階層の削除と
 * パスとファイル名の分離(カンマ区切り)を行う
 */
String pathSplitter(String path) {

  List<String> pathList = path.replaceFirst(rootDir.path, '').split('/');
  String filename = pathList.removeLast();

  String filePath = pathList.join('/');
  if(filePath == '') filePath = '/';

  // csvで表示がバグらないためにパースする
  return filePath.replaceAll('"', '""').replaceAll(',', '","') + ',' + filename.replaceAll('"', '""').replaceAll(',', '","');
}

/**
 * パスの展開
 * *指定の部分を調べるのが目的
 * TODO: Futureに変更
 */
List<FileSystemEntity> parseDirectory(String dir, [String current = '']) {
  List<FileSystemEntity> returnList = new List();

  Queue parseDir = new Queue.from(dir.split('/'));

  if(parseDir.first == '') parseDir.removeFirst();

  while(parseDir.length != 0) {
    String routeDir = parseDir.removeFirst();
    if(routeDir != '*') {
      current += '/' + routeDir;
      continue;
    }

    Directory searchDir = new Directory(current);
    if(!searchDir.existsSync()) return returnList;

    searchDir.listSync().forEach((entity) {
      if(parseDir.length != 0) {
         // 下位のパス指定がある場合はファイルはリストに含めない
        if(entity is Directory) {
          print('下位パス探索: ' + entity.path + '/' + parseDir.join('/'));
          returnList.addAll(parseDirectory(entity.path + '/' + parseDir.join('/')));
        }
        return;
      }
      returnList.add(entity);
    });
    break;
  }

  if(returnList.length == 0) {
    Directory currentDir = new Directory(current);
    if(currentDir.existsSync()) returnList.add(currentDir);
  }

  return returnList;
}