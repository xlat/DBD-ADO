#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:aw:ai:sta:
$| = 1;

use DBI qw(:sql_types);

use ADOTEST;

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

$dbh->{PrintError} = 1;


my $rslt;


ok($rslt = $dbh->do(
	qq{INSERT INTO $ADOTEST::table_name (A, B) VALUES (?, ?)}
	, undef,
	, 1, q{Testing Insert of 1} )
, "Inserting  varchar" );

ok($rslt = $dbh->do(
	qq{INSERT INTO $ADOTEST::table_name (A, B) VALUES (?, ?)}
	, undef,
	, 1, undef )
, "Inserting NULL varchar" );

ok($rslt = $dbh->do(
	qq{INSERT INTO $ADOTEST::table_name (A, B, C) VALUES (?, ?, ?)}
	, undef,
	, 2, q{this insert a null value}, undef )
, "Inserting NULL date" );

my $sth = $dbh->prepare(
	qq{INSERT INTO $ADOTEST::table_name (A, B) VALUES (?, ?)});

ok(defined $sth, "Prepare insert statement" );

my @row;
my $n = 7; my $s = undef;
@row = ADOTEST::get_type_for_column($dbh, 'A');
ok($sth->bind_param(1, $n, { TYPE => $row[0]->{DATA_TYPE}}), "Bind Param 1");

@row = ADOTEST::get_type_for_column($dbh, 'B');
ok($sth->bind_param(2, $s, { TYPE => $row[0]->{DATA_TYPE} }), "Bind Param 2");

ok($sth->execute(), "Execute prepared statement with bind params");


ok( $dbh->disconnect,'Disconnect');
