#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:ai:aw:nu:
$| = 1;

# Generate large number of test rows.

use strict;
use warnings;
use DBI qw(:sql_types);
use Time::HiRes qw(gettimeofday tv_interval);
use ADOTEST;

use Data::Dumper;

use vars qw($tests $table_name);
use constant MAX_ROWS => 200;

my %TestFieldInfo = (
	'A' => [SQL_SMALLINT,SQL_TINYINT, SQL_NUMERIC, SQL_DECIMAL, SQL_FLOAT, SQL_REAL, SQL_DOUBLE],
	'B' => [SQL_WVARCHAR, SQL_VARCHAR, SQL_WCHAR, SQL_CHAR],
	'D' => [SQL_DATE, SQL_TIMESTAMP],
);

$ADOTEST::table_name = $table_name = "dbd_ado_large";

use Test::More;

if (defined $ENV{DBI_DSN}) {
	plan tests => 37;
} else {
	plan skip_all => 'Cannot test without DB info';
}

pass( "Begining test, modules loaded" );

my $dbh = DBI->connect( $ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
	{
		ado_commandtimeout	=> 20
	}) 
	or die "Connect failed: $DBI::errstr\n";
		  # ado_cursortype			=> 'adOpenStatic'
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

# ok(!$dbh->do( qq(drop table $table_name) ), "Drop table $table_name" );

ok( ADOTEST::tab_create($dbh), "Create table $table_name" );

my $sel = $dbh->prepare( qq{select * from $table_name},
	{ ado_cursortype			=> 'adOpenStatic' }
);
ok ( defined $sel, "Prepared select * statement, cursortype defined" );
ok ( $sel->execute, "Execute select" );
$sel->finish; $sel = undef;

$sel = $dbh->prepare( qq{select * from $table_name},
	{ ado_cursortype			=> 'adOpenStatic' }
);
ok ( defined $sel, "Prepared select * statement, cursortype defined" );
ok ( $sel->execute, "Execute select" );
$sel->finish; $sel = undef;

$sel = $dbh->prepare( qq{select * from $table_name},
	{
	  ado_cursortype			=> 'adOpenStatic'
	, ado_users						=> 1
	}
);
ok ( defined $sel, "Prepared select * statement, cursortype and users defined" );
ok ( $sel->execute, "Execute select" );
$sel->finish; $sel = undef;

$sel = $dbh->prepare( qq{select * from $table_name},
	{
	  ado_cursortype			=> 'adOpenStatic'
	, ado_usecmd					=> 1
	}
);
ok ( defined $sel, "Prepared select * statement, cursortype and usecmd defined" );
ok ( $sel->execute, "Execute select" );
$sel->finish; $sel = undef;

$sel = $dbh->prepare( qq{select * from $table_name},
	{
	  ado_cursortype			=> 'adOpenStatic'
	, ado_usecmd					=> 1
	, ado_users						=> 1
	}
);
ok ( defined $sel, "Prepared select * statement, cursortype, users, and usecmd defined" );
ok ( $sel->execute, "Execute select" );
$sel->finish; $sel = undef;

$sel = $dbh->prepare( qq{select * from $table_name});
ok ( defined $sel, "Prepared select * statement" );

$sel->{ado_commandtimeout} = 37;
ok( $sel->{ado_commandtimeout} == 37, "Modify ado commandtimeout" );
ok( $sel->{ado_comm}->{CommandTimeout} == 37, "Modify command commandtimeout" );

$sel->finish; $sel = undef;

# foreach my $ac (qw[0 1]) {
# 	pass( "Testing with AutoCommit $ac" );
# 	$dbh->{AutoCommit} = $ac;
# 
# 	# Time how long it takes to run the insert test.
# 	my $t_beg = [gettimeofday];
# 	run_insert_test($dbh);
# 
# 	my $elapsed = tv_interval($t_beg, [gettimeofday]);
# 
# 	pass( "Run insert test: MAX_ROWS elapsed: $elapsed" );
# 
# 	ok($dbh->do( qq{drop table $table_name} ), "Drop table $table_name" );
# }

# Time how long it takes to run the insert test.
$dbh->{AutoCommit} = 0;
my $t_beg = [gettimeofday];
run_insert_test($dbh);

my $elapsed = tv_interval($t_beg, [gettimeofday]);

pass( "Run insert test: MAX_ROWS elapsed: $elapsed" );

foreach my $ric (qw[1 10 100 1000]) {
	$sel = $dbh->prepare( qq{select * from $table_name}, {RowCacheSize => $ric, ado_users => 1} );
	ok ( defined $sel, "Prepared select * statement, with RowCacheSize and ado_users" );

	my $rtn = $sel->execute();
	ok ( defined $rtn, "Execute returned $rtn" );

	$t_beg = [gettimeofday];
	while( my $row = $sel->fetchrow_arrayref() ) {
		$row = undef;
	}
	$elapsed = tv_interval($t_beg, [gettimeofday]);
	pass( "Run select all test: cache: $ric Max rows: MAX_ROWS elapsed: $elapsed" );
}

$sel = undef;

ok($dbh->do( qq{drop table $table_name} ), "Drop table $table_name" );
ok(!$dbh->disconnect(), "Disconnect from database" );


exit;

sub run_insert_test {
	my $dbh = shift;
	# ok(!$dbh->do( qq(drop table $table_name) ), "Drop table $table_name" );
	ok( ADOTEST::tab_create($dbh), "Create table $table_name" );
	# Add test data.
	my $ins = $dbh->prepare( qq{insert into $table_name (A,B) values (?,?)}, {ado_usecmd => 1 } );
	ok( defined $ins, "Insert statement prepared" );
	ok( ! $dbh->err, "No error on prepare." );

	pass( "Loading rows into table: $table_name" );

	my $cnt = 0; my $added = 0;
	my $ac = ($dbh->{AutoCommit} == 0);
	while( $cnt < MAX_ROWS ) {

		$added += ($ins->execute( $cnt, qq{Just a text message for $cnt} )||0);

	} continue { 

		$cnt++;

		$dbh->commit if ($ac and $cnt % 1000);
		warn "Checkpoint: $cnt\n" unless ($cnt % 1000);

	}

	$dbh->commit if ($ac);
	ok( $added > 0, "Added $added rows to test using count of $cnt" );
	ok( $added == MAX_ROWS, "Added MAX MAX_ROWS $added rows to test using count of $cnt" );

	$ins->finish; $ins = undef;
	return;
}
__END__
