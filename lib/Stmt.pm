use strict;
use warnings;

package Stmt;
use Moose;

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

1;
