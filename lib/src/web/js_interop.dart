library cs61a_scheme.web.js_interop;

import 'dart:async';
import 'dart:js';

import 'package:cs61a_scheme/cs61a_scheme_extra.dart';

class JsProcedure extends Procedure {
  final SchemeSymbol name = null;
  final JsFunction fn;
  JsProcedure(this.fn);
  Value apply(SchemeList args, Frame env) {
    var result = fn.apply(args.map((arg) => arg.toJS()).toList());
    return jsToScheme(result);
  }

  toJS() => fn;
}

class JsValue extends Value {
  final JsObject obj;
  JsValue(this.obj);
  toString() {
    var objString = obj.toString();
    if (objString.length > 20) objString = objString.substring(0, 17) + "...";
    return "#[js:$objString]";
  }

  toJS() => obj;
}

class NativeValue extends Value {
  final Object obj;
  NativeValue(this.obj);
  toString() {
    var objString = obj.toString();
    if (objString.length > 20) objString = objString.substring(0, 17) + "...";
    return "#[native:$objString]";
  }

  toJS() => obj;
}

Value jsToScheme(obj) {
  if (obj is Value) return obj;
  if (obj is num) return Number.fromNum(obj);
  if (obj is bool) return obj ? schemeTrue : schemeFalse;
  if (obj is String) return SchemeString(obj);
  if (obj is JsFunction) {
    if (obj.hasProperty('wrappedSchemeProcedure')) {
      return obj['wrappedSchemeProcedure'];
    }
    return JsProcedure(obj);
  }
  if (obj is JsObject) return jsObjectToScheme(obj);
  if (obj == null) return undefined;
  if (obj == context['undefined']) return undefined;
  return NativeValue(obj);
}

Value jsObjectToScheme(JsObject obj) {
  var type =
      context['Object']['prototype']['toString'].callMethod('call', [obj]);
  if (type == '[object Promise]') {
    var completer = Completer();
    obj.callMethod('then', [completer.complete, completer.completeError]);
    var future = completer.future.then(jsToScheme);
    return AsyncValue(future)..jsPromise = obj;
  }
  return JsValue(obj);
}

Value jsEval(String code) {
  try {
    return jsToScheme(context.callMethod("eval", [code]));
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    if (e is SchemeException) rethrow;
    throw SchemeException("$e");
  }
}

JsFunction procedureToJsFunction(Procedure procedure, Frame env) {
  var wrapper = context.callMethod("eval", [
    "(fn) => {function wrapped(){return fn(Array.from(arguments));} return wrapped;}"
  ]) as JsFunction;
  var wrapped = wrapper.apply([
    allowInterop((args) {
      var schemeArgs = <Value>[];
      for (var arg in args) {
        schemeArgs.add(jsToScheme(arg));
      }
      return schemeApply(procedure, SchemeList.fromIterable(schemeArgs), env)
          .toJS();
    })
  ]) as JsFunction;
  wrapped['wrappedSchemeProcedure'] = procedure;
  return wrapped;
}
