#!/usr/bin/perl -I./t
$| = 1;

# vim:ts=2:sw=2:ai:aw:nu:
use DBI qw(:sql_types);
use ADOTEST;
use Data::Dumper;
use strict;
my ($pf, $sf);

use Test::More tests => 74;

BEGIN { use_ok( 'DBD::ADO' ); }

my $non_supported = '-2146825037';

my ($longstr) = qq{THIS IS A STRING LONGER THAN 80 CHARS.  THIS SHOULD BE CHECKED FOR TRUNCATION AND COMPARED WITH ITSELF.};
my ($longstr2) = $longstr . "  " . $longstr . "  " . $longstr . "  " . $longstr;

# print "ok 1\n";

# print " Test 2: connecting to the database\n";
my $dbh = DBI->connect() or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh, "Connection" ); # print "ok 2\n";


#### testing a simple select

# print " Test 3: create test table\n";
# $rc = ADOTEST::tab_create($dbh);
ok( ADOTEST::tab_create($dbh), " Create test table" );
# print "not " unless($rc);
# print "ok 3\n";

# print " Test 4: check existance of test table\n";
my $rc = 0;
# $rc = ADOTEST::tab_exists($dbh);
ok( ADOTEST::tab_exists($dbh), " check existance of test table" );
# print "not " unless($rc >= 0);
# print "ok 4\n";

# print " Test 5: insert test data\n";
# $rc = tab_insert($dbh);
ok( tab_insert($dbh), " insert test data" );
# print "not " unless($rc);
# print "ok 5\n";

# print " Test 6: select test data\n";
ok( tab_select($dbh), " select test data" );
# print "not " unless($rc);
# print "ok 6\n";

# print " Test 14: test creating two statement handles\n";
my ($sth1, $sth2);
pass( "Test Creating two statement handle.  Execute in series" );
ok( $sth1 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A"),
	" Prepare statement handle 1" );
ok( $sth2 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A"),
	" Prepare statement handle 2" );

ok( defined $sth1, " statement handle 1 defined" );
ok( defined $sth2, " statement handle 2 defined" );

ok( defined ($rc = $sth1->execute), " execute statement handle 1" );
my $cnt = 0;
while( my @row = $sth1->fetchrow_array ) {
	$cnt++;
	# print join( ",", map { defined $_ ? $_ : 'undef' } @row ), "\n";
}
ok( $cnt > 0, " rows fetched > 0" );

ok( $rc = $sth2->execute, " execute statement handle 2" );
$cnt = 0;
while( my @row = $sth2->fetchrow_array ) {
	# print join( ",", map { defined $_ ? $_ : 'undef' } @row ), "\n";
	$cnt++;
}
ok( $cnt > 0, " rows fetched > 0" );

undef $sth1; undef $sth2;

# Testing a prepare statement with different cursortypes.
my @CursorTypes = qw{adOpenForwardOnly adOpenKeyset adOpenDynamic adOpenStatic};
foreach my $ct (@CursorTypes) {
	ok( $sth1 = $dbh->prepare(
		"SELECT * FROM $ADOTEST::table_name ORDER BY A",
			{ CursorType => $ct } ),
		"Prepare statement handle using CursorType => $ct" );
	$rc = $sth1->execute;
   SKIP: {
       skip "CusorType: $ct, not supported by Provider", 2 
			 		if ( defined $sth1->err and $sth1->err eq $non_supported );
			ok( defined ($rc) , " Execute statement handle using CursorType => $ct : $rc" );
		
			$cnt = 0;
			while( my @row = $sth1->fetchrow_array ) {
				$cnt++;
				# print join( ",", map { defined $_ ? $_ : 'undef' } @row ), "\n";
			}
			ok( $cnt > 0, " Rows fetched > 0 for CursorType => $ct" );
  	}
	ok( $sth1->finish, " Finish statement handle using CursorType => $ct" );
}

