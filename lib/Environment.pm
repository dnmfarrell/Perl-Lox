package Environment;
use strict;
use warnings;
use Moo;

has enclosing => (
  is => 'ro',
  isa => sub { $_->isa('Environment') },
);

has values => (
  is => 'rw',
  isa => sub { ref $_ eq 'HASH' },
  default => sub { +{} },
);

sub define {
  my ($self, $name, $value) = @_;
  $self->values->{$name} = $value;
}

sub get {
  my ($self, $token) = @_;
  if (my $v = $self->values->{$token->{lexeme}}) {
    return $v;
  }
  if ($self->enclosing) {
    return $self->enclosing->get($token);
  }
  die sprintf 'Undefined variable "%s".', $token->{lexeme};
}

sub assign {
  my ($self, $token, $value) = @_;
  if (exists $self->values->{$token->{lexeme}}) {
    $self->values->{$token->{lexeme}} = $value;
    return;
  }

  if ($self->enclosing) {
    return $self->enclosing->assign($token, $value);
  }
  die sprintf 'Undefined variable "%s".', $token->{lexeme};
}

1;
