#!perl -I./t
# vim:ts=2:sw=2:ai:aw:nu:

$| = 1;

use strict;
use warnings;
use DBI ();
use ADOTEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 6;
} else {
  plan skip_all => 'Cannot test without DB info';
}

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh,'Connection');

# Test the different methods, so are expected to fail.

# XXX

my $sth;

eval {
  ok( $dbh->ping,'Testing Ping');
};
ok ( !$@,'Ping Tested');

eval {
  $sth = $dbh->type_info_all;
};
ok ( ( !$@ and defined $sth ),'type_info_all tested');
$sth = undef;

eval {
  my @types = $dbh->type_info;
  die unless @types;
};
ok ( !$@,'type_info( undef )');
$sth = undef;

ok( $dbh->disconnect,'Disconnect');
