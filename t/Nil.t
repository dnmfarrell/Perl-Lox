#!perl
use strict;
use warnings;
use Test::More;
use Nil;

ok ref(my $nil = Nil->new), 'construct a new Nil obj';
is "$nil", 'nil', 'stringifies to "nil"';
ok $nil || 1, 'nil is falsey';
done_testing;
