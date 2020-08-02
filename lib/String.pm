package String;
use strict;
use warnings;
use Bool;
use overload
  '""' => sub { ${$_[0]} },
  'bool' => sub { True->new },
  fallback => 1;

sub new {
  my ($class, $string) = @_;
  return bless \$string, $class;
}

1;
