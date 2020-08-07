use strict;
use warnings;
package Expr;

sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

package Expr::Variable;
use parent -norequire, 'Expr';

sub name { $_[0]->{name} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_variable_expr($self);
}

package Expr::Unary;
use parent -norequire, 'Expr';
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_unary_expr($self);
}

package Expr::Assign;
use parent -norequire, 'Expr';
sub name { $_[0]->{name} }
sub value { $_[0]->{value} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_assign_expr($self);
}

package Expr::Binary;
use parent -norequire, 'Expr';
sub left { $_[0]->{left} }
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_binary_expr($self);
}

package Expr::Call;
use parent -norequire, 'Expr';
sub arguments { $_[0]->{arguments} }
sub callee { $_[0]->{callee} }
sub paren { $_[0]->{paren} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_call_expr($self);
}

package Expr::Function;
use parent -norequire, 'Expr';
sub params { $_[0]->{params} }
sub body   { $_[0]->{body} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_function_expr($self);
}

package Expr::Grouping;
use parent -norequire, 'Expr';
sub expression { $_[0]->{expression} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_grouping_expr($self);
}

package Expr::Literal;
use parent -norequire, 'Expr';
sub value { $_[0]->{value} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_literal_expr($self);
}

package Expr::Logical;
use parent -norequire, 'Expr';
sub left { $_[0]->{left} }
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_logical_expr($self);
}

1;
