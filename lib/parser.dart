library dfcsv.parser;

import 'dart:io';
import 'dart:collection';
import 'dart:async';
import 'package:quiver/pattern.dart';
import 'package:path/path.dart' as path;

class Parser {

  final Directory _rootDir;
  final Iterable _ignores;

  Parser(this._rootDir, List<String> ignores)
    : _ignores = ignores.map((ignore) => {
      'glob': new Glob(ignore[0] != '!' ? ignore : ignore.substring(1)),
      'turning': ignore[0] != '!'
    });

    Future<String> search(List<String> groups) =>
    groups.length == 0 ? _searchAll() : _searchGroups(groups);

    /**
     * groupオプションなしの場合
     */
    Future<String> _searchAll() =>
    _searchDirectory(_rootDir).then((String csv) => csv.replaceAll(new RegExp(r'\n$'), ''));

    /**
     * groupオプション付けた場合
     */
    Future<String> _searchGroups(List<String> groups) {

      List<FileSystemEntity> targetFs = new List();

      groups.forEach((String p) {
        targetFs.addAll(_parseDirectory(p.replaceFirst(new RegExp(path.separator + r'$'), ''), _rootDir.path));
      });

      return Future.wait(targetFs.map((group) {
        if(group is File) {
          String fileSplit = _pathSplitter(group.path);
          return new Future.value(fileSplit + '\n');
        }
        return _searchDirectory(group);
      })).then((List<String> result) => result.join(',\n'));
    }

  /**
   * ファイル探索
   */
  Future<String> _searchDirectory(Directory targetDir) {

    return targetDir.list(recursive: true, followLinks: false).map((entity) {
      if(entity is Directory || _checkIgnore(entity)) return '';

      String consolidated = _pathSplitter(entity.path);
      return consolidated + '\n';

    }).join();
  }

  /**
   * ignoreで指定されたファイルを取り除く
   */
  bool _checkIgnore(FileSystemEntity entity) {
    var p = entity.path.replaceAll(_rootDir.path, '');
    var result = false;

    _ignores.forEach((ignore) {
      if(ignore['glob'].hasMatch(p)) {
        result = ignore['turning'];
      }
    });

    return result;
  }

  /**
   * rootDirより上の階層の削除と
   * パスとファイル名の分離(カンマ区切り)を行う
   */
  String _pathSplitter(String p) {

    List<String> pathList = p.replaceFirst(_rootDir.path, '').split(path.separator);
    String filename = pathList.removeLast();

    String filePath = pathList.join('/');
    if(filePath == '') filePath = '/';

    // csvで表示がバグらないようににパースする
    return filePath.replaceAll('"', '""').replaceAll(',', '","') + ',' + filename.replaceAll('"', '""').replaceAll(',', '","');
  }

  /**
   * パスの展開
   * *指定の部分を調べるのが目的
   */
  List<FileSystemEntity> _parseDirectory(String dir, [String current = '']) {
    List<FileSystemEntity> returnList = new List();

    Queue parseDir = new Queue.from(dir.split(path.separator));

    if(parseDir.first == '') parseDir.removeFirst();

    while(parseDir.length != 0) {
      String routeDir = parseDir.removeFirst();
      if(routeDir != '*') {
        current += path.separator + routeDir;
        continue;
      }

      Directory searchDir = new Directory(current);
      if(!searchDir.existsSync()) return returnList;

      searchDir.listSync().forEach((entity) {
        if(parseDir.length != 0) {
          // 下位のパス指定がある場合はファイルはリストに含めない
          if(entity is Directory) {
            returnList.addAll(_parseDirectory(entity.path + path.separator + parseDir.join(path.separator)));
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

}