package TokenType;
use strict;
use warnings;
use Exporter 'import';

my @tokens = qw(
  BLOCK_BEGIN
  BLOCK_END
  CLASS
  INTEGER
  FLOAT
  STMNT_END
  STRING
  WORD
);
require enum;
enum->import(@tokens);
our @EXPORT = (@tokens, 'type');

sub type {
  $tokens[shift]
}

1;
