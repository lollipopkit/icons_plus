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

  final classNames = <String>{};
  for (final file in files) {
    if (file is File) {
      final className = await _doParse(file);
      if (className != null) {
        classNames.add(className);
      }
    }
  }

  namesFileStream.write('\n\nconst packNames = {');
  for (final className in classNames) {
    // skip these two (they are not IconData)
    if (className == 'Flags' || className == 'Brands') continue; 
    final classNameLower = className.lowerFirst;
    namesFileStream.write('\n "$classNameLower": ${classNameLower}Names,');
  }
  namesFileStream.write('\n};\n');
  await namesFileStream.close();
}

final classNameReg = RegExp(r'class (\w+) {');
final constNameReg = RegExp(r'static const (\w+) = ');

Future<String?> _doParse(File f) async {
  final lines = await f.readAsLines();
  final names = <String>{};
  String? className;
  for (final line in lines) {
    if (line.trimLeft().startsWith('//')) continue;

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
    return null;
  }
  if (names.isEmpty) {
    print('No names found in ${f.path}');
    return null;
  }

  namesFileStream.write('const ${className.lowerFirst}Names = {');
  for (final name in names) {
    namesFileStream.write('\n "$name": $className.$name,');
  }
  namesFileStream.write('\n};\n');
  await namesFileStream.flush();
  print('Updated ${f.path}');
  return className;
}

extension StringX on String {
  String get lowerFirst => this[0].toLowerCase() + substring(1);
}
