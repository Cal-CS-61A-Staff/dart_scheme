library cs61a_scheme.core.project_interface;

import 'dart:async';

import 'expressions.dart';
import 'procedures.dart';

/// Interface for the Scheme project implementation.
///
/// This code is not publicly released, as it is ported from the solutions to
/// the Scheme project. An object implementing this interface must be passed to
/// the Interpreter constructor for it to work.
///
/// 61A staff members should be able to use the private dart_scheme_impl on our
/// GitHub org. Non-staff members can implement their own based on the
/// [skeleton][] (if you're not likely to take 61A now or in the future, you
/// can also ask Jen for a copy of the code).
///
/// Reminder for Berkeley students: **publicly distributing an implementation of
/// this class constitutes academic dishonesty as described in our
/// [course policies]**, as the implementation is close enough to the Scheme
/// project's to be considered distribution of solutions, despite the change of
/// language from Python to Dart. This applies even if you are not currently
/// taking 61A.
///
/// [skeleton]: https://github.com/jathak/scheme_impl_skeleton
/// [course policies]: https://cs61a.org/articles/about.html#academic-honesty
abstract class ProjectInterface {
  /// Analagous to scheme_read ans read_tail in Problems 1, 2, and 7
  Expression read(List<Expression> tokens);

  /// Analagous to Frame.define and Frame.lookup in Problem 3
  void defineInFrame(SchemeSymbol symbol, Expression value, Frame env);
  Expression lookupInFrame(SchemeSymbol symbol, Frame env);

  /// Analagous to BuiltinProcedure.apply in Problem 4
  Expression builtinApply(
          BuiltinProcedure procedure, PairOrEmpty args, Frame env) =>
      // ignore: deprecated_member_use
      primitiveApply(procedure, args, env);

  @deprecated
  Expression primitiveApply(
      BuiltinProcedure procedure, PairOrEmpty args, Frame env);

  /// Analagous to part of scheme_eval implemented in Problem 5
  Expression evalProcedureCall(Expression first, Expression rest, Frame env);

  /// Analagous to Procedure.eval_call in Problem 5
  Expression procedureCall(
      Procedure procedure, PairOrEmpty operands, Frame env);

  /// Analagous to do_define_form in Problems 6 and 10
  Expression doDefineForm(PairOrEmpty expressions, Frame env);

  /// Analagous to do_quote_form in Problem 7
  Expression doQuoteForm(PairOrEmpty expressions, Frame env);

  /// Analagous to eval_all in Problem 8
  Expression evalAll(PairOrEmpty expressions, Frame env);

  /// Analagous to do_lambda_form in Problem 9
  LambdaProcedure doLambdaForm(PairOrEmpty expressions, Frame env);

  /// Analagous to Frame.make_child_frame in Problem 11
  Frame makeChildOf(Expression formals, Expression vals, Frame parent);

  /// Analagous to LambdaProcedure.make_call_frame in Problem 12
  Frame makeLambdaFrame(LambdaProcedure procedure, PairOrEmpty args, Frame env);

  /// Analagous to do_and_form and do_or_form in Problem 13
  Expression doAndForm(PairOrEmpty expressions, Frame env);
  Expression doOrForm(PairOrEmpty expressions, Frame env);

  /// Analagous to part of do_cond_form in Problem 14
  Expression evalCondResult(PairOrEmpty clause, Frame env, Expression test);

  /// Analagous to make_let_frame in Problem 15
  Frame makeLetFrame(PairOrEmpty bindings, Frame env);

  /// Analagous to MuProcedure.make_call_frame in Problem 16
  Frame makeMuFrame(MuProcedure procedure, PairOrEmpty args, Frame env);

  /// Analagous to do_mu_form in Problem 16
  MuProcedure doMuForm(PairOrEmpty expressions, Frame env);

  /// Analagous to do_if_form, but with some changes from the spec
  Expression doIfForm(PairOrEmpty expressions, Frame env);

  /// Analagous to scheme_optimized_eval with tail=True in Problem 20 (EC)
  Expression tailEval(Expression expression, Frame env);

