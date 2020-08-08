package Nil;
use strict;
use warnings;
use Bool;
use overload
  '""' => sub { 'nil' },
  '!'  => sub { $True },
  'bool' => sub { $False },
  fallback => 1;

use Exporter 'import';
my $u = undef;
our $Nil = bless \$u, 'Nil';
our @EXPORT = qw($Nil);
our $VERSION = 0.01;

1;
