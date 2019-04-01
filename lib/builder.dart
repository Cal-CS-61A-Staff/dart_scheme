library builder;

import 'dart:convert' show json;

// ignore: deprecated_member_use
import 'package:analyzer/analyzer.dart';

/// Generates mixin source code to implement importAll on a SchemeLibrary
/// based on the library's source code.
String generateImportMixin(String sourceCode) {
  CompilationUnit ast = parseCompilationUnit(sourceCode);
  for (CompilationUnitMember decl in ast.declarations) {
    if (decl is ClassDeclaration) {
      for (Annotation annotation in decl.metadata) {
        if (annotation.name.toSource() == "schemelib") {
          return _buildMixin(decl);
        }
      }
    }
  }
  return null;
}

String _buildMixin(ClassDeclaration decl) {
  List<BuiltinStub> builtins = [];
  List<String> abstractMethods = [];
  for (ClassMember member in decl.members) {
    if (member is MethodDeclaration) {
      String name = member.name.toSource();
      if (!name.startsWith('import') && !name.startsWith('_')) {
        abstractMethods.add(_buildAbstract(member));
        builtins.add(_buildStub(member));
      }
    }
  }
  if (builtins.any((stub) => stub.needsTurtle)) {
    abstractMethods.add('Turtle get turtle;');
  }
  String mixinName = decl.withClause.mixinTypes[0].name.toSource();
  return """// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: unnecessary_this
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: unnecessary_lambdas
abstract class $mixinName {
  ${abstractMethods.join("\n  ")}
  void importAll(Frame __env) {
    ${builtins.join("\n    ")}
  }
}""";
}

String _buildAbstract(MethodDeclaration method) =>
    "${method.returnType} ${method.name}${method.parameters};";

class BuiltinStub {
  String methodName;
  String name;
  List<String> aliases = [];
  int minArgs = 0, maxArgs = -1;
  bool variableArity = false;

  List<String> events = [];
  bool operandProcedure = false;
  bool needsTurtle = false;

  String returnType;
  List<String> paramTypes;
  List<String> paramNames;
  String variableType;
  bool needsEnvironment = false;

  String comment;

  String get symbol => 'const SchemeSymbol($name)';

  toString() {
    var fn = _makeFunction();
    var extra = aliases
        .map((alias) => 'const SchemeSymbol($alias)')
        .map((alias) => '__env.bindings[$alias] = __env.bindings[$symbol];'
            '__env.hidden[$alias] = true;')
        .join('');
    var op = operandProcedure ? "Operand" : "";
    var arity = variableArity ? "Variable" : "";
    var args = variableArity ? "$minArgs, maxArgs: $maxArgs" : "$minArgs";
    var docs = variableArity ? _makeVariableDocs() : _makeDocs();
    return "add$arity${op}Builtin(__env, $symbol, $fn, $args $docs);$extra";
  }

  String _makeVariableDocs() {
    if (comment == null) return "";
    var ret = docTypes.containsKey(returnType)
        ? ', returnType:' + json.encode(docTypes[returnType])
        : '';
    return ", docs: Docs.variable($name, ${json.encode(comment)} $ret)";
  }

  String _makeDocs() {
    if (comment == null) return "";
    var commentStr = json.encode(comment);
    var params = [];
    for (int i = 0; i < paramTypes.length; i++) {
      var type = docTypes.containsKey(paramTypes[i])
          ? json.encode(docTypes[paramTypes[i]])
          : 'null';
      params.add('Param($type, ${json.encode(paramNames[i])})');
    }
    var ret = docTypes.containsKey(returnType)
        ? ', returnType:' + json.encode(docTypes[returnType])
        : '';
    return ", docs: Docs($name, $commentStr, [${params.join(', ')}] $ret)";
  }

  String _makeFunction() {
    if (variableArity &&
        needsEnvironment &&
        variableType == 'Value' &&
        !returnConversions.containsKey(returnType) &&
        returnType != 'void') return "this.$methodName";
    String before = needsTurtle ? "turtle.show();" : "";
    String after = "";
    String prefix = "return";
    for (var event in events) {
      if (returnType == 'void') {
        after += "__env.interpreter.triggerEvent($event, [undefined], __env);";
      } else {
        prefix = "var __value =";
        after += "__env.interpreter.triggerEvent($event, [__value], __env);";
      }
    }
    if (returnType == 'void') {
      prefix = "";
      after += "return undefined;";
    }
    String checks = _makeChecks();
    String call = "this.$methodName(${_makeParams()})";
    call = _wrapReturn(call);
    return "(__exprs, __env) {$checks $before $prefix $call; $after}";
  }

