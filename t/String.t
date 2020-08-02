#!perl
use strict;
use warnings;
use Test::More;
use String;

ok my $str = String->new('foo'), 'construct a new String obj';
is "$str", 'foo', 'stringifies to "foo"';
ok $str && 1, 'String is truthy';
cmp_ok 'foo', 'eq', $str, 'stringifies to eq';
is $str . 'bar', 'foobar', 'stringifies for concat';
cmp_ok(String->new('foo'), 'eq', $str, 'String(foo) eq String(foo)');
cmp_ok(String->new('bar'), 'ne', $str, 'String(bar) ne String(foo)');

done_testing;
