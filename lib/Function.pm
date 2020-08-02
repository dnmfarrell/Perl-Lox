package Function;
use parent 'Callable';
use strict;
use warnings;
use Bool;
use Carp 'croak';
use Environment;
use overload
  '""' => sub { sprintf '<fn %s>',  $_[0]->declaration->name->lexeme },
  '!'  => sub { False->new },
  'bool' => sub { True->new }, # only false and nil are untrue in Lox
  fallback => 0;

sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

sub declaration { $_[0]->{declaration} }
sub closure { $_[0]->{closure} }
sub arity { scalar $_[0]->declaration->params->@* }

sub call {
  my ($self, $interpreter, $args) = @_;
  my $environment = Environment->new({ enclosing => $self->closure });
  for (my $i = 0; $i < $self->declaration->params->@*; $i++) {
    $environment->define($self->declaration->params->[$i]->lexeme,$args->[$i]);
  }
  my $sub = sub {
    $interpreter->execute_block($self->declaration->body, $environment);
  };
  return $self->call_catch_return($interpreter, $sub);
}

1;
