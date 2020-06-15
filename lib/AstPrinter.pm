package AstPrinter;
use strict;
use warnings;
use Moo;
use Expr;
use Token;
use TokenType;

sub print_expr {
  my ($self, $expr) = @_;
  return $expr->accept($self);
}

sub visit_unary {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->method->{lexeme},$expr->left);
}

sub visit_binary {
  my ($self, $expr) = @_;
  return $self->parenthesize($expr->operator->{lexeme},$expr->left,$expr->right);
}

sub visit_grouping {
  my ($self, $expr) = @_;
  return $self->parenthesize('group',$expr->expression);
}

sub visit_literal {
  my ($self, $expr) = @_;
  return defined $expr ? $expr->value : 'nil';
}

sub parenthesize {
  my ($self, $name, @expr) = @_;
  my $expr_string = join ' ', $name, map { $_->accept($self) } @expr;
  return "($expr_string)";
}

1;
