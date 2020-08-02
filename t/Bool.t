#!perl
use strict;
use warnings;
use Test::More;
use Bool;

ok ref(my $true = True->new), 'construct a new True obj';
is "$true", 'true', 'stringifies to "true"';
ok $true && 1, 'True is truthy';
ok ref !$true eq 'False', 'True negates to False';

ok ref(my $false = False->new), 'construct a new False obj';
is "$false", 'false', 'stringifies to "false"';
ok $false || 1, 'false is falsey';
ok ref !$false eq 'True', 'False negates to True';

done_testing;
