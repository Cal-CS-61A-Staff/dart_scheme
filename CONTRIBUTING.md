# Contributing

## Setting Up Your Development Environment

This interpreter is written in [Dart][]. You should start by downloading
version 2.0.0 of the [Dart SDK][].

You should then clone this repo and  the implementation skeleton into the same
parent directory:

```shell
mkdir scheme && cd scheme
git clone git@github.com:Cal-CS-61A-Staff/dart_scheme.git
git clone git@github.com:jathak/scheme_impl_skeleton.git dart_scheme_impl
```

Replace that last line with the following if you are part of 61A Staff:

```shell
git clone git@github.com:Cal-CS-61A-Staff/dart_scheme_impl.git
```

### Fetching Dependencies

Dart uses `pub` to manage project dependencies. You can run `pub get` from
inside the `dart_scheme` directory to fetch them. If you get errors about
`cs61a_scheme` or `cs61a_scheme_impl`, your directory structure is probably the
issue. Make sure that you have this repo cloned to `dart_scheme` and the
implementation cloned to `dart_scheme_impl` (even if you cloned from the
skeleton).

### Running and Writing Tests

Once you've fetched dependencies, you can run all tests with `pub run test`.

A collection of Scheme tests can be found in `test/tests.scm`. The structure
should match that of `tests.scm` in the 61A project if you want to add more
tests. You can test for error conditions with `; expect Error`. The test harness
that connects these to Dart is in `scm_test.dart`. Please don't change the
header or footer. They're necessary to make the file importable in Dart.

`tests.scm` and any other tests tagged with `@Tags(const ["impl"])` require a
working `dart_scheme_impl` to run. You can skip these tests with
`pub run test -x impl`.

[Dart]: https://dartlang.org
[Dart SDK]: https://www.dartlang.org/install

### Running the Web App

To run the web app, you need to install the `webdev` package by running
`pub global activate webdev`.

You can then run the web app with `webdev serve`. This uses an incremental
compiler that's faster for development, but may have some behavior differences
compared to the released version. It will usually take a while to build the
first time, but all intermediate files are cached on disk, so future builds will
be much faster (even if you kill and relaunch the `webdev` process).

Run `webdev serve --release` to build with the same compiler as the released
version.

## Repo Organization

Most interpreter code is in the `lib` directory. The four libraries at the root
of this directory can be imported outside the project.

- `cs61a_scheme.dart` defines the core interpreter library.
- `cs61a_scheme_extra.dart` defines the extra interpreter library.
- `cs61a_scheme_web.dart` defines the web interpreter library.
- `builder.dart` defines the code generator, which is used to build helpers for
  libraries of Scheme built-ins.

The actual implementation of each of the first three libraries is in
`lib/src/core`, `lib/src/extra`, and `lib/src/web` respectively. Any files that
end with `.g.dart` are generated and should not be changed by hand.

The `styles` directory contains the Sass files for diagramming and the theming
mixins.

Tests are contained in the `test` directory.

Miscellanous documentation (for special forms and other topics) lives in
`lib/src/core/documentation.md` and is compiled into a form that allows users
to reference it from the interpreter (`(docs &lt;topic>)`).

The web frontend is contained in the `web` directory and the `lib/web_ui`
directory.

A simple CLI repl is contained in `tool/repl.dart`. Dart package layout
conventions would usually include this in `bin`, but since it depends on the
implementation dev dependency, it can't be.

## Creating a `SchemeLibrary`

The most common way to add a collection of new built-in Scheme procedures is by
creating a `SchemeLibrary`. There are four exiting libraries: `StandardLibrary`
in `cs61a_scheme.core`, `ExtraLibrary` in `cs61a_scheme.extra`, and `WebLibrary`
and `TurtleLibrary` in `cs61a_scheme.web`. You'll likely want to look at these
for examples.

Each `SchemeLibrary` is supported by a generated mixin that is responsible for
loading all built-ins and doing various type checks and conversions. Whenever
you create a new `SchemeLibrary`, make sure to add it to the list of libraries
in `tool/grind.dart`. You also need to annotate the class with `@schemelib`.

