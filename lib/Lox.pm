package Lox;
use strict;
use warnings;
use AstPrinter;
use Interpreter;
use Parser;
use Resolver;
use Scanner;
use TokenType;
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
  my $scanner = Scanner->new({source => $source});
  eval { $scanner->scan_tokens };
  if ($@) {
    die "Unexpected error: $@";
  }
  elsif ($scanner->{errors}->@*) {
    error(@$_) for ($scanner->{errors}->@*);
  }
  else {
    $scanner->print if $debug_mode;
    my $parser = Parser->new({tokens => $scanner->{tokens}, repl => $is_repl});
    my $stmts = $parser->parse;
    if ($parser->errors->@*) {
      error(@$_) for ($parser->{errors}->@*);
      return;
    }
    print AstPrinter->new->print_tree($stmts), "\n" if $debug_mode;
    my $interpreter = Interpreter->new({});
    my $resolver = Resolver->new($interpreter);
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
