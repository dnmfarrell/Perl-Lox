use strict;
use warnings;

package Stmt;
use Moose;

package Stmt::Block;
use Moose;
extends 'Stmt';
has statements => (is => 'ro', isa => 'ArrayRef', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_block_stmt($self);
}

package Stmt::Expression;
use Moose;
extends 'Stmt';
has expression => (is => 'ro', isa => 'Expr', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_expression_stmt($self);
}

package Stmt::Print;
use Moose;
extends 'Stmt';
has expression => (is => 'ro', isa => 'Expr', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_print_stmt($self);
}

package Stmt::Var;
use Moose;
extends 'Stmt';
has name => (is => 'ro', isa => 'Token', required => 1);
has initializer => (is => 'ro', isa => 'Expr', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_var_stmt($self);
}

1;
