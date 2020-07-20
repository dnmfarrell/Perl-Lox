package Function;
use parent 'Callable';
use overload
  '""' => sub { sprintf '<fn %s >',  $_[0]->declaration->name->lexeme };
use strict;
use warnings;
use Carp 'croak';
use Environment;

sub new {
  my ($class, $args) = @_;
  croak 'Function::new requires a declaration Stmt::Function key/value pair'
    unless $args->{declaration} &&
           ref $args->{declaration} eq 'Stmt::Function';

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
  return $interpreter->execute_block($self->declaration->body, $environment);
}

1;