  String _makeChecks() {
    var checks = [];
    if (variableArity) {
      var type = variableType;
      if (typeChecks.containsKey(type)) {
        type = typeChecks[type];
      } else if (type.startsWith('SchemeList')) {
        type = 'PairOrEmpty';
      }
      if (type != 'Value') checks.add("__exprs.any((x) => x is! $type)");
    } else {
      for (int i = 0; i < paramTypes.length; i++) {
        var type = paramTypes[i];
        if (typeChecks.containsKey(type)) {
          type = typeChecks[type];
        } else if (type.startsWith('SchemeList')) {
          type = 'PairOrEmpty';
        }
        if (type != 'Value') checks.add("__exprs[$i] is! $type");
      }
    }
    if (checks.isEmpty) return "";
    var decodeName = name.substring(1, name.length - 1);
    var error = "Argument of invalid type passed to $decodeName.";
    return "if(${checks.join('||')}) throw SchemeException('$error');";
  }

  String _makeParams() {
    var params = [];
    if (variableArity) {
      var param = "__exprs";
      var type = variableType;
      if (typeChecks.containsKey(type)) {
        type = typeChecks[type];
      }
      if (type != 'Value') param += ".cast<$type>()";
      var converted = _convertParam('x', variableType);
      if (converted != 'x') {
        param += '.map((x) => $converted).toList()';
      }
      params.add(param);
    } else {
      for (int i = 0; i < paramTypes.length; i++) {
        var param = _convertParam('__exprs[$i]', paramTypes[i]);
        params.add(param);
      }
    }
    if (needsEnvironment) params.add("__env");
    return params.join(',');
  }

  String _convertParam(String param, String type) {
    switch (type) {
      case 'int':
        param = '$param.toJS().toInt()';
        break;
      case 'double':
        param = '$param.toJS().toDouble()';
        break;
      case 'num':
        param = '$param.toJS()';
        break;
      case 'bool':
        param = '$param.isTruthy';
        break;
      case 'String':
        param = '($param as SchemeString).value';
        break;
    }
    if (type.startsWith('SchemeList')) {
      param = '$type($param)';
    }
    return param;
  }

  String _wrapReturn(String call) {
    if (returnConversions.containsKey(returnType)) {
      return '${returnConversions[returnType]}($call)';
    }
    if (returnType.startsWith('SchemeList')) {
      return '($call).list';
    }
    return call;
  }

  static const Map<String, String> docTypes = {
    'int': 'int',
    'Integer': 'int',
    'double': 'float',
    'Double': 'float',
    'num': 'num',
    'Number': 'num',
    'bool': 'bool',
    'Boolean': 'bool',
    'String': 'string',
    'SchemeString': 'string',
    'SchemeSymbol': 'symbol',
    'Procedure': 'procedure',
    'Pair': 'pair',
    'SchemeEventListener': 'event listener',
    'JsValue': 'js object',
    'JsProcedure': 'js function',
    'Color': 'color',
    'ImportedLibrary': 'library',
    'Value': 'value',
    'Expression': 'expression'
  };

  static const Map<String, String> typeChecks = {
    'int': 'Integer',
    'double': 'Double',
    'num': 'Number',
    'bool': 'Boolean',
    'String': 'SchemeString'
  };

  static const Map<String, String> returnConversions = {
    'int': 'Number.fromInt',
    'double': 'Number.fromDouble',
    'num': 'Number.fromNum',
    'String': 'SchemeString',
    'bool': 'Boolean',
    'Future<Value>': 'AsyncValue',
    'JsFunction': 'JsProcedure',
    'JsObject': 'JsValue'
  };
}

String _parseComment(Comment comment) {
  if (comment == null) return null;
  var result = "";
  var current = comment.beginToken;
  while (current != null) {
    result += current.lexeme.substring(3).trim() + '\n';
    current = current.next;
  }
  return result;
}