  /// Analagous to scheme_call_cc in Problem 21 (EC)
  Expression callWithCurrentContinuation(Procedure procedure, Frame env);

  /// Analagous to part of ContinuationProcedure.apply in Problem 21 (EC)
  Expression continuationApply(
      Continuation procedure, PairOrEmpty args, Frame env);

  /// Analagous to MacroProcedure.eval_call in Problem 22 (EC)
  Expression macroCall(
      MacroProcedure procedure, PairOrEmpty operands, Frame env);

  /// Analagous to do_define_macro in Problem 22
  Expression doDefineMacro(PairOrEmpty expressions, Frame env);

  /// Async version of doDefineForm
  Future<Expression> asyncDefineForm(PairOrEmpty expressions, Frame env);

  /// Async version of doAndForm
  Future<Expression> asyncAndForm(PairOrEmpty expressions, Frame env);

  /// Async version of doOrForm
  Future<Expression> asyncOrForm(PairOrEmpty expressions, Frame env);

  /// Async version of evalCondResult
  Future<Expression> asyncCondResult(
      PairOrEmpty clause, Frame env, Expression test);

  /// Async version of evalAll
  Future<Expression> asyncEvalAll(PairOrEmpty expressions, Frame env);

  /// Async version of makeLetFrame
  Future<Frame> asyncLetFrame(PairOrEmpty bindings, Frame env);

  /// Async version of evalProcedureCall
  Future<Expression> asyncEvalProcedureCall(
      Expression first, Expression rest, Frame env);

  /// Async version of procedureCall
  Future<Expression> asyncProcedureCall(
      Procedure procedure, PairOrEmpty operands, Frame env);

  /// Implements define-async. Similar to a regular procedure define.
  Expression doDefineAsync(PairOrEmpty expressions, Frame env);

  /// Implements lambda-async. Similar to a regular lambda.
  LambdaProcedure doAsyncLambda(PairOrEmpty expressions, Frame env);
}

/// Use this as a mixin when not implementing tail call optimization
/// If using this, make sure to set tailCallOptimization = true.
abstract class UnimplementedTailCalls {
  Expression tailEval(Expression expression, Frame env) {
    throw UnimplementedError("Tail calls not implemented");
  }
}

/// Use this as a mixin when not implementing continuations
abstract class UnimplementedContinuations {
  Expression callWithCurrentContinuation(Procedure procedure, Frame env) {
    throw UnimplementedError("Continuations not supported");
  }

  Expression continuationApply(
      Continuation procedure, PairOrEmpty args, Frame env) {
    throw UnimplementedError("Continuations not supported");
  }
}

/// Use this as a mixin when not implementing macros
abstract class UnimplementedMacros {
  Expression macroCall(
      MacroProcedure procedure, PairOrEmpty operands, Frame env) {
    throw UnimplementedError("Macros not supported");
  }

  Expression doDefineMacro(PairOrEmpty expressions, Frame env) {
    throw UnimplementedError("Macros not supported");
  }
}

/// Use this as a mixin when not implementing the async-await.
abstract class UnimplementedAsync {
  Future<Expression> asyncDefineForm(PairOrEmpty expressions, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }

  Future<Expression> asyncAndForm(PairOrEmpty expressions, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }

  Future<Expression> asyncOrForm(PairOrEmpty expressions, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }

  Future<Expression> asyncCondResult(
      PairOrEmpty clause, Frame env, Expression test) {
    throw UnimplementedError("Async/await not supported");
  }

  Future<Expression> asyncEvalAll(PairOrEmpty expressions, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }

  Future<Frame> asyncLetFrame(PairOrEmpty bindings, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }

  Future<Expression> asyncEvalProcedureCall(
      Expression first, Expression rest, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }

  Future<Expression> asyncProcedureCall(
      Procedure procedure, PairOrEmpty operands, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }

  Expression doDefineAsync(PairOrEmpty expressions, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }

  LambdaProcedure doAsyncLambda(PairOrEmpty expressions, Frame env) {
    throw UnimplementedError("Async/await not supported");
  }
}
