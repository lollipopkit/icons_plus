#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

final namesFile = File('lib/src/names.dart');
final namesFileStream = namesFile.openWrite(mode: FileMode.append);

void main() async {
  if (await namesFile.exists()) {
    await namesFile.delete();
  }

  final files = await Directory('lib/src').list().toList();
  for (final file in files) {
    if (file is File) {
      namesFileStream.write("import '${file.path.split('/').last}';\n");
    }
  }
  namesFileStream.write('\n\n');
  await namesFileStream.flush();

  for (final file in files) {
    if (file is File) {
      await _doParse(file);
    }
  }
  await namesFileStream.close();
}

final classNameReg = RegExp(r'class (\w+) {');
final constNameReg = RegExp(r'static const (\w+) = ');

Future<void> _doParse(File f) async {
  final lines = await f.readAsLines();
  final names = <String>{};
  String? className;
  for (final line in lines) {
    if (className == null) {
      final classNameMatch = classNameReg.firstMatch(line);
      if (classNameMatch != null) {
        final matchStr = classNameMatch.group(1);
        if (matchStr != null) {
          className = matchStr;
        }
      }
      continue;
    }

    if (line.trimLeft().startsWith('//')) continue;

    final constNameMatch = constNameReg.firstMatch(line);
    if (constNameMatch != null) {
      final matchStr = constNameMatch.group(1);
      if (matchStr != null) {
        names.add(matchStr);
      }
    }
  }

  if (className == null) {
    print('No class name found in ${f.path}');
    return;
  }
  if (names.isEmpty) {
    print('No names found in ${f.path}');
    return;
  }

  final lowerFirst = className[0].toLowerCase() + className.substring(1);
  namesFileStream.write('const ${lowerFirst}Names = {');
  for (final name in names) {
    namesFileStream.write('\n "$name": $className.$name,');
  }
  namesFileStream.write('};\n\n');
  await namesFileStream.flush();
  print('Updated ${f.path}');
}
