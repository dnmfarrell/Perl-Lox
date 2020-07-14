package AstPrinter;
use strict;
use warnings;

sub new { bless {}, shift }

sub print_tree {
  my ($self, $stmts) = @_;
  return join "\n", grep { /\S/ } split "\n", $self->parenthesize(@$stmts);
}

sub visit_expression_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize($stmt->expression);
}

sub visit_print_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize('print', $stmt->expression);
}

sub visit_var_stmt {
  my ($self, $stmt) = @_;
  my @expressions;
  push @expressions, $stmt->initializer if $stmt->initializer;
  return $self->parenthesize($stmt->name, '=', @expressions);
}

sub visit_block_stmt {
  my ($self, $stmt) = @_;
  return $self->parenthesize($stmt->statements->@*);
}

sub visit_unary {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->operator,$expr->right);
}

sub visit_binary {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->left,$expr->operator,$expr->right);
}

sub visit_assign {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->name,'=',$expr->value);
}

sub visit_variable {
  my ($self, $expr) = @_;
  return $expr->name->lexeme;
}

sub visit_grouping {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->expression);
}

sub visit_literal {
  my ($self, $expr) = @_;
  return defined $expr ? $expr->value : 'nil';
}

sub visit_token {
  my ($self, $token) = @_;
  return $token->lexeme;
}

my $column = 0;
sub parenthesize {
  my ($self, @expr) = @_;
  my $indent =  ' ' x $column // '';
  $column += 2;
  my $values = join ' ', map { ref $_ ? $_->accept($self) : $_ } @expr;
  my $parenthesized = "\n$indent(\n$indent $values\n$indent)";
  $column -= 2;
  return $parenthesized;
}

1;
