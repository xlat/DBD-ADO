#!/usr/bin/perl -I./t
#
# vim:ts=2:sw=2:ai:aw:nu
$|=1;
print "1..$tests\n";

use DBI qw(:sql_types);
use ADOTEST;
my ($pf, $sf);

my @row;

print "ok 1\n";

my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";
print "ok 2\n";

#### testing set/get of connection attributes

$dbh->{'AutoCommit'} = 1;
$rc = commitTest($dbh);
print " ", $DBI->errstr, "" if ($rc < 0);
print "not " unless ($rc == 1);
print "ok 3\n";

print "not " unless($dbh->{AutoCommit});
print "ok 4\n";

$dbh->{'AutoCommit'} = 0;
$rc = commitTest($dbh);
print $DBI->errstr, "\n" if ($rc < 0);
print "not" unless ($rc == 0);
print "ok 5\n";
$dbh->{'AutoCommit'} = 1;

# ------------------------------------------------------------

my $rows = 0;
# TBD: Check for tables function working.  
$tchk = [ qw{TABLE_CAT TABLE_SCHEM TABLE_NAME TABLE_TYPE REMARKS } ];
if ($sth = $dbh->table_info()) {
    while (@row = $sth->fetchrow()) {
        $rows++;
    }
    $sth->finish();
#		Check the columns returned from table_info.
	my $vtchk = $sth->{NAME};
	for ( 0 .. $#{$tchk} ) {
			print "Attribute: $tchk->[$_] $vtchk->[$_] ";
		if ( $tchk->[$_] eq $vtchk->[$_] ) {
			print "ok\n";
		} else {
				print "not ok\n";
		}
	}
	
}
print "tables $rows\n";
print "not " unless $rows;
print "ok 6\n";

$rows = 0;
# Check if type_info_all is working.
$rows = $dbh->type_info_all();
print "not " unless $rows;
print "ok 7\n";

$sth = $dbh->prepare("SELECT A FROM $ADOTEST::table_name");
# $sth = $dbh->prepare("SELECT * FROM titles where title_id = ?");
#$sth = $dbh->prepare("SELECT * FROM titles");
#$sth->bind_param(1, undef, SQL_VARCHAR());
#$sth->execute('PS1372');
$sth->execute();

print "not " unless exists $sth->{NUM_OF_FIELDS};
print "Number of Fields ", $sth->{NUM_OF_FIELDS}, "\n" if exists $sth->{NUM_OF_FIELDS};
print "ok 8\n";

print "not " unless exists $sth->{NUM_OF_PARAMS};
print "Number of Parameters ", $sth->{NUM_OF_PARAMS}, "\n" if exists $sth->{NUM_OF_PARAMS};
print "ok 9\n";

print "not " unless exists $sth->{NAME};
print "Names ", join( " ", @{$sth->{NAME}}), "\n" if exists $sth->{NAME};
print "ok 10\n";

print "not " unless exists $sth->{NAME_lc};
print "Names ", join( " ", @{$sth->{NAME_lc}}), "\n" if exists $sth->{NAME_lc};
print "ok 11\n";

print "not " unless exists $sth->{NAME_uc};
print "Names ", join( " ", @{$sth->{NAME_uc}}), "\n" if exists $sth->{NAME_uc};
print "ok 12\n";

print "not " unless exists $sth->{TYPE};
print "Types ", join( " ", @{$sth->{TYPE}}), "\n" if exists $sth->{TYPE};
print "ok 13\n";

print "not " unless exists $sth->{PRECISION};
print "ok 14\n";

print "not " unless exists $sth->{SCALE};
print "ok 15\n";

print "not " unless exists $sth->{NULLABLE};

print "ok 16\n";
print "not " unless $sth->{CursorName};

print "ok 17\n";
print "not " unless exists $sth->{Statement};
print "statement ", $sth->{Statement}, "\n" if exists $sth->{Statement};
print "ok 18\n";

print "not " unless $sth->{RowsInCache};
print "ok 19\n";

$sth->finish;

print "tables() \n";
@row = $dbh->tables();
print "not " unless @row;
print "ok 20\n";

$dbh->disconnect();

BEGIN { $tests = 20; }

# ------------------------------------------------------------
# returns true when a row remains inserted after a rollback.
# this means that autocommit is ON. 
# ------------------------------------------------------------
sub commitTest {
    my $dbh = shift;
    my @row;
    my $rc = -1;
    my $sth;
		# Determine if an escape sequence is usable.
		foreach (DBI::SQL_DATE(), DBI::SQL_TIMESTAMP()) {
			@row = $dbh->type_info($_);
			last if @row;
		}
		my $r = shift @row;
		$pf = $r->{LITERAL_PREFIX};
		$sf = $r->{LITERAL_SUFFIX};
		$pf = qq/{d \'/ unless $pf;
		$sf = qq/\' }/  unless $sf;

    $dbh->do("DELETE FROM $ADOTEST::table_name WHERE A = 100") or return undef;

    { # suppress the "commit ineffective" warning
      local($SIG{__WARN__}) = sub { };
      $dbh->commit();
    }

		my $dt = qq{${pf}1997-01-01${sf}};
    $dbh->do("insert into $ADOTEST::table_name values(100, 'x', 'y', $dt)");
    { # suppress the "rollback ineffective" warning
	  local($SIG{__WARN__}) = sub { };
      $dbh->rollback();
    }
    $sth = $dbh->prepare("SELECT A FROM $ADOTEST::table_name WHERE A = 100");
    $sth->execute();
    if (@row = $sth->fetchrow()) {
        $rc = 1;
    }
    else {
	$rc = 0;
    }
    $sth->finish();
    $rc;
}

# ------------------------------------------------------------

