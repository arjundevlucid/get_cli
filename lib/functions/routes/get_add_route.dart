import 'dart:convert';
import 'dart:io';

import 'package:get_cli/core/internationalization.dart';
import 'package:get_cli/core/locales.g.dart';
import 'package:recase/recase.dart';

import 'package:get_cli/common/utils/logger/LogUtils.dart';
import 'package:get_cli/functions/create/create_single_file.dart';
import 'package:get_cli/functions/find_file/find_file_by_name.dart';
import 'package:get_cli/functions/formatter_dart_file/frommatter_dart_file.dart';
import 'package:get_cli/functions/routes/get_app_pages.dart';
import 'package:get_cli/functions/routes/get_support_children.dart';
import 'package:get_cli/samples/impl/get_route.dart';

Future<void> addRoute(String nameRoute, String path) async {
  File routesFile = findFileByName('app_routes.dart');
  List<String> lines = [];

  if (routesFile.path.isEmpty) {
    await RouteSample().create(skipFormatter: true);
    routesFile = File(RouteSample().path);
    lines = routesFile.readAsLinesSync();
  } else {
    String content = formatterDartFile(routesFile.readAsStringSync());
    lines = LineSplitter.split(content).toList();
  }
  List<String> pathSplit = path.split('/');
  pathSplit.removeLast();
  pathSplit.removeWhere((element) => element == 'app' || element == 'modules');

  pathSplit.add(nameRoute);
  for (var i = 0; i < pathSplit.length; i++) {
    pathSplit[i] =
        pathSplit[i].snakeCase.snakeCase.toLowerCase().replaceAll('_', '-');
  }
  String route = pathSplit.join('/');

  int indexEndRoutes = lines.indexWhere((element) => element.startsWith('}'));

  String line =
      "static const ${nameRoute.snakeCase.toUpperCase()} = '/$route';";

  if (supportChildrenRoutes) {
    line =
        'static const ${nameRoute.snakeCase.toUpperCase()} = ${_pathsToRoute(pathSplit)};';
    int indexEndPaths =
        lines.lastIndexWhere((element) => element.startsWith('}'));

    String linePath =
        "static const ${nameRoute.snakeCase.toUpperCase()} = '/${pathSplit.last}';";
    lines.insert(indexEndPaths, linePath);
  }

  if (lines.contains(line)) {
    return;
  }

  lines.insert(indexEndRoutes, line);

  await writeFile(routesFile.path, lines.join('\n'),
      overwrite: true, logger: false);
  LogService.success(
      Translation(LocaleKeys.sucess_route_created).trArgs([nameRoute]));

  await addAppPage(nameRoute, path);
}

String _pathsToRoute(List<String> pathSplit) {
  StringBuffer sb = StringBuffer();
  pathSplit.forEach((element) {
    sb.write('_Paths.');
    sb.write(element.snakeCase.toUpperCase());
    if (element != pathSplit.last) {
      sb.write(' + ');
    }
  });
  return sb.toString();
}
