#!perl -I./t

$| = 1;

use strict;
use warnings;
use Win32::OLE();
use DBI();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 5;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Beginning test, modules loaded');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

my $Cxn = $dbh->{ado_conn};

ok( $Cxn,"ADO Connection object: $Cxn");

print "\n  Connection properties:\n";
printf "    %-20s %s\n", $_, $Cxn->{$_} ||'undef'
  for sort keys %$Cxn;

my $Properties = $Cxn->Properties;

ok( $Properties,"ADO Connection Properties Collection: $Properties");

print "\n  Connection Properties Collection:\n";
printf "    %-45s %s\n", $_->Name, $_->Value ||'undef'
  for sort { $a->Name cmp $b->Name } Win32::OLE::in( $Properties );

$dbh->disconnect;
pass('disconnect');
