#!perl
use strict;
use warnings;
use Test::More;
use Bool;

is ref $True, 'True', 'Get the True singleton';
is "$True", 'true', 'stringifies to "true"';
ok $True && 1, 'True is truthy';
ok ref !$True eq 'False', 'True negates to False';

is ref $False, 'False', 'Get the False singleton';
is "$False", 'false', 'stringifies to "false"';
ok $False || 1, 'False is falsey';
ok ref !$False eq 'True', 'False negates to True';

done_testing;
