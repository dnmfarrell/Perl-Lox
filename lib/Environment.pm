package Environment;
use strict;
use warnings;

sub new {
  my ($class, $args) = @_;
  return bless {
    enclosing => undef,
    values    => {},
    %$args,
  }, $class;
}

sub enclosing { $_[0]->{enclosing} }
sub values { $_[0]->{values} }

sub define {
  my ($self, $name, $value) = @_;
  $self->values->{$name} = $value;
}

sub get {
  my ($self, $token) = @_;
  if (exists $self->values->{$token->lexeme}) {
    my $v = $self->values->{$token->lexeme};
    return $v if defined $v;
    die sprintf 'Uninitialized variable "%s"', $token->lexeme;
  }
  if ($self->enclosing) {
    return $self->enclosing->get($token);
  }
  die sprintf 'Undefined variable "%s".', $token->lexeme;
}

sub assign {
  my ($self, $token, $value) = @_;
  if (exists $self->values->{$token->lexeme}) {
    $self->values->{$token->lexeme} = $value;
    return;
  }

  if ($self->enclosing) {
    return $self->enclosing->assign($token, $value);
  }
  die sprintf 'Undefined variable "%s".', $token->lexeme;
}

1;
