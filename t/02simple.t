#!/usr/bin/perl -I./t
$| = 1;

# vim:ts=2:sw=2:ai:aw:nu:
use DBI qw(:sql_types);
use ADOTEST;
use strict;

use vars qw($tests);

use Test::More tests => 24;

my $non_supported = '-2146825037';

my ($pf, $sf);

my ($longstr) = qq{THIS IS A STRING LONGER THAN 80 CHARS.  THIS SHOULD BE CHECKED FOR TRUNCATION AND COMPARED WITH ITSELF.};
my ($longstr2) = $longstr . "  " . $longstr . "  " . $longstr . "  " . $longstr;

pass( "Begining test, modules loaded" );

my $dbh = DBI->connect() or die "Connect failed: $DBI::errstr\n";
pass( "Database connection created." );


#### testing a simple select

my $rc = 0;

ok( $rc = ADOTEST::tab_create($dbh), " create test table" );

ok( $rc = ADOTEST::tab_exists($dbh), " check existance of test table" );

ok( $rc = tab_insert($dbh), " insert test data" );

ok( $rc = tab_select($dbh), " select test data" );

$rc = undef;
$dbh->{LongReadLen} = 50;
$dbh->{LongTruncOk} = 1;
ok( ($rc = select_long($dbh)) eq 1, " test LongTruncOk ON" );

$dbh->{LongTruncOk} = 0;
ok( ($rc = select_long($dbh)) eq undef, "test LongTruncOk OFF" );

# Not implemented yet.
pass( " test attributes, not implemented yet" );

#$sth = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A");

#if ($sth) {
	#$sth->execute();
	#my $colcount = $sth->func(1, 0, ColAttributes); # 1 for col (unused) 0 for SQL_COLUMN_COUNT
	#print "Column count is: $colcount\n";
	#my ($coltype, $colname, $i, @row);
	#my $is_ok = 0;
	#for ($i = 1; $i <= $colcount; $i++) {
		# $i is colno (1 based) 2 is for SQL_COLUMN_TYPE, 1 is for SQL_COLUMN_NAME
		#$coltype = $sth->func($i, 2, ColAttributes);
		#$colname = $sth->func($i, 1, ColAttributes);
		#print "$i: $colname = $coltype\n";
 		#++$is_ok if grep { $coltype == $_ } @{$ADOTEST::TestFieldInfo{$colname}};
	#}
	#print "not " unless $is_ok == $colcount;
	#print "ok 9\n";
	
	#$sth->finish;
#}
#else {
	#print "not ok 9\n";
#}

$dbh->{RaiseError} = 0;
$dbh->{PrintError} = 0;
#
# some ADO drivers will prepare this OK, but not execute.
# 
{
	# Turn the warnings off at this point.  Expecting statement to fail.
	local $dbh->{Warn} = 0;
	my $sth = $dbh->prepare("SELECT XXNOTCOLUMN FROM $ADOTEST::table_name");
	$sth->execute() if $sth;
	ok( $sth->err, "Check error returned, statement handle" );
	ok( $dbh->err, "Check error returned, database handle " );
	ok( $DBI::err, "Check error returned, DBI::err" );
}

my $dt = qq{${pf}1998-05-13${sf}};
my $sth = $dbh->prepare("SELECT D FROM $ADOTEST::table_name WHERE D > $dt");
$sth->execute();
my $count = 0;
my @row = ();
while (@row = $sth->fetchrow) {
	$count++ if ($row[0]);
	# print "$row[0]\n";
}
ok( $count != 0, " test date value: $dt" );

$sth->finish;

$sth = $dbh->prepare("SELECT A, COUNT(*) FROM $ADOTEST::table_name GROUP BY A");
$sth->execute();
$count = 0;
while (@row = $sth->fetchrow) {
	$count++ if ($row[0]);
	# print "$row[0], $row[1]\n";
}
ok( $count != 0, " test group by queries" );

$sth->finish;
#$rc = ADOTEST::tab_delete($dbh);

