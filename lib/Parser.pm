package Parser;
use Moose;
use Expr;
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
    push @statements, $self->declaration;
  }
  return \@statements;
}

sub declaration {
  my $self = shift;
  my $dec = eval {
    $self->match(VAR) ? $self->var_declaration : $self->statement;
  };
  unless ($@) {
    return $dec;
  }
  warn $@;
  $self->synchronize;
  return undef;
}

sub statement {
  my $self = shift;
  if ($self->match(PRINT)) {
    return $self->print_statement;
  }
  if ($self->match(LEFT_BRACE)) {
    return Stmt::Block->new({statements => $self->block});
  }
  return $self->expression_statement;
}

sub var_declaration {
  my $self = shift;
  my $name = $self->consume(IDENTIFIER, "Expect variable name.");
  my $init = undef;
  if ($self->match(EQUAL)) {
    $init = $self->expression;
  }
  $self->consume(SEMICOLON, 'Expect ";" after variable declaration.');
  return Stmt::Var->new({name => $name, initializer => $init});
}

sub expression_statement {
  my $self = shift;
  my $value = $self->expression;
  $self->consume(SEMICOLON, 'Expect ";" after value.');
  return Stmt::Expression->new(expression => $value);
}

sub block {
  my $self = shift;
  my @statements;
  while (!$self->check(RIGHT_BRACE) && !$self->is_at_end) {
    push @statements, $self->declaration;
  }
  $self->consume(RIGHT_BRACE, "Expect '}' after block.");
  return \@statements;
}

sub print_statement {
  my $self = shift;
  my $value = $self->expression;
  $self->consume(SEMICOLON, 'Expect ";" after value.');
  return Stmt::Print->new(expression => $value);
}

sub assignment {
  my $self = shift;
  my $expr = $self->equality;
  if ($self->match(EQUAL)) {
    my $equals = $self->previous;
    my $value = $self->assignment;
    if ($expr->isa('Expr::Variable')) {
      return Expr::Assign->new({name => $expr->name, value => $value});
    }
    $self->error($equals, 'Invalid assignment target');
  }
  return $expr;
}

sub expression { shift->assignment }

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
  if ($self->match(BANG, MINUS)) {
    my $expr = Expr::Unary->new({
        operator => $self->previous,
        right    => $self->unary,
    });
    return $expr;
  }
  return $self->primary;
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
  elsif ($self->match(IDENTIFIER)) {
    return Expr::Variable->new(name => $self->previous);
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

sub synchronize {
  my $self = shift;
  $self->advance;
  while (!$self->is_at_end) {
    return if $self->previous->{type} == SEMICOLON;
    my $next = $self->peek;
    return if grep { $next == $_ } CLASS,FUN,VAR,FOR,IF,WHILE,PRINT,RETURN;
    $self->advance;
  }
}

1;
