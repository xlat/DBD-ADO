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


my $tia = $dbh->type_info_all;
is( ref $tia,'ARRAY','type_info_all');

my @ti = $dbh->type_info;
ok( @ti,'type_info');
for my $ti ( @ti ) {
  print  "#\n";
  printf "# %-20s => %s\n", $_, DBI::neat( $ti->{$_} ) for sort keys %$ti;
}

ok( $dbh->disconnect,'Disconnect');
