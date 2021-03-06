import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'route_annotation.dart';

String _allBody = "";
Set<String> _allImport = {};

/// page generator
class _PageGenerator extends GeneratorForAnnotation<RoutePage> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    var args = "()";
    bool needArgs = false;
    if (element is ClassElement) {
      ConstructorElement? constructor;
      try {
        constructor = element.constructors
            .where((element) => element.isDefaultConstructor)
            .first;
      } catch (e) {
        try {
          constructor = element.constructors.first;
        } catch (e) {}
      }
      args = "(";
      constructor?.parameters.forEach((element) {
        if (element.isNamed) {
          args +=
              '${element.name}:_format(args["${element.name}"],${element.type}),';
        } else {
          args += '_format(args["${element.name}"],${element.type}),';
        }
      });
      args += ")";
      needArgs = args.length > 2;
    }
    RegExp rule = RegExp(r"[A-Z]");
    var key = element.name
        ?.replaceAllMapped(rule, (Match m) => "_${m[0]?.toLowerCase()}");
    key = key?.replaceFirst("_", "");
    var argsIntro = "";
    if (needArgs) {
      argsIntro = """
   Map<String,dynamic> args = {};
   Map<String,dynamic>? from = ModalRoute.of(context)?.settings.arguments as Map<String,dynamic>?;
   if (from != null){
    args = from;
   }""";
    }
    _allBody += """ 
"$key": (context){
$argsIntro
   return ${element.name}$args;
}, 
""";
    _allImport.add('import "${buildStep.inputId.uri}";\n');
    return "";
  }
}

/// main generator
class _RouteMainGenerator extends GeneratorForAnnotation<RouteMain> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    var importString = _allImport.reduce((value, element) => value + element);
    return 'import "package:flutter/material.dart";\n' +
        importString +
        "\n" +
        "Map<String, WidgetBuilder> allRoutes = {$_allBody};\n\n" +
        """
_format(dynamic value,Type to){
  var from = value.runtimeType;
  if (from == String){
    if (to == int){
      return int.parse(value);
    }else if (to == double){
      return double.parse(value);
    }
  }
  return value;
}
    """;
  }
}

/// build page string
Builder routePageSerializable(BuilderOptions options) {
  _allBody = "";
  _allImport = {};
  return LibraryBuilder(_PageGenerator(), generatedExtension: ".page.dart");
}

/// build main file
Builder routeSerializable(BuilderOptions options) {
  return LibraryBuilder(_RouteMainGenerator(), generatedExtension: ".all.dart");
}
