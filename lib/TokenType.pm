package TokenType;
use strict;
use warnings;
use Exporter 'import';

my @tokens = qw(
  BANG
  BANG_EQUAL
  BLOCK_BEGIN
  BLOCK_END
  CLASS
  EOF
  EQUAL
  EQUAL_EQUAL
  ERROR
  FALSE
  FLOAT
  GREATER
  GREATER_EQUAL
  IDENTIFIER
  INTEGER
  LEFT_PAREN
  LESS
  LESS_EQUAL
  METHOD
  MINUS
  NIL
  PLUS
  PRINT
  RIGHT_PAREN
  SLASH
  STAR
  STMNT_END
  STRING
  TRUE
);

require enum;
enum->import(@tokens);
our @EXPORT = (@tokens, 'type');

sub type { $tokens[shift] }

1;