BuiltinStub _buildStub(MethodDeclaration method) {
  var stub = BuiltinStub();
  stub.methodName = method.name.toSource();

  stub.comment = _parseComment(method.documentationComment);
  String arg(Annotation ant) => ant.arguments.arguments[0].toSource();
  for (Annotation ant in method.metadata) {
    switch (ant.name.toSource()) {
      case "MinArgs":
        stub.minArgs = int.parse(arg(ant));
        stub.variableArity = true;
        break;
      case "MaxArgs":
        stub.maxArgs = int.parse(arg(ant));
        stub.variableArity = true;
        break;
      case "SchemeSymbol":
        if (stub.name == null) {
          stub.name = arg(ant).toLowerCase();
        } else {
          stub.aliases.add(arg(ant).toLowerCase());
        }
        break;
      case "TriggerEventAfter":
        stub.events.add(arg(ant));
        break;
      case "noeval":
        stub.operandProcedure = true;
        break;
      case "turtlestart":
        stub.needsTurtle = true;
        break;
    }
  }
  stub.name ??= json.encode(method.name.toSource().toLowerCase());
  stub.returnType = method.returnType.toSource();
  var variableType = _findVariableArityType(method);
  if (stub.variableArity && variableType == null) {
    print(method);
    throw Exception("Built-ins with fixed arguments can't have min/max");
  }
  stub.variableArity = variableType != null;
  if (stub.variableArity) {
    stub.variableType = variableType;
    int paramCount = method.parameters.parameters.length;
    if (paramCount != 1 && paramCount != 2) {
      throw Exception("${stub.name} has an invalid number of parameters!");
    }
    stub.needsEnvironment = paramCount == 2;
  } else {
    stub.paramTypes = _paramTypes(method);
    stub.paramNames = _paramNames(method);
    stub.needsEnvironment =
        stub.paramTypes.isNotEmpty && stub.paramTypes.last == "Frame";
    if (stub.needsEnvironment) stub.paramTypes.removeLast();
    stub.minArgs = stub.paramTypes.length;
    stub.maxArgs = stub.paramTypes.length;
  }
  return stub;
}

List<String> _paramTypes(MethodDeclaration method) {
  List<String> types = [];
  for (FormalParameter param in method.parameters.parameters) {
    if (param is SimpleFormalParameter) {
      if (param.type == null) {
        throw Exception("Built-in procedure parameters must be typed.");
      }
      types.add(param.type.toSource());
    } else {
      throw Exception("Built-in procedures may not have optional parameters");
    }
  }
  return types;
}

List<String> _paramNames(MethodDeclaration method) {
  List<String> names = [];
  for (FormalParameter param in method.parameters.parameters) {
    names.add(param.identifier.toSource());
  }
  return names;
}

String _findVariableArityType(MethodDeclaration method) {
  if (method.parameters.parameters.isEmpty) return null;
  FormalParameter param = method.parameters.parameters[0];
  if (param is! SimpleFormalParameter) {
    throw Exception("Built-in procedures may not have optional parameters.");
  }
  TypeAnnotation paramType = (param as SimpleFormalParameter).type;
  if (paramType is! NamedType) return null;
  NamedType namedType = paramType as NamedType;
  if (namedType.name.toSource() != 'List') return null;
  if ((namedType.typeArguments?.length ?? 0) == 0) return null;
  return namedType.typeArguments.arguments[0].toSource();
}

String generateDocumentation(String markdownSource) {
  Map<String, String> docs = {};
  String current;
  for (var line in markdownSource.split('\n')) {
    line = line.trim();
    if (line.startsWith('#')) {
      current = line.substring(1).trim();
      if (docs.containsKey(current)) {
        throw Exception("Duplicate documentation for '$current'");
      }
      docs[current] = "";
    } else {
      docs[current] += line + '\n';
    }
  }
  var pairs = docs
      .map((k, v) => MapEntry(
          json.encode(k) + ": Docs.markdown(" + json.encode(v.trim()) + ")",
          null))
      .keys;
  return """part of cs61a_scheme.core.documentation;

Map<String, Docs> miscDocumentation = {
  ${pairs.join(',')}
};
""";
}
