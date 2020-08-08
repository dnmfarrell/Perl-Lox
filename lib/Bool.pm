use strict;
use warnings;
package True;
use overload
  '""' => sub { 'true' },
  '!'  => sub { $False::False },
  'bool' => sub { 1 },
  fallback => 0;

our $True = bless {}, 'True';
our $VERSION = 0.01;

package False;
use overload
  '""' => sub { 'false' },
  '!'  => sub { $True::True },
  'bool' => sub { undef },
  fallback => 0;

our $False = bless {}, 'False';
our $VERSION = 0.01;

package Bool;
use Exporter 'import';
our $True = $True::True;
our $False = $False::False;
our @EXPORT = qw($True $False);
our $VERSION = 0.01;

1;
