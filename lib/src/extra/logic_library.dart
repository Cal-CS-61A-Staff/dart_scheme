library cs61a_scheme.extra.logic_library;

import 'package:cs61a_scheme/cs61a_scheme.dart';

import 'package:cs61a_scheme/logic.dart' as logic;

import 'operand_procedures.dart';

part 'logic_library.g.dart';

/// Note: When the signatures (including any annotations) of any of theses methods
/// change, make sure to `pub run grinder` to rebuild the mixin (which registers
/// the primitives and performs type checking on arguments).
@library
class LogicLibrary extends SchemeLibrary with _$LogicLibraryMixin {
  Map<Frame, List<logic.Fact>> facts = new Map.identity();

  @override
  void importAll(Frame env) {
    Frame child = new Frame(env, env.interpreter);
    super.importAll(child);
    var sym = const SchemeSymbol('logic');

    // Only import the loader to start. Calling logic imports the rest.
    env.define(sym, child.bindings[sym]);
  }

  @SchemeSymbol('logic')
  void logicStart(Frame env) {
    super.importAll(env);
  }

  @SchemeSymbol('fact')
  @SchemeSymbol('!')
  @noeval
  void fact(List<Expression> exprs, Frame env) {
    if (!facts.containsKey(env)) facts[env] = [];
    facts[env].add(new logic.Fact(exprs.first, exprs.skip(1)));
  }

  @SchemeSymbol('query')
  @SchemeSymbol('?')
  @noeval
  void query(List<Expression> exprs, Frame env) {
    bool success = false;
    for (var sol in logic.evaluate(new logic.Query(exprs), facts[env] ?? [])) {
      if (!success) env.interpreter.logText('Success!');
      success = true;
      env.interpreter.logger(sol, true);
    }
    if (!success) env.interpreter.logText('Failure.');
    return null;
  }
}
