package TokenType;
use strict;
use warnings;
use Exporter 'import';

my @tokens = qw(
  LEFT_PAREN RIGHT_PAREN LEFT_BRACE RIGHT_BRACE
  COMMA DOT MINUS PLUS SEMICOLON SLASH STAR

  BANG BANG_EQUAL
  EQUAL EQUAL_EQUAL
  GREATER GREATER_EQUAL
  LESS LESS_EQUAL

  IDENTIFIER STRING NUMBER

  AND BREAK CLASS ELSE FALSE FUN FOR IF NIL OR
  PRINT RETURN SUPER THIS TRUE VAR WHILE

  ERROR
  EOF
);

require enum;
enum->import(@tokens);
our @EXPORT = (@tokens, 'type');

sub type { $tokens[shift] }

1;
