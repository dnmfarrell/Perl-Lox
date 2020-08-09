package Lox;
use strict;
use warnings;
use Lox::AstPrinter;
use Lox::Interpreter;
use Lox::Parser;
use Lox::Resolver;
use Lox::Scanner;
use Lox::TokenType;
our $VERSION = 0.01;

my $had_error = undef;

sub run_file {
  my ($path, $debug_mode) = @_;
  open my $fh, '<', $path or die "Error opening $path: $!";
  my $bytes = do { local $/; <$fh> };
  run($bytes, undef, $debug_mode);
  if ($had_error) {
    exit 65;
  }
}

sub run_prompt {
  my ($debug_mode) = @_;
  print "Welcome to Perl-Lox version $VERSION\n> ";
  while (my $line = <>) {
    run($line, 'repl', $debug_mode);
    undef $had_error;
    print "> ";
  }
}

sub run {
  my ($source, $is_repl, $debug_mode) = @_;
  my $scanner = Lox::Scanner->new({source => $source});
  eval { $scanner->scan_tokens };
  if ($@) {
    die "Unexpected error: $@";
  }
  else {
    $scanner->print if $debug_mode;
    return if $had_error;
    my $parser = Lox::Parser->new({tokens => $scanner->{tokens}, repl => $is_repl});
    my $stmts = $parser->parse;
    if ($parser->errors->@*) {
      error(@$_) for ($parser->{errors}->@*);
      return;
    }
    print Lox::AstPrinter->new->print_tree($stmts), "\n" if $debug_mode;
    my $interpreter = Lox::Interpreter->new({});
    my $resolver = Lox::Resolver->new($interpreter);
    $resolver->resolve($stmts);
    return if $had_error;
    $interpreter->interpret($stmts);
  }
}

sub runtime_error {
  my ($token, $message) = @_;
  report($token->{line}, "at '$token->{lexeme}'", $message);
  exit 65;
}

sub error {
  my ($token, $message) = @_;
  $had_error = 1;
  report($token->{line}, "at '$token->{lexeme}'", $message);
}

sub report {
  my ($line, $where, $message) = @_;
  printf "[Line %s] Error %s: %s.\n", $line, $where, $message;
}

1;
__END__
=head1 NAME

Lox - A Perl implementation of the Lox programming language

=head1 DESCRIPTION

A Perl translation of the Java Lox interpreter from
L<Crafting Interpreters|https://craftinginterpreters.com/>.

=head1 INSTALL

To install the project dependencies and just run C<plox> from the project
directory:

  $ cpanm --installdeps .

If you'd rather build and install it:

  $ perl Makefile.PL
  $ make
  $ make test
  $ make install

=head1 SYNOPSIS

If you have built and installed C<plox>:

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


=head1 TESTING

The test suite includes 238 test files from the Crafting Interpreters
L<repo|https://github.com/munificent/craftinginterpreters>.

  $ prove -l t/*

=head1 ISSUES

Differences from the canonical "jlox" implementation:

=over 2

=item * signed zero is unsupported

=item * methods are equivalent

Prints "true" in plox and "false" in jlox:

  class Foo  { bar () { } } print Foo().bar == Foo().bar;

=back

=head1 AUTHOR

Copyright 2020 David Farrell

=head1 LICENSE

See F<LICENSE> file.

=cut
