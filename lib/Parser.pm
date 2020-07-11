package Parser;
use Moose;
use Stmt;
use TokenType;

has tokens => (
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 1,
);

has errors => (
  is       => 'rw',
  isa      => 'ArrayRef',
  default  => sub { [] },
);

has current => (
  is      => 'rw',
  isa     => 'Int',
  default => 0,
  traits  => ['Counter'],
  handles => {
    inc_current => 'inc',
  },
);

sub parse {
  my $self = shift;
  my @statements;
  while (!$self->is_at_end) {
    push @statements, $self->statement;
  }
  return \@statements;
}

sub statement {
  my $self = shift;
  if ($self->match(PRINT)) {
    return $self->print_statement;
  }
  return $self->expression_statement;
}

sub expression_statement {
  my $self = shift;
  my $value = $self->expression;
  $self->consume(SEMICOLON, 'Expect newline after value.');
  return Stmt::Expression->new(expression => $value);
}

sub print_statement {
  my $self = shift;
  my $value = $self->expression;
  $self->consume(SEMICOLON, 'Expect newline after value.');
  return Stmt::Print->new(expression => $value);
}

sub expression { shift->equality }

sub equality {
  my $self = shift;
  my $expr = $self->comparison;
  while ($self->match(BANG_EQUAL, EQUAL_EQUAL)) {
    $expr = Expr::Binary->new({
        left     => $expr,
        operator => $self->previous,
        right    => $self->comparison,
    });
  }
  return $expr;
}

sub comparison {
  my $self = shift;
  my $expr = $self->addition;
  while ($self->match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL)) {
    $expr = Expr::Binary->new({
        left     => $expr,
        operator => $self->previous,
        right    => $self->addition,
    });
  }
  return $expr;
}

sub addition {
  my $self = shift;
  my $expr = $self->multiplication;
  while ($self->match(MINUS, PLUS)) {
    $expr = Expr::Binary->new({
        left     => $expr,
        operator => $self->previous,
        right    => $self->multiplication,
    });
  }
  return $expr;
}

sub multiplication {
  my $self = shift;
  my $expr = $self->unary;
  while ($self->match(SLASH, STAR)) {
    $expr = Expr::Binary->new({
        left     => $expr,
        operator => $self->previous,
        right    => $self->unary,
    });
  }
  return $expr;
}

sub unary {
  my $self = shift;
  my $expr = $self->primary;
  while ($self->match(METHOD)) {
    $expr = Expr::Unary->new({
        left   => $expr,
        method => $self->previous,
    });
  }
  return $expr;
}

sub primary {
  my $self = shift;
  if ($self->match(FALSE)) {
    return Expr::Literal->new(value => undef);
  }
  elsif ($self->match(TRUE)) {
    return Expr::Literal->new(value => 1);
  }
  elsif ($self->match(NIL)) {
    return Expr::Literal->new(value => undef);
  }
  elsif ($self->match(NUMBER, STRING)) {
    return Expr::Literal->new(value => $self->previous->{literal});
  }
  elsif ($self->match(LEFT_PAREN)) {
    my $expr = $self->expression;
    $self->consume(RIGHT_PAREN, 'Expect ")" after expression.');
    return Expr::Grouping->new(expression => $expr);
  }
  $self->error($self->peek, 'expect expression');
}

sub match {
  my ($self, @types) = @_;
  for my $t (@types) {
    if ($self->check($t)) {
      $self->advance;
      return 1;
    }
  }
  return undef;
}

sub consume {
  my ($self, $type, $msg) = @_;
  return $self->advance if $self->check($type);
  $self->error($self->peek, $msg);
}

sub check {
  my ($self, $type) = @_;
  return $self->is_at_end ? undef : $self->peek->{type} == $type;
}

sub advance {
  my $self = shift;
  $self->inc_current unless $self->is_at_end;
  return $self->previous;
}

sub is_at_end { shift->peek->{type} == EOF }

sub peek {
  my $self = shift;
  return $self->tokens->[ $self->current ];
}

sub previous {
  my $self = shift;
  return $self->tokens->[ $self->current - 1];
}

sub error {
  my ($self, $token, $msg) = @_;
  push $self->errors->@*, [$token, $msg];
  die $msg;
}

1;
