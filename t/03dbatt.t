#!/usr/bin/perl -I./t
#
# vim:ts=2:sw=2:ai:aw:nu
$|=1;

use DBI qw(:sql_types);
use ADOTEST;
use Test::More tests => 29;
use strict;

my ($pf, $sf);

my @row;

pass( "Begin testing, modules loaded" );

my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";
pass( "Connection established" );

#### testing set/get of connection attributes

my $rc = 0;

$dbh->{'AutoCommit'} = 1;
$rc = commitTest($dbh);
print " ", $DBI::errstr, "" if ($rc < 0);
ok( $rc == 1, "Commit Test, AutoCommit ON" );

ok( defined $dbh->{AutoCommit}, "AutoCommit attribute" );

$dbh->{'AutoCommit'} = 0;
$rc = commitTest($dbh);
print $DBI::errstr, "\n" if ($rc < 0);
ok( $rc == 0, "Commit Test, AutoCommit OFF" );
ok( $dbh->{'AutoCommit'} = 1, "Set AutoCommit ON" );

# ------------------------------------------------------------

my $rows = 0;
# TBD: Check for tables function working.  

ok( @row = $dbh->tables(), " tables() return a list of tables." );

my $tchk = [ qw{TABLE_CAT TABLE_SCHEM TABLE_NAME TABLE_TYPE REMARKS } ];
if (my $sth = $dbh->table_info()) {
    while (my @row = $sth->fetchrow()) {
        $rows++;
    }
    $sth->finish();
#		Check the columns returned from table_info.
	my $vtchk = $sth->{NAME};
	for ( 0 .. $#{$tchk} ) {
		ok ( $tchk->[$_] eq $vtchk->[$_], "Attribute: $tchk->[$_] $vtchk->[$_] " );
	}
}
ok( $rows, "Total tables count: $rows" );

$rows = 0;
# Check if type_info_all is working.
ok( $rows = $dbh->type_info_all(), "Check type_info_all: " );

my $sth = $dbh->prepare("SELECT A FROM $ADOTEST::table_name");
# $sth = $dbh->prepare("SELECT * FROM titles where title_id = ?");
#$sth = $dbh->prepare("SELECT * FROM titles");
#$sth->bind_param(1, undef, SQL_VARCHAR());
#$sth->execute('PS1372');
$sth->execute();

my @attribs = qw{
	NUM_OF_FIELDS NUM_OF_PARAMS NAME NAME_lc NAME_uc
	PRECISION SCALE NULLABLE CursorName Statement
	RowsInCache
};

eval { 
	my $val = $sth->{BadAttributeHere};
};
ok( $@, " Statement attribute: BadAttributeHere" );

foreach my $attrib (sort @attribs) {
	eval { 
		my $val = $sth->{$attrib};
	};
	ok( !$@, " Statement attribute: $attrib" );
}

my $val = -1;
ok($val = ($sth->{RowsInCache} = 100) , " Setting RowsInCache : $val" );
ok(($val = $sth->{RowsInCache}) == 100, " Getting RowsInCache : $val" );

$sth->finish;


ok( !$dbh->disconnect(), "Disconnect, tests completed" );

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

