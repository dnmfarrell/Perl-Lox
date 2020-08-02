package Nil;
use strict;
use warnings;
use Bool;
use overload
  '""' => sub { 'nil' },
  '!'  => sub { True->new },
  'bool' => sub { False->new },
  fallback => 0;


sub new {
  my $class = shift;
  my $undef = undef;
  return bless \$undef, $class;
}

1;
