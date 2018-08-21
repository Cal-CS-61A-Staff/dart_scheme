import 'dart:io';

import 'package:cs61a_scheme/builder.dart';
import 'package:grinder/grinder.dart';
import 'package:dart_style/dart_style.dart';

const libraries = [
  'core/standard_library',
  'extra/extra_library',
  'extra/logic_library',
  'web/web_library',
  'web/turtle_library'
];

main(args) => grind(args);

@DefaultTask('Builds helpers for Scheme libraries.')
build() async {
  for (var lib in libraries) {
    await buildLibrary(lib);
  }
  await buildDocs();
}

@Task('Check that generated code is in sync.')
check() async {
  bool good = true;
  for (var lib in libraries) {
    good = await checkBuilt(lib) && good;
  }
  good = await checkDocs();
  if (!good) {
    print('Run `pub run grinder` to keep generated code in sync.');
    exit(1);
  }
}

buildDocs() async {
  String source = await File("lib/src/core/documentation.md").readAsString();
  String code = generateDocumentation(source);
  await File('lib/src/core/documentation.g.dart')
      .writeAsString(DartFormatter().format(code));
}

buildLibrary(String name) async {
  String code = await generateCode(name);
  var output = File("lib/src/$name.g.dart");
  if (!output.existsSync()) await output.create(recursive: true);
  await output.writeAsString(code);
}

generateCode(String name) async {
  String source = await File("lib/src/$name.dart").readAsString();
  String mixin = generateImportMixin(source);
  String dottedName = name.replaceAll("/", ".");
  String code = "part of cs61a_scheme.$dottedName;\n\n$mixin";
  return DartFormatter().format(code);
}

checkBuilt(String name) async {
  String code = await generateCode(name);
  var output = File("lib/src/$name.g.dart");
  String existing = await output.readAsString();
  if (code != existing) {
    print('Generated code for $name out of sync!');
    return false;
  }
  return true;
}

checkDocs() async {
  String source = await File("lib/src/core/documentation.md").readAsString();
  String code = generateDocumentation(source);
  String exist = await File('lib/src/core/documentation.g.dart').readAsString();
  if (code != exist) {
    print('Generated documentation is out of sync!');
    return false;
  }
  return true;
}
