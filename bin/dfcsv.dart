// Copyright (c) 2015, Tsuguya Toma. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library dfcsv;

import 'dart:io';
import 'dart:collection';
import 'package:args/args.dart';
import 'dart:async';

Directory rootDir;

main(List<String> args) {

  var parser = new ArgParser();
  parser.addOption('in',    abbr: 'i');
  parser.addOption('out',   abbr: 'o');
  parser.addOption('group', abbr: 'g');

  var results = parser.parse(args);

  if(results['in'] != null) {
    rootDir = new Directory(results['in']);
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

  if(results['group'] == null) {
    csvResult = searchAll();
  } else {

    List<FileSystemEntity> targetFs = new List();
    results['group'].split(',').forEach((dt) {
      targetFs.addAll(parseDirectory(dt));
    });

    csvResult = searchGroups(targetFs);
  }

  csvResult.then((String csv) {

    File exportFile;

    if(results['out'] == null) {
      exportFile = new File(rootDir.path + '/export.csv');
    } else if(results['out'][0] == '/' || results['out'][0] == '~') {
      exportFile = new File(results['out']);
    } else {
      exportFile = new File(rootDir.path + '/' + results['out']);
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
  String filename = pathList.last;
  pathList.removeLast();

  String filePath = pathList.join('/');
  if(filePath == '') filePath = '/';

  return filePath + ',' + filename;
}

/**
 * パスの展開
 * *指定の部分を調べるのが目的
 */
List<FileSystemEntity> parseDirectory(String dir) {
  List<FileSystemEntity> returnList = new List();

  Queue parseDir = new Queue.from(dir.split('/'));

  String current = rootDir.path;
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
        if(entity is Directory) returnList.addAll(parseDirectory(entity.path + '/' + parseDir.join('/')));
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