package Interpreter;
use feature 'say';
use strict;
use warnings;
use Bool;
use Callable;
use Environment;
use Function;
use Nil;
use TokenType;
use Scalar::Util 'looks_like_number';

sub new {
  my ($class, $args) = @_;
  my $globals = Environment->new({});
  my $interpreter = bless {
    environment => $globals,
    globals     => $globals,
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
sub globals { $_[0]->{globals} }
sub locals { $_[0]->{locals} }

sub interpret {
  my ($self, $stmts) = @_;
  for (@$stmts) {
    $self->execute($_);
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
    closure => $self->environment,
  });
  $self->environment->define($stmt->name->lexeme, $function);
  return undef;
}

sub visit_function {
  my ($self, $expr) = @_;
  return Function->new({
    declaration => $expr,
    closure => $self->environment,
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
  }
  die "return\n";
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
    Environment->new({ enclosing => $self->environment }));

  return undef;
}

sub execute_block {
  my ($self, $statements, $environment) = @_;
  my $prev_environment = $self->environment;
  $self->environment = $environment;
  my $error;
  for my $stmt (@$statements) {
    eval { $self->execute($stmt) }; # so we can reset the env
    if ($error = $@) {
      last;
    }
  }
  $self->environment = $prev_environment;
  die $error if $error;
  return undef;
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
    die 'Can only call functions and classes';
  }

  if (@args!= $callee->arity) {
    die sprintf 'Expected %d arguments but got %s',$callee->arity,scalar @args;
  }
  return $callee->call($self, \@args) // Nil->new;
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
    return !($self->is_truthy($right) ? True->new : False->new);
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
  return $self->look_up_variable($expr);
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
  my ($self, $expr) = @_;
  my $distance = $self->look_up_variable_local($expr);
  return defined $distance
    ? $self->environment->get_at($distance, $expr->name)
    : $self->globals->get($expr->name);
}

sub visit_binary {
  my ($self, $expr) = @_;
  my $left = $self->evaluate($expr->left);
  my $right = $self->evaluate($expr->right);

  my $type = $expr->operator->{type};
  if ($type == EQUAL_EQUAL) {
    return $self->are_equal($left, $right) ? True->new : False->new;
  }
  elsif ($type == BANG_EQUAL) {
    return !$self->are_equal($left, $right) ? True->new : False->new;
  }
  elsif ($type == GREATER) {
    return $left > $right ? True->new : False->new;
  }
  elsif ($type == GREATER_EQUAL) {
    return $left >= $right ? True->new : False->new;
  }
  elsif ($type == LESS) {
    return $left < $right ? True->new : False->new;
  }
  elsif ($type == LESS_EQUAL) {
    return $left <= $right ? True->new : False->new;
  }
  elsif ($type == MINUS) {
    return $left - $right;
  }
  elsif ($type == PLUS) {
    if (ref $left || ref $right) {
      if (ref $left eq ref $right) {
        if (ref $left eq 'String') {
          return String->new($left . $right);
        }
      }
      Lox::runtime_error(
        $expr->operator, 'Operands must be two numbers or two strings');
    }
    return $left + $right; # Lox numbers are the only non-object values
  }
  elsif ($type == SLASH) {
    return $left / $right if $right;
    return 'NaN';
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
  return !!$value if ref $value;
  return 1;
}

sub are_equal {
  my ($self, $left, $right) = @_;
  if (my $ltype = ref $left) {
    if ($ltype eq ref $right) {
      if ($ltype eq 'String') {
        return $left eq $right;
      }
      elsif ($left->isa('Callable')) {
        return $left eq $right; # does each reference point to the same thing
      }
      else {
        return 1; # Nil, True, False
      }
    }
    return undef;
  }
  elsif (ref $right) {
    return undef;
  }
  else {
    return $left == $right;
  }
}

sub stringify {
  my ($self, $object) = @_;
  return "$object";
}

1;
