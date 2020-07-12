use strict;
use warnings;

package Expr;
use Moose;

package Expr::Variable;
use Moose;
extends 'Expr';
has name => (is => 'ro', isa => 'Token', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_variable($self);
}

package Expr::Unary;
use Moose;
extends 'Expr';
has operator => (is => 'ro', isa => 'Token', required => 1);
has right => (is => 'ro', isa => 'Expr', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_unary($self);
}

package Expr::Assign;
use Moose;
extends 'Expr';
has name => (is => 'ro', isa => 'Token', required => 1);
has value => (is => 'ro', isa => 'Expr', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_assign($self);
}

package Expr::Binary;
use Moose;
extends 'Expr';
has left => (is => 'ro', isa => 'Expr', required => 1);
has operator => (is => 'ro', isa => 'Token', required => 1);
has right => (is => 'ro', isa => 'Expr', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_binary($self);
}

package Expr::Grouping;
use Moose;
extends 'Expr';
has expression => (is => 'ro', isa => 'Expr', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_grouping($self);
}

package Expr::Literal;
use Moose;
extends 'Expr';
has value => (is => 'ro', isa => 'Value', required => 1);

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_literal($self);
}

1;
