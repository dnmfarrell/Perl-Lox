use strict;
use warnings;
package True;
use overload
  '""' => sub { 'true' },
  '!'  => sub { False->new },
  'bool' => sub { 1 },
  fallback => 0;

sub new { bless {}, shift }

package False;
use overload
  '""' => sub { 'false' },
  '!'  => sub { True->new },
  'bool' => sub { undef },
  fallback => 0;

sub new { bless {}, shift }

1;
