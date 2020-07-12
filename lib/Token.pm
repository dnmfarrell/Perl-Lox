package Token;
use strict;
use warnings;
use TokenType ();

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
    TokenType::type($self->{type}),
    $self->{lexeme},
    $self->{literal};
}

sub literal { $_[0]->{literal} }
sub lexeme { $_[0]->{lexeme} }
sub column { $_[0]->{column} }
sub type { $_[0]->{type} }
sub line { $_[0]->{line} }

1;
