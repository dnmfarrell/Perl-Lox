package Lox;
use autodie;
use strict;
use warnings;
#use AstPrinter;
#use Interpreter;
#use Parser;
use Scanner;

my $had_error = undef;

sub run_file {
  my ($path) = @_;
  open my $fh, '<', $path;
  my $bytes = do { local $/; <$fh> };
  run($bytes);

  if ($had_error) {
    exit 65;
  }
}

sub run_prompt {
  print "Welcome to Lox version 0.01\n> ";

  while (my $line = <>) {
    run($line);
    undef $had_error;
    print "> ";
  }
}

sub run {
  my $source = shift;
  my $scanner = Scanner->new({source => $source});
  eval { $scanner->scan_tokens };
  if ($@) {
    die "Unexpected error: $@";
  }
  elsif ($scanner->{errors}->@*) {
    error(@$_) for ($scanner->{errors}->@*);
  }
    else {
      $scanner->print;
  #    my $parser = Parser->new(tokens => $scanner->{tokens});
  #    my $stmts = $parser->parse;
  #    if ($parser->errors->@*) {
  #      error(@$_) for ($parser->{errors}->@*);
  #    }
  #    else {
  #      #print AstPrinter->new->print_expr($stmts), "\n";
  #      my $interpreter = Interpreter->new;
  #      $interpreter->interpret($stmts);
  #    }
    }
}

sub error {
  my ($token, $message) = @_;
  $had_error = 1;
  report($token->{line}, " at " . $token->{lexeme} . "'", $message);
}

sub report {
  my ($line, $where, $message) = @_;
  printf STDERR "[Line %s] Error %s: %s\n", $line, $where, $message;
}

1;
