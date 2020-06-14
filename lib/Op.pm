package Op;
use autodie;
use strict;
use warnings;
use Scanner;

my $had_error;

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
  print "Welcome to Op version 0.01\n> ";

  while (my $line = <>) {
    run($line);
    undef $had_error;
    print "> ";
  }
}

sub run {
  my $source = shift;
  my $scanner = Scanner->new({source => $source});
  $scanner->scan_tokens;
  for my $e ($scanner->{errors}->@*) {
    error(@$e);
  }
  for my $t ($scanner->{tokens}->@*) {
    print $t->to_string, "\n";
  }
}

sub error {
  my ($line, $message) = @_;
  $had_error = 1;
  report($line, "", $message);
}

sub report {
  my ($line, $where, $message) = @_;
  printf STDERR "[Line %s] Error %s: %s\n", $line, $where, $message;
}

1;
