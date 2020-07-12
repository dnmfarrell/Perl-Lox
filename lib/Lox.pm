package Lox;
use autodie;
use strict;
use warnings;
use AstPrinter;
use Interpreter;
use Parser;
use Scanner;
use TokenType;

my $had_error = undef;

sub run_file {
  my ($path, $debug_mode) = @_;
  open my $fh, '<', $path;
  my $bytes = do { local $/; <$fh> };
  run($bytes, undef, $debug_mode);

  if ($had_error) {
    exit 65;
  }
}

sub run_prompt {
  my ($debug_mode) = @_;
  print "Welcome to Lox version 0.01\n> ";

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
    if ($is_repl) {
      my $eof = pop $scanner->{tokens}->@*;
      unless ($scanner->{tokens}[-1]->type == SEMICOLON) {
        $scanner->new_token(lexeme=>';', type=>SEMICOLON);
      }
      push $scanner->{tokens}->@*, $eof;
    }
    $scanner->print if $debug_mode;
    my $parser = Parser->new({tokens => $scanner->{tokens}, repl => $is_repl});
    my $stmts = $parser->parse;
    if ($parser->errors->@*) {
      error(@$_) for ($parser->{errors}->@*);
    }
    else {
      #print AstPrinter->new->print_expr($stmts), "\n";
      my $interpreter = Interpreter->new({});
      $interpreter->interpret($stmts);
    }
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
