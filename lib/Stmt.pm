use strict;
use warnings;

package Stmt;
sub new {
  my ($class, $args) = @_;
  return bless { %$args }, $class;
}

package Stmt::Block;
use parent -norequire, 'Stmt';
sub statements { $_[0]->{statements} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_block_stmt($self);
}

package Stmt::Expression;
use parent -norequire, 'Stmt';
sub expression { $_[0]->{expression} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_expression_stmt($self);
}

package Stmt::Print;
use parent -norequire, 'Stmt';
sub expression { $_[0]->{expression} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_print_stmt($self);
}

package Stmt::Var;
use parent -norequire, 'Stmt';
sub name { $_[0]->{name} }
sub initializer { $_[0]->{initializer} }

sub accept {
  my ($self, $visitor) = @_;
  return $visitor->visit_var_stmt($self);
}

1;