$dbh->{Warn} = 0;
foreach my $ad (<DATA>) {
	chomp $ad;
	print "Checking func: OpenSchema : $ad\n";
	print "->$ad\n";
	$sth1 = $dbh->func( qq{$ad}, 'OpenSchema' );
	SKIP: {
		skip "OpenSchema: $ad, not supported by Provider", 1 
			unless ( defined $sth1 );
		ok(  defined $sth1, " Test function call 'OpenSchema': $ad : return statement handle" );

		print "\n", join( ",", map { defined $_ ? $_ : 'undef' } @{$sth1->{NAME}}), "\n";

		# while( my @row = $sth1->fetchrow_array ) {
		# 	print join( ",", map { defined $_ ? $_ : 'undef' } @row ), "\n";
		# }

		$sth1 = undef;
	}
}

eval {
	$sth1 = $dbh->func( 'adBadCallOpenSchema', 'OpenSchema' );
	die "Error OpenSchema: undefined statement handle" unless $sth1;
};

ok( $@, " call to OpenSchema with bad argument" );

$sth1 = undef;

# MS SQL test.
# {
# 	local ($dbh->{AutoCommit});
# 	$dbh->{AutoCommit} = 0;
# 	$dbh->rollback;
# 
# pass( "Test creating executing statement handle 2 while looping statement handle 1" );
# ok ($sth1 = $dbh->prepare( q{select name, type from sysobjects where type = 'U '},
# 	{ CursorType => 'adOpenStatic' } ),
# 	" test prepare with CursorType => adOpenStatic" );
# 
# die "Undefined statement handle: \n" unless $sth1;
# 
# $sth1->execute();
# # print join( "\n\t", @{$sth1->{NAME}}), "\n";
# while( my ($name, $type) = $sth1->fetchrow_array ) {
# # 	print "Object $name, Type $type\n";
# 	my $sth2;
# 	ok( $sth2 = $dbh->prepare( "select * from $name", { CursorType => 'adOpenForwardOnly' } ),
# 		" selecting data from $name CursorType => adOpenForwardOnly"
# 	);
# 
# 	ok( !$sth2->execute, " execute second handle CursorType => adOpenForwardOnly" );
# 	my $row;
# 	$row = $sth2->fetchrow;
# 	ok(!$sth2->err, " fetchrow: " . defined $sth2->err ? $sth2->errstr : 'no errors' );
# # 	print "Table: $name: Columns: \n", join( "\n\t", @{$sth2->{NAME}}), "\n";
# 	ok( $sth2->finish, " finished second handle" );
# }
# 
# $sth1->finish;
# 
# }

ok( $dbh->do( qq{drop table $ADOTEST::table_name} ) , " Drop test table" );

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
			# print qq{$row[0] $row[1] $row[2] $row[3]\n};
			++$rowcount;
		}
		if ($rowcount == 0) {
			# print "Basic retrieval of rows not working!\n";
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
		$pf = qq/{d \'/ unless $pf; #'
		$sf = qq/\' }/  unless $sf; #'
    # qeDBF needs a space after the table name!

		print "Building dates using: $pf $sf\n";
	my $dt = qq{${pf}1998-05-10 00:00:00${sf}};
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
adSchemaAsserts
adSchemaCatalogs
adSchemaCharacterSets
adSchemaCheckConstraints
adSchemaCollations
adSchemaColumnPrivileges
adSchemaColumns
adSchemaColumnsDomainUsage
adSchemaConstraintColumnUsage
adSchemaConstraintTableUsage
adSchemaCubes
adSchemaDBInfoKeywords
adSchemaDBInfoLiterals
adSchemaDimensions
adSchemaForeignKeys
adSchemaHierarchies
adSchemaIndexes
adSchemaKeyColumnUsage
adSchemaLevels
adSchemaMeasures
adSchemaMembers
adSchemaPrimaryKeys
adSchemaProcedureColumns
adSchemaProcedureParameters
adSchemaProcedures
adSchemaProperties
adSchemaProviderSpecific
adSchemaProviderTypes
adSchemaReferentialConstraints
adSchemaSchemata
adSchemaSQLLanguages
adSchemaStatistics
adSchemaTableConstraints
adSchemaTablePrivileges
adSchemaTables
adSchemaTranslations
adSchemaTrustees
adSchemaUsagePrivileges
adSchemaViewColumnUsage
adSchemaViews
adSchemaViewTableUsage