### Adding Built-Ins

Once you've created your library, you can add a new built-in by simply defining
a method. The simplest possible structure would be as follows:

```dart
Expression example(List<Expression> expression, Frame env) {...}
```

This would create a built-in `example` procedure that takes in any number of
arguments (including 0).

`env` is the frame in which the procedure was
called. This can be useful both for accessing the current frame (for built-ins
like `eval`) and for accessing `env.interpreter` for things like logging. If
you don't need it, you can omit that parameter.

### Naming and Specifing Arity

But what about built-ins like `-` (subtraction)? Its name is not a valid Dart
identifier, and it requires a minimum of 1 argument. We can specify this with
annotations:

```dart
// from lib/src/core/standard_library.dart
@SchemeSymbol("-")
@MinArgs(1)
Number sub(List<Expression> args) {...}
```

Without the `@SchemeSymbol` annotation, we just define the procedure's name as
the method's. With it, we instead define it to be the symbol we provide.

If you wish to alias a built-in, you can add multiple annotations. Only the
first will be used as the intrinsic name, but all of them will be bound.

We can also use `@MinArgs` and/or `@MaxArgs` to define limits on the number of
arguments.

### Type Casting

If your procedure takes in a fixed number of arguments, you can specify them
directly as parameters and the generated code will unpack and type check them
for you.

```dart
Expression example(Number a, Number b) {...}
```

Now `example` takes in two Scheme numbers! If you give it the wrong number of
arguments, or arguments that aren't numbers, it will throw a `SchemeException`.

### Type Conversion

A lot of Scheme expression types are just wrappers around native Dart types.
The Dart types are easier to work with, so sometimes we want our arguments or
return value to use them instead of the Scheme wrapper.

```dart
int increment(int x) => x + 1;
```

This will create a Scheme built-in `increment` that takes in and returns an
`Integer`, but the body of our function gets to work with a Dart `int`.

The following conversions are currently supported:

| Scheme Type    | Dart Type |
| -------------- | --------- |
| `Boolean`      | `bool`    |
| `Integer`      | `int`     |
| `Double`       | `double`  |
| `Number`       | `num`     |
| `SchemeString` | `String`  |

Note that the Dart `int` type is of limited size when running on the web (64-bit
floating point), or on all platforms starting in Dart 2 (64-bit integer). The
conversion from `Integer` to `int` is unspecified for large values.

### Documentation

The code generator will also embed the doc comments on a library into the
library itself, so they can be referenced from the interpreter. Any built-in
intended for general use should have a doc comment.

Doc comments must not exceed 80 characters of width, since they will not be
wrapped when viewed within the interpreter.

You can reference parameter names within your comment by putting the name in
square brackets. This only works for explicitly named parameters.

### Importing a `SchemeLibrary`

Only the `StandardLibrary` is included automatically in a new `Interpreter`.
Other libraries need to be imported like so:

```dart
interpreter.importLibrary(new YourLibrary());
```

### Generated Code

All this fanciness works because of generated code. If you add or change the
signature of any methods in a `SchemeLibrary`, run `pub run grinder` to
regenerate the `.g.dart` files.

## Creating a Pull Request

Before creating a PR, please make sure you have done the following:

* Run `dartfmt -w .` to format your code (or, even better, configure your editor 
  to do this for you when you save).

* Run `dartanalyzer --fatal-warnings .` to make sure you code doesn't
  cause any analysis errors or warnings. Most editors with Dart support should
  do this automatically.

* Run `pub run grinder` to keep the generated code in sync with your changes.

* Run `pub run dependency_validator` to make sure you're not depending on
  anything unnecessarily.

* Run `pub run test` to make sure all the tests pass. If you don't have a
  complete `StaffProjectImplementation`, add `-x impl` to test everything else,
  and let us know that you haven't run the impl tests in your PR.

When you make your PR, Travis will confirm that all of these checks pass before
it lets us merge. Save time by checking it yourself first.

We don't have a formal contributor license agreement, but by making a PR, you
are agreeing to license your code to us under the terms of the 3-clause BSD
license found in [LICENSE](LICENSE).
