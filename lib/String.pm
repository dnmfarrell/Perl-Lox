package String;
use strict;
use warnings;
use Bool;
use overload
  '""' => sub { ${$_[0]} },
  'bool' => sub { $True },
  '!' => sub { $False },
  fallback => 0;

our $VERSION = 0.01;

sub new {
  my ($class, $string) = @_;
  return bless \$string, $class;
}

1;
