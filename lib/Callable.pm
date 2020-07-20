package Callable;
use strict;
use warnings;

sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

sub arity { $_[0]->{arity} }
sub call {
  my ($self, $interpreter, @args) = @_;
  return $self->{call}->($interpreter, @args);
}

1;
