package Interpreter;
use feature 'say';
use strict;
use warnings;
use Callable;
use Environment;
use Function;
use TokenType;
use Scalar::Util 'looks_like_number';

sub new {
  my ($class, $args) = @_;
  my $interpreter = bless {
    environment => Environment->new({}),
    globals     => Environment->new({}),
    locals      => {},
    %$args,
  }, $class;
  $interpreter->globals->define('clock', Callable->new({
    arity => 0,
    call  => sub { time },
  }));

  return $interpreter;
}

sub environment :lvalue { $_[0]->{environment} }
sub globals { $_[0]->{environment} }
sub locals { $_[0]->{locals} }

sub interpret {
  my ($self, $stmts) = @_;
  eval {
    for (@$stmts) {
      $self->execute($_);
    }
  };
  if ($@) {
    warn $@;
  }
}

sub execute {
  my ($self, $stmt) = @_;
  $stmt->accept($self) unless $self->{breaking};
}

sub resolve {
  my ($self, $expr, $depth) = @_;
  $self->locals->{"$expr"} = { expr=>$expr, distance=>$depth, accessed=>0 };
}

sub visit_break_stmt {
  my ($self, $stmt) = @_;
  $self->{breaking}++;
  return undef;
}

sub visit_expression_stmt {
  my ($self, $stmt) = @_;
  $self->evaluate($stmt->expression);
  return undef;
}

sub visit_if_stmt {
  my ($self, $stmt) = @_;
  if ($self->is_truthy($self->evaluate($stmt->condition))) {
    $self->execute($stmt->then_branch);
  }
  elsif ($stmt->else_branch) {
    $self->execute($stmt->else_branch);
  }
}

sub visit_function_stmt {
  my ($self, $stmt) = @_;
  my $function = Function->new({
    declaration => $stmt,
    environment => $self->environment,
  });
  $self->environment->define($stmt->name->lexeme, $function);
  return undef;
}

sub visit_function {
  my ($self, $expr) = @_;
  return Function->new({
    declaration => $expr,
    environment => $self->environment,
  });
}

sub visit_logical {
  my ($self, $expr) = @_;
  my $left = $self->evaluate($expr->left);
  if ($expr->operator->type == OR) {
    return $left if $self->is_truthy($left);
  }
  else {
    return $left if !$self->is_truthy($left);
  }

  return $self->evaluate($expr->right);
}

sub visit_print_stmt {
  my ($self, $stmt) = @_;
  my $value = $self->evaluate($stmt->expression);
  say $self->stringify($value);
  return undef;
}

sub visit_return_stmt {
  my ($self, $stmt) = @_;
  if ($stmt->value) {
    $self->{returning} = $self->evaluate($stmt->value);
    die "return\n";
  }
  return undef;
}

sub visit_var_stmt {
  my ($self, $stmt) = @_;
  my $value = undef;
  if ($stmt->initializer) {
    $value = $self->evaluate($stmt->initializer);
  }
  $self->environment->define($stmt->name->{lexeme}, $value);
  return undef;
}

sub visit_while_stmt {
  my ($self, $stmt) = @_;
  while ($self->is_truthy($self->evaluate($stmt->condition))) {
    $self->execute($stmt->body);
    last if $self->{breaking};
  }
  return undef $self->{breaking};
}

sub visit_block_stmt {
  my ($self, $stmt) = @_;
  $self->execute_block(
    $stmt->statements,
    Environment->new({enclosing => $self->environment }));;

  return undef;
}

sub execute_block {
  my ($self, $statements, $environment) = @_;
  my $prev_environment = $self->environment;
  eval {
    $self->environment = $environment;
    for my $stmt (@$statements) {
      $self->execute($stmt);
    }
  };
  $self->environment = $prev_environment;
  return delete $self->{returning};
}

sub visit_literal {
  my ($self, $expr) = @_;
  return $expr->value;
}

sub visit_call {
  my ($self, $expr) = @_;
  my $callee = $self->evaluate($expr->callee);
  my @args;
  for my $arg ($expr->arguments->@*) {
    push @args, $self->evaluate($arg);
  }
  unless (ref $callee && $callee->isa('Callable')) {
    die "Can only call functions and classes.";
  }

  if (@args!= $callee->arity) {
    die sprintf 'Expected %d arguments but got %s',$callee->arity,scalar @args;
  }
  return $callee->call($self, \@args);
}

sub visit_grouping {
  my ($self, $expr) = @_;
  return $self->evaluate($expr->expression);
}

sub visit_unary {
  my ($self, $expr) = @_;
  my $right = $self->evaluate($expr->right);

  if ($expr->operator->{type} == MINUS) {
    return -$right;
  }
  else {
    return !$self->is_truthy($right);
  }
}

sub visit_assign {
  my ($self, $expr) = @_;
  my $value = $self->evaluate($expr->value);
  my $distance = $self->look_up_variable_local($expr);
  if (defined $distance) {
    $self->environment->assign_at($distance, $expr->name, $value);
  }
  else {
    $self->globals->assign($expr->name, $value);
  }
  return $value;
}

sub visit_variable {
  my ($self, $expr) = @_;
  return $self->look_up_variable($expr->name, $expr);
}

sub look_up_variable_local {
  my ($self, $expr) = @_;
  my $local = $self->locals->{"$expr"};
  if ($local) {
    $local->{accessed}++;
    return $local->{distance};
  }
  return undef;
}

sub look_up_variable {
  my ($self, $name, $expr) = @_;
  my $distance = $self->resolve_local($expr);
  return $distance
    ? $self->environment->get_at($distance, $name->lexeme)
    : $self->globals->get($name);
}

sub visit_binary {
  my ($self, $expr) = @_;
  my $left = $self->evaluate($expr->left);
  my $right = $self->evaluate($expr->right);

  my $type = $expr->operator->{type};
  if ($type == BANG) {
    return $self->are_equal($expr->left, $expr->right);
  }
  elsif ($type == BANG_EQUAL) {
    return !$self->are_equal($expr->left, $expr->right);
  }
  elsif ($type == GREATER) {
    return $left > $right;
  }
  elsif ($type == GREATER_EQUAL) {
    return $left >= $right;
  }
  elsif ($type == LESS) {
    return $left < $right;
  }
  elsif ($type == LESS_EQUAL) {
    return $left <= $right;
  }
  elsif ($type == PLUS) {
    return $left + $right;
  }
  elsif ($type == SLASH) {
    return $left / $right;
  }
  elsif ($type == STAR) {
    return $left * $right;
  }
}

sub evaluate {
  my ($self, $expr) = @_;
  return $expr->accept($self);
}

sub is_truthy {
  my ($self, $value) = @_;
  return $value ? 1 : 0;
}

sub are_equal {
  my ($self, $left, $right) = @_;
  if (!defined $left) {
    return !defined $right;
  }
  elsif (looks_like_number($left) && looks_like_number($right)) {
    return $left == $right;
  }
  else {
    return $left eq $right;
  }
}

sub stringify {
  my ($self, $object) = @_;
  return defined $object ? "$object" : 'nil';
}

1;
