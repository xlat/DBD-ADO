#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:ai:aw:nu

$| = 1;

use strict;
use ADOTEST();

use Test::More tests => 23;

BEGIN { use_ok('DBD::ADO') }

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh, 'Connection');

{
  ok( ADOTEST::tab_create($dbh), "Create the test table $ADOTEST::table_name" );
}
# TODO: handle catalog and schema ($ADOTEST::table_name may exist in more then one schema)
{
  my $sth = $dbh->column_info( undef, undef, $ADOTEST::table_name, 'B');
  ok( defined $sth, 'Statement handle defined');

  my $row = $sth->fetch;
  is( $row->[ 2], $ADOTEST::table_name, "Is this table name $ADOTEST::table_name?");
  is( $row->[ 3], 'B'                 , 'Is this column name B?');
}
{
  my $sth = $dbh->column_info( undef, undef, $ADOTEST::table_name );
  ok( defined $sth, 'Statement handle defined');

  my @ColNames = sort keys %ADOTEST::TestFieldInfo;
  print "-- Columns:\n";
  my $i = 0;
  while ( my $row = $sth->fetch )
  {
    $i++;
    {
      local $^W = 0; local $,  = ":"; print '-- ', @$row, "\n";
    }
    is( $row->[ 2], $ADOTEST::table_name, "Is this table name $ADOTEST::table_name?");
    is( $row->[16], $i                  , "Is this ordinal position $i?");
    is( $row->[ 3], $ColNames[$i-1]     , "Is this column name $ColNames[$i-1]?");
    my @ti = ADOTEST::get_type_for_column($dbh, $row->[3]);
    my $ti = shift @ti;
#   is( $row->[ 4] , $ti->{DATA_TYPE}   , "Is this data type $ti->{DATA_TYPE}?");
    is( $row->[ 5] , $ti->{TYPE_NAME}   , "Is this type name $ti->{TYPE_NAME}?");
  }
}

$dbh->disconnect;

exit;

END { }
