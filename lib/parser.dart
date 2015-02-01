library dfcsv.parser;

import 'dart:io';
import 'dart:collection';
import 'dart:async';

class Parser {

  Directory rootDir;

  Parser(this.rootDir);

  Future<String> search(List<String> groups) =>
    groups.length == 0 ? searchAll() : searchGroups(groups);

  /**
   * groupオプションなしの場合
   */
  Future<String> searchAll() =>
    searchDirectory(rootDir).then((String csv) => csv.replaceAll(new RegExp(r'\n$'), ''));

  /**
   * groupオプション付けた場合
   */
  Future<String> searchGroups(List<String> groups) {

    List<FileSystemEntity> targetFs = new List();

    groups.forEach((String path) =>
      targetFs.addAll(parseDirectory(path.replaceFirst(new RegExp(r'\/$'), ''), rootDir.path)));

    List<Future<String>> waitList = new List();

    targetFs.forEach((group) {
      if(group is File) {
        String fileSplit = pathSplitter(group.path);
        print('* File: ' + fileSplit);
        waitList.add(new Future.value(fileSplit + '\n'));
        return;
      }
      waitList.add(searchDirectory(group));

    });

    return Future.wait(waitList).then((List<String> result) => result.join(',\n,\n'));
  }

  /**
   * ファイル探索
   */
  Future<String> searchDirectory(Directory targetDir) {
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

}