#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:ai:aw:nu

$| = 1;

use strict;
use ADOTEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
	plan tests => 10;
} else {
	plan skip_all => 'Cannot test without DB info';
}

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh, 'Connection');

{
	ok( ADOTEST::tab_create($dbh), "Create the test table $ADOTEST::table_name" );
}
{
  my $sth = $dbh->table_info( undef, undef, undef, 'TABLE');
  ok( defined $sth, 'Statement handle defined');

  my $row = $sth->fetch;
  is( $row->[3], 'TABLE', 'Fetched a TABLE?');
}
{
  my $sth = $dbh->table_info( undef, undef, $ADOTEST::table_name, 'TABLE');
  ok( defined $sth, 'Statement handle defined');

  my $row = $sth->fetch;
  is( $row->[2], $ADOTEST::table_name, "Is this $ADOTEST::table_name?");
  is( $row->[3], 'TABLE', "Is $ADOTEST::table_name a TABLE?");
}
{
  my $sth = $dbh->table_info( undef, undef, $ADOTEST::table_name, 'VIEW');
  ok( defined $sth, 'Statement handle defined');

  my $row = $sth->fetch;
  ok( !defined $row, "$ADOTEST::table_name isn't a VIEW!");
}
=for todo
{
  my $sth = $dbh->table_info('%');
  ok( defined $sth, 'Statement handle defined');

  print "Catalogs:\n";
  while ( my $row = $sth->fetch )
  {
    local $^W = 0;
    local $,  = "\t";
    print @$row, "\n";
  }
}
{
  my $sth = $dbh->table_info( undef, '%');
  ok( defined $sth, 'Statement handle defined');

  print "Schemata:\n";
  while ( my $row = $sth->fetch )
  {
    local $^W = 0;
    local $,  = "\t";
    print @$row, "\n";
  }
}
{
  my $sth = $dbh->table_info( undef, undef, undef, '%');
  ok( defined $sth, 'Statement handle defined');

  print "Table types:\n";
  while ( my $row = $sth->fetch )
  {
    local $^W = 0;
    local $,  = "\t";
    print @$row, "\n";
  }
}
=cut

ok(!$dbh->disconnect, "Disconnect");

exit;

END { }
