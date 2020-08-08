#!perl
use strict;
use warnings;
use Test::More;
use Path::Tiny 'path';

my $LOX_PATH = 'lox';
my $TEST_PATH = 'test';

my @UNSUPPORTED = qw(
  benchmark/
  expressions/
  limit/
  operator/equals_method.lox
  regression/394.lox
  scanning/
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
  #warn "testing $filepath\n";
  open my $fh, '<', $filepath or die "Couldn't open $filepath $!";
  my $expected = '';
  my $test_content = '';
  while (my $line = <$fh>) {
    $test_content .= $line;
    $expected .= $1 if $line =~ qr{// expect: (.+)$}s;
  }
  my $output = join '', `./$LOX_PATH $filepath`;
  my $result = is($output, $expected, "Got expected output for $filepath");
  #warn "$filepath\n" unless $expected;
  unless ($result) {
    print "TEST BEGIN\n${test_content}TEST END\n";
    exit 1;
  }
}
