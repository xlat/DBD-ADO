#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:ai:aw:nu:

$| = 1;

use strict;
use DBI qw(:sql_types);

use Data::Dumper;

use vars qw($tests);

use Test::More;

if (defined $ENV{DBI_DSN}) {
	plan tests => 18;
} else {
	plan skip_all => 'Cannot test without DB info';
}

pass( "Begining test, modules loaded" );

my $dbh = DBI->connect() or die "Connect failed: $DBI::errstr\n";
pass( "Database connection created." );

my $chck = [
	SQL_SMALLINT,SQL_TINYINT,SQL_NUMERIC,SQL_DECIMAL,SQL_FLOAT,
	SQL_REAL,SQL_DOUBLE,SQL_WVARCHAR,SQL_VARCHAR,SQL_WCHAR,SQL_CHAR,
	SQL_WLONGVARCHAR,SQL_LONGVARCHAR,SQL_DATE,SQL_TIMESTAMP
	];

foreach my $type (@$chck) {
    my @row = $dbh->type_info($type);
    # may not correct behavior, but get the first compat type
		print "Type $type rows: ", scalar(@row), "\n";
}

{

	local ($dbh->{PrintError}, $dbh->{RaiseError}, $dbh->{Warn});

	$dbh->{PrintError} = 0; $dbh->{RaiseError} = 0; $dbh->{Warn} = 0;

	$dbh->do("DROP TABLE fred");

}

ok(!$dbh->disconnect(), "Disconnect from database" );

$dbh = DBI->connect() or die "Connect failed: $DBI::errstr\n";
pass( "Database connection created." );
{
  local $dbh->{PrintError} = 0;
  local $dbh->{RaiseError} = 1;
  ok(!eval{$dbh->do( 'drop table fred' )}, "Drop table fred" );
  print $@, "\n";
}
ok($dbh->do( 'create table fred (chr char(1))' ), "Create table fred" );

my $sth;
ok( $sth = $dbh->prepare( 'select * from fred' ), "Select all from fred" );

ok( $sth->execute, "Execute select all from fred" );

ok( $sth->finish, "Finish select all from fred" );

ok( $sth = $dbh->prepare( 'select * from fred' ), "Select all from fred" );

ok( $sth->finish, "Finish select all from fred" );

ok( $sth = $dbh->prepare( 'select * from fred' ), "Select all from fred" );

ok( ! ($sth = undef), "Set sth to undefined" );

ok( $sth = $dbh->prepare( 'select * from fred' ), "Select all from fred" );

ok( $sth->execute, "Execute select all from fred" );

ok( ! ($sth = undef), "Set sth to undefined" );

ok($dbh->do( 'drop table fred' ), "Drop table fred" );

my $types = $dbh->type_info_all();

# print Dumper($types), "\n";

ok(!$dbh->disconnect(), "Disconnect from database" );
