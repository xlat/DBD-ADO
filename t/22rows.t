#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:ai:aw:nu:
$| = 1;

# Test the rows returned.

use strict;
use warnings;
use DBI qw(:sql_types);
use Time::HiRes qw(gettimeofday tv_interval);

use Data::Dumper;

use vars qw($tests $table_name);
use constant MAX_ROWS => 200;

my %TestFieldInfo = (
	'A' => [SQL_SMALLINT,SQL_TINYINT, SQL_NUMERIC, SQL_DECIMAL, SQL_FLOAT, SQL_REAL, SQL_DOUBLE],
	'B' => [SQL_WVARCHAR, SQL_VARCHAR, SQL_WCHAR, SQL_CHAR],
	'D' => [SQL_DATE, SQL_TIMESTAMP],
);

my $from_table_name = "dbd_ado_frows";
my $to_table_name = "dbd_ado_trows";

use Test::More;

if (defined $ENV{DBI_DSN}) {
	plan tests => 17;
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

ok( tab_create($dbh, $from_table_name, 1), "Create table $from_table_name" );
ok( tab_create($dbh, $to_table_name, 1),   "Create table $to_table_name" );


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
run_insert_test($dbh, $from_table_name);

my $elapsed = tv_interval($t_beg, [gettimeofday]);
pass( "Run insert test: MAX_ROWS elapsed: $elapsed" );

# Test the number of rows returned by an execute.
my $ins_sql = qq{
	insert into $to_table_name( A, B )
	select A, B from $from_table_name
};

my $ins_sth = $dbh->prepare( $ins_sql );
ok( defined $ins_sth, "Prepared insert select statement" );
my $rc = $ins_sth->execute;
is( $rc, MAX_ROWS, "Execute returned " . MAX_ROWS . " rows" );
is($ins_sth->rows, $rc, "Execute ins_sth->rows returned $rc" );

$ins_sth->finish; $ins_sth = undef;

# Test the number of rows returned by a do.
$rc = $dbh->do($ins_sql);
is( $rc, MAX_ROWS, "Do returned  " . MAX_ROWS . " rows" );

$dbh->rollback;

ok($dbh->do( qq{drop table $from_table_name} ), "Drop table $from_table_name" );
ok($dbh->do( qq{drop table $to_table_name} ), "Drop table $to_table_name" );

ok( $dbh->disconnect,'Disconnect');


exit;

sub run_insert_test {
	my $dbh = shift;
	my $table_name = shift;
	# ok( tab_create($dbh), "Create table $table_name" );
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
	ok( $added == MAX_ROWS, "Added MAX " . MAX_ROWS . " rows to test using count of $cnt" );

	$ins->finish; $ins = undef;
	return;
}



sub get_type_for_column {
	my $dbh = shift;
	my $column = shift;

	my $type;
	my @row;
	my $sth;
	foreach $type (@{ $TestFieldInfo{$column} }) {
	    @row = $dbh->type_info($type);
	    # may not correct behavior, but get the first compat type
			#print "Type $type rows: ", scalar(@row), "\n";
	    last if @row;
	}
	die "Unable to find a suitable test type for field $column"
	    unless @row;
	return @row;
}
	
sub tab_create {
	my $dbh = shift;
	my $table_name = shift;
	my $drop = shift;
	if ($drop) {
				local ($dbh->{PrintError}, $dbh->{RaiseError}, $dbh->{Warn});
				$dbh->{PrintError} = $dbh->{RaiseError} = $dbh->{Warn} = 0;
	    	$dbh->do("DROP TABLE $table_name");
	}

	# $dbh->{PrintError} = 1;

	# trying to use ADO to tell us what type of data to use,
	# instead of the above.
	my $fields = undef;
	my ($f,$r);
	foreach $f (sort keys %TestFieldInfo) {
	    #print "$f: @{$TestFieldInfo{$f}}\n";
	    $fields .= ", " unless !$fields;
	    $fields .= "$f ";
	    #print "-- $fields\n";

	    my @row = get_type_for_column($dbh, $f);
			shift @row if ($row[0])->{TYPE_NAME} =~ /identity$/i;
			shift @row if ($row[0])->{TYPE_NAME} =~ /nclob/i;

			$r = shift @row;
	    $fields .= $dbh->func( $r,  'create_parm');

	}
	print "Using fields: $fields\n";
	return $dbh->do(qq{CREATE TABLE $table_name ($fields)});
}



__END__
