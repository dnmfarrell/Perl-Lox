#!perl
use strict;
use warnings;
use Test::More;
use Path::Tiny 'path';

my $LOX_PATH = 'bin/plox';
my $TEST_PATH = 'test';

my @UNSUPPORTED = (
  'operator/equals_method.lox', # I'm not sure why this behavior is desirable
  'benchmark/', # take forever to run
);

my $iter = path($TEST_PATH)->iterator({ recurse => 1 });
while (my $p = $iter->()) {
  next unless $p =~ /\.lox$/;
  next if grep { $p =~ m($_) } @UNSUPPORTED;
  test_file($p->stringify);
}

done_testing;

sub test_file {
  my $filepath = shift;;
  open my $fh, '<', $filepath or die "Couldn't open $filepath $!";
  my $expected = '';
  my $test_content = '';
  while (my $line = <$fh>) {
    $test_content .= $line;
    $expected .= $1 if $line =~ qr{// expect: (.+)$}s;
  }
  my $output = join '', `$^X -Ilib $LOX_PATH $filepath`;
  my $result = is($output, $expected, "Got expected output for $filepath");
  unless ($result) {
    print "TEST BEGIN\n${test_content}TEST END\n";
    exit 1;
  }
}
