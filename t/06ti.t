#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI ();
use ADOTEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 4;
} else {
  plan skip_all => 'Cannot test without DB info';
}

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh,'Connection');


my $sth;

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
