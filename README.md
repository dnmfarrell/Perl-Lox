### NAME

Lox - A Perl implementation of the Lox programming language

### DESCRIPTION

A Perl translation of the Java Lox interpreter from
[Crafting Interpreters](https://craftinginterpreters.com/).

### INSTALL

To install the project dependencies and just run `plox` from the project
directory:

    $ cpanm --installdeps .

If you'd rather build and install it:

    $ perl Makefile.PL
    $ make
    $ make test
    $ make install

### SYNOPSIS

If you have built and installed `plox`:

    $ plox
    Welcome to Perl-Lox version 0.01
    >

    $ plox hello.lox
    Hello, World!

Otherwise from the root project directory:

    $ perl -Ilib bin/plox
    Welcome to Perl-Lox version 0.01
    >

    $ perl -Ilib bin/plox hello.lox
    Hello, World!

### TESTING

The test suite includes 238 test files from the Crafting Interpreters
[repo](https://github.com/munificent/craftinginterpreters).

    $ prove -l t/*

### EXTENSIONS

Perl-Lox has these capabilities from the "challenges" sections of the book:

- Anonymous functions `fun () { ... }`
- Multi-line comments `/* ... */`
- Break statements in loops
    - Evaluating an uninitialized variable

### DIFFERENCES

Differences from the canonical "jlox" implementation:

- signed zero is unsupported
- methods are equivalent

    Prints "true" in plox and "false" in jlox:

        class Foo  { bar () { } } print Foo().bar == Foo().bar;

### AUTHOR

Copyright 2020 David Farrell

### LICENSE

See `LICENSE` file.