my @data_sources = DBI->data_sources('ADO');
# print "Data sources:\n\t", join("\n\t",@data_sources),"\n\n";
ok( $#data_sources != 0, " test data sources ... not implemented" );

my $sth1 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A")
	or warn $dbh->errstr;
my $sth2 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A")
	or warn $dbh->errstr;
ok( defined $sth1, "Statement handle 1 created." );
ok( defined $sth2, "Statement handle 2 created." );

$sth1 = undef; $sth2 = undef; $sth = undef;

$count = 0;
$sth1 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name where A = ?")
	or warn $dbh->errstr;
ok( defined $sth1, "Prepared statement * and Parameter." );

$sth1 = $dbh->prepare("SELECT Stuff_and_Things FROM $ADOTEST::table_name where A = ?")
	or warn $dbh->errstr;
ok( defined $sth1, "Prepared statement bad column and Parameter." );

@row = $sth1->fetchrow;
ok( $sth1->err , "Call to fetchrow without call to execute. " . $sth1->errstr );
ok( scalar @row  == 0, "Call to fetchrow without call to execute, should return 0. " . scalar @row );

{
	$count = 0;
	$sth1 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name where A = ?")
		or warn $dbh->errstr;
	ok( defined $sth1, "Prepared statement * and Parameter." );

	$sth1 = $dbh->prepare("SELECT Stuff_and_Things FROM $ADOTEST::table_name where A = ?")
		or warn $dbh->errstr;
	ok( defined $sth1, "Prepared statement bad column and Parameter." );

	eval { 
		local $sth1->{PrintError} = 0;
		local $sth1->{RaiseError} = 1;
		@row = $sth1->fetchrow;
	};
	ok( $@, "RaiseError caught error: $@" );
}

exit(0);

sub tab_select
{
	my $dbh = shift;
    my @row;
	my $rowcount = 0;

	$dbh->{LongReadLen} = 1000;

    my $sth = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A")
		or return undef;
    $sth->execute();
    while (@row = $sth->fetchrow())	{
			#print "$row[0]|$row[1]|$row[2]|\n";
			print qq{$row[0] $row[1] $row[2] $row[3]\n};
			++$rowcount;
		}
		if ($rowcount == 0) {
			print "Basic retrieval of rows not working!\n";
			$sth->finish;
			return 0;
		}
		$sth->finish();

		$sth = $dbh->prepare("SELECT A,C FROM $ADOTEST::table_name WHERE A>=4")
    	or return undef;
	$rowcount = 0;
	$sth->execute();
	while (@row = $sth->fetchrow()) {
		$rowcount++;
		if ($row[0] == 4) {
			if ($row[1] eq $longstr) {
				print "retrieved ", length($longstr), " byte string OK\n";
			} else {
				print "Basic retrieval of longer rows not working!\nRetrieved value = $row[0]\n";
				return 0;
			}
		} elsif ($row[0] == 5) {
			if ($row[1] eq $longstr2) {
				print "retrieved ", length($longstr2), " byte string OK\n";
			} else {
				print "Basic retrieval of row longer than 255 chars not working!",
						"\nRetrieved ", length($row[1]), " bytes instead of ", 
						length($longstr2), "\nRetrieved value = $row[1]\n";
				return 0;
			}
		}
	}
	if ($rowcount == 0) {
		print "Basic retrieval of rows not working!\nRowcount = $rowcount, while retrieved value = $row[0]\n";
			$sth->finish;
			return 0;
		}

	return 1;
}

#
# show various ways of inserting data without binding parameters.
# Note, these are not necessarily GOOD ways to
# show this...
#
sub tab_insert {
    my $dbh = shift;

		# Determine if an escape sequence is usable.
		my @row;
		foreach (DBI::SQL_DATE(), SQL_TIMESTAMP()) {
			@row = $dbh->type_info($_);
			last if @row;
		}
		my $r = shift @row;
		$pf = $r->{LITERAL_PREFIX};
		$sf = $r->{LITERAL_SUFFIX};
		$pf = qq/{d \'/ unless $pf;		# '
		$sf = qq/\' }/  unless $sf;		# '
    # qeDBF needs a space after the table name!

		print "Building dates using: $pf $sf\n";
	my $dt = qq{${pf}1998-05-10${sf}};
    my $stmt = "INSERT INTO $ADOTEST::table_name (A, B, C, D) VALUES ("
	    . join(", ", 3, $dbh->quote("bletch"), $dbh->quote("bletch varchar"), 
			$dt) . ")";
    my $sth = $dbh->prepare($stmt) or die "prepare: $stmt: $DBI::errstr";
    $sth->execute or die "execute: $stmt: $DBI::errstr";
    $sth->finish;

		$dt = qq{${pf}1998-05-11${sf}};
    $dbh->do(qq{INSERT INTO $ADOTEST::table_name (A, B, C, D) VALUES (1, 'foo', 'foo varchar', $dt)});
		$dt = qq{${pf}1998-05-12${sf}};
    $dbh->do(qq{INSERT INTO $ADOTEST::table_name (A, B, C, D) VALUES (2, 'bar', 'bar varchar', $dt)});
		$dt = qq{${pf}1998-05-13${sf}};
		print "Length of long string ", length($longstr), "\n";
    $stmt = "INSERT INTO $ADOTEST::table_name (A, B, C, D) VALUES ("
	    . join(", ", 4, $dbh->quote("80char"), $dbh->quote($longstr), $dt) . ")";
    $sth = $dbh->prepare($stmt) or die "prepare: $stmt: $DBI::errstr";
    $sth->execute or die "execute: $stmt: $DBI::errstr";
    $sth->finish;
		$dt = qq{${pf}1998-05-14${sf}};
		print "Length of long string 2 ", length($longstr2), "\n";
    $stmt = "INSERT INTO $ADOTEST::table_name (A, B, C, D) VALUES ("
	    . join(", ", 5, $dbh->quote("gt250char"), $dbh->quote($longstr2), $dt). ")";
    $sth = $dbh->prepare($stmt) or die "prepare: $stmt: $DBI::errstr";
    $sth->execute or die "execute: $stmt: $DBI::errstr";
    $sth->finish;
		return 1;
}

sub select_long
{
	my $dbh = shift;
	my @row;
	my $sth;
	my $rc = undef;
	
	$dbh->{RaiseError} = 1;
	$sth = $dbh->prepare("SELECT A,C FROM $ADOTEST::table_name WHERE A=4");
	if ($sth) {
		$sth->execute();
		eval {
			while (@row = $sth->fetchrow()) {
			}
		};
		$rc = 1 unless ($@) ;
	}
	$rc;
}

__END__




