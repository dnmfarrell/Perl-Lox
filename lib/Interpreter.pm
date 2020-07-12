package Interpreter;
use feature 'say';
use strict;
use warnings;
use Environment;
use TokenType;
use Scalar::Util 'looks_like_number';

sub new {
  my ($class, $args) = @_;
  return bless {
    environment => Environment->new({}),
    %$args,
  }, $class;
}

sub environment :lvalue { $_[0]->{environment} }

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
  $stmt->accept($self);
}

sub visit_expression_stmt {
  my ($self, $stmt) = @_;
  $self->evaluate($stmt->expression);
  return undef;
}

sub visit_print_stmt {
  my ($self, $stmt) = @_;
  my $value = $self->evaluate($stmt->expression);
  say $self->stringify($value);
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
}

sub visit_literal {
  my ($self, $expr) = @_;
  return $expr->value;
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
  $self->environment->assign($expr->name, $value);
  return $value;
}

sub visit_variable {
  my ($self, $expr) = @_;
  return $self->environment->get($expr->name);
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
  return !defined $value || $value eq 'false' ? 0 : 1;
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
  return "$object";
}

1;
