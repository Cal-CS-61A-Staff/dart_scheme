part of cs61a_scheme.extra.logic_library;

// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: unnecessary_this
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: unnecessary_lambdas
abstract class _$LogicLibraryMixin {
  void fact(List<Expression> exprs);
  void query(List<Expression> exprs, Frame env);
  void queryOne(List<Expression> exprs, Frame env);
  String prolog();
  void importAll(Frame __env) {
    addVariableOperandPrimitive(__env, const SchemeSymbol('fact'),
        (__exprs, __env) {
      var __value = undefined;
      this.fact(__exprs);
      return __value;
    }, 0, -1);
    __env.bindings[const SchemeSymbol('!')] =
        __env.bindings[const SchemeSymbol('fact')];
    __env.hidden[const SchemeSymbol('!')] = true;
    addVariableOperandPrimitive(__env, const SchemeSymbol('query'),
        (__exprs, __env) {
      var __value = undefined;
      this.query(__exprs, __env);
      return __value;
    }, 0, -1);
    __env.bindings[const SchemeSymbol('?')] =
        __env.bindings[const SchemeSymbol('query')];
    __env.hidden[const SchemeSymbol('?')] = true;
    addVariableOperandPrimitive(__env, const SchemeSymbol('query-one'),
        (__exprs, __env) {
      var __value = undefined;
      this.queryOne(__exprs, __env);
      return __value;
    }, 0, -1);
    addPrimitive(__env, const SchemeSymbol('prolog'), (__exprs, __env) {
      return SchemeString(this.prolog());
    }, 0);
  }
}
