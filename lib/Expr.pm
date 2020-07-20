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
  return $visitor->visit_variable($self);
}

package Expr::Unary;
use parent -norequire, 'Expr';
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_unary($self);
}

package Expr::Assign;
use parent -norequire, 'Expr';
sub name { $_[0]->{name} }
sub value { $_[0]->{value} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_assign($self);
}

package Expr::Binary;
use parent -norequire, 'Expr';
sub left { $_[0]->{left} }
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_binary($self);
}

package Expr::Call;
use parent -norequire, 'Expr';
sub arguments { $_[0]->{arguments} }
sub callee { $_[0]->{callee} }
sub paren { $_[0]->{paren} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_call($self);
}

package Expr::Grouping;
use parent -norequire, 'Expr';
sub expression { $_[0]->{expression} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_grouping($self);
}

package Expr::Literal;
use parent -norequire, 'Expr';
sub value { $_[0]->{value} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_literal($self);
}

package Expr::Logical;
use parent -norequire, 'Expr';
sub left { $_[0]->{left} }
sub operator { $_[0]->{operator} }
sub right { $_[0]->{right} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_logical($self);
}

1;
