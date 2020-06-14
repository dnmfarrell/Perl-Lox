package Token;
use strict;
use warnings;
use TokenType;

sub new {
  my ($class, $args) = @_;
  return bless {
    literal => $args->{literal},
    lexeme  => $args->{lexeme},
    column  => $args->{column},
    type    => $args->{type},
    line    => $args->{line},
  }, $class;
}

sub to_string {
  my $self = shift;
  return sprintf '%3d:%3d %-12s %s %s',
    $self->{line},
    $self->{column},
    type($self->{type}),
    $self->{lexeme},
    $self->{literal};
}

1;
