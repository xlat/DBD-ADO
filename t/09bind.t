#!/usr/bin/perl -I./t
$| = 1;
print "1..$tests\n";

use DBI qw(:sql_types);
use ADOTEST;

print "ok 1\n";

print " Test 2: connecting to the database\n";
my $dbh = DBI->connect() || die "Connect failed: $DBI::errstr\n";

print "ok 2\n";


#### testing a simple select"

print " Test 3: create test table\n";
$rc = ADOTEST::tab_create($dbh);
print "not " unless($rc);
print "ok 3\n";

print " Test 4: insert test data\n";
my $vr = "me" x 120;
my @data = (
	[ 1, 'foo', $vr, "1998-05-13", "1988-05-13 01:12:33" ],
	[ 2, 'bar', 'bar varchar', "1998-05-14", "1998-05-14 01:25:33" ],
	[ 3, 'bletch', 'bletch varchar', "1998-05-15", "1998-05-15 01:15:33" ],
	[ 4, 'bletch', 'memememememememememememememe', "1998-05-15", "1998-05-15 01:15:33" ],
);
$rc = tab_insert($dbh, \@data);
unless ($rc) {
	warn qq{Test 4 is known to fail often. It is not a major concern.  It *may* be an indication of being unable to bind datetime values correctly.\n};
	print "not "
}
print "ok 4\n";

print qq{ Test 5: select test data\n};
$rc = tab_select($dbh, \@data);
print "not " unless($rc);
print qq{ok 5\n};

$rc = ADOTEST::tab_delete($dbh);

BEGIN {$tests = 5;}
exit(0);

sub tab_select {
	my $dbh = shift;
    my $dref = shift;
    my @data = @{$dref};
    my @row;

    my $sth = $dbh->prepare(qq{SELECT A,B,C,D FROM $ADOTEST::table_name WHERE a = ?})
		or return undef;
	@ctype = ADOTEST::get_type_for_column($dbh, 'A');
	my @bind_vals = (1,3,2,4,10);
	my $bind_val;
	foreach $bind_val (@bind_vals) {
	#	$sth->bind_param(1, $bind_val, SQL_INTEGER);
		$sth->bind_param(1, $bind_val, { TYPE => $ctype[0]->{DATA_TYPE}});
		$sth->execute;
		while (@row = $sth->fetchrow()) {
			print "$row[0] length:(", length($row[1]), ") $row[1] $row[2] $row[3]\n";
			if ($row[0] != $bind_val) {
				print "Bind value failed! bind value = $bind_val, returned value = $row[0]\n";
				return undef;
			}
		}
    }
	return 1;
}

sub tab_insert {
    my $dbh = shift;
    my $dref = shift;
    my @data = @{$dref};

	# Determine if an escape sequence is usable.
	my @row1;
	foreach (DBI::SQL_DATE(), SQL_TIMESTAMP()) {
  	@row1 = $dbh->type_info($_);
  	last if @row1;
	}
	my $r = shift @row1;
	my ($pf, $sf);
	$pf = $r->{LITERAL_PREFIX};
	$sf = $r->{LITERAL_SUFFIX};
	$pf = qq/{d \'/ unless $pf;
	$sf = qq/\' }/  unless $sf;
	# qeDBF needs a space after the table name!

	#print "Building dates using: $pf $sf\n";

	$pf =~ s/\'$//;
	$sf =~ s/^\'//;
	#print qq{${pf}1998-05-10${sf}};

	#INSERT INTO $ADOTEST::table_name (A, B, C, D) VALUES (?, ?, ?, ${pf}?${sf})
    my $sth = $dbh->prepare(qq{
	INSERT INTO $ADOTEST::table_name (A, B, C, D) VALUES (?, ?, ?, ?)
});
    unless ($sth) {
	warn $DBI::errstr;
	return 0;
    }
    $sth->{PrintError} = 1;
    foreach (@data) {
	my @row;
	@row = ADOTEST::get_type_for_column($dbh, 'A');
	$sth->bind_param(1, $_->[0], { TYPE => $row[0]->{DATA_TYPE}});

	@row = ADOTEST::get_type_for_column($dbh, 'B');
	$_->[1] = $_->[1] x (int( $row[0]->{COLUMN_SIZE}/length($_->[1])));
	$sth->bind_param(2, $_->[1], { TYPE => $row[0]->{DATA_TYPE} });

	@row = ADOTEST::get_type_for_column($dbh, 'C');
	$sth->bind_param(3, $_->[2], { TYPE => $row[0]->{DATA_TYPE}});

	@row = ADOTEST::get_type_for_column($dbh, 'D');
	my $dt = ($_->[$row[1] == SQL_DATE ? 3 : 4 ]);
	$sth->bind_param(4, $dt, { TYPE => $row[0]->{DATA_TYPE}});
	return 0 unless $sth->execute;
    }
    1;
}

__END__

