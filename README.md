### NAME

Lox - A Perl implementation of the Lox programming language

### DESCRIPTION

A Perl translation of the Java Lox interpreter from [Crafting Interpreters](https://craftinginterpreters.com/).

### INSTALL

    $ cpanm --installdeps .

### SYNOPSIS

    $ perl -Ilib bin/plox
    Welcome to Perl-Lox version 0.01
    >

    $ perl -Ilib bin/plox hello.lox
    Hello, World!

### TESTING

The test suite includes 252 test files from the Crafting Interpreters [repo](https://github.com/munificent/craftinginterpreters).

    $ prove -l t/*

### ISSUES

Differences from the canonical "jlox" implementation:

- signed zero is unsupported
- methods are equivalent

    Prints "true" in plox and "false" in jlox:

        class Foo  { bar () { } } print Foo().bar == Foo().bar;

### AUTHOR

Copyright 2020 David Farrell

### LICENSE

See `LICENSE` file.
