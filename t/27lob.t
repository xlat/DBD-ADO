#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI qw(:sql_types);
use ADOTEST();

#use Test::More;
#
#if (defined $ENV{DBI_DSN}) {
#  plan tests => ;
#} else {
#  plan skip_all => 'Cannot test without DB info';
#}

my $t = 0;
my $failed = 0;
my $table = "perl_dbd_ado_long";


print "1..0\n";
exit;

unless (defined $ENV{DBI_DSN}) {
    	print "1..0\n";
	exit;
}

my $dbh = DBI->connect();

unless($dbh) {
    warn "Unable to connect to ($DBI::errstr)\nTests skiped.\n";
    print "1..0\n";
    exit 0;
}

warn "Skipping the long tests ... for now!";
print "1..0\n";
exit 0;

print "Test Verbose: ", $ENV{TEST_VERBOSE}, "\n";

my $tn = ($dbh->type_info(SQL_NUMERIC()))[0]->{TYPE_NAME};
my $tiv = SQL_NUMERIC();

my @test_sets;
foreach my $t (SQL_VARCHAR, SQL_LONGVARCHAR, SQL_WLONGVARCHAR(), SQL_LONGVARBINARY()) {
	my @r = $dbh->type_info( $t );
	# print Dumper(@r);
	foreach my $rt ( @r ) {
		next if ( $rt->{TYPE_NAME} =~ m/nclob/i );
		next if ( $rt->{TYPE_NAME} =~ m/raw/i );
		next if ( $rt->{TYPE_NAME} =~ m/^lo$/i );
		print "For $t Using: ", my $tbd = $rt->{TYPE_NAME}, "\n";
		push( @test_sets, [ "$tbd", $t ] );
		last;
	}
}

# Set size of test data (in 10KB units)
#	Minimum value 3 (else tests fail because of assumptions)
#	Normal  value 8 (to test 64KB threshold well)
my $sz = 8;

my $tests;
my $tests_per_set = 35;
$tests = @test_sets * $tests_per_set;

# use Test::More tests => 35;

my($sth, $p1, $p2, $tmp, @tmp);

foreach (@test_sets) {
    run_long_tests( @$_ );
}


sub run_long_tests {
    my ($type_name, $type_num) = @_;

# relationships between these lengths are important # e.g.
my $long_data0 = ('0\177x\0X'   x 2048) x (1    );  # 10KB  < 64KB
my $long_data1 = ("1234567890"  x 1024) x ($sz  );  # 80KB >> 64KB && > long_data2
my $long_data2 = ("2bcdefabcd"  x 1024) x ($sz-1);  # 70KB  > 64KB && < long_data1

# special hack for long_data0 since RAW types need pairs of HEX
$long_data0 = "00FF" x (length($long_data0) / 2) if $type_name =~ /RAW/i;

my $len_data0 = length($long_data0);
my $len_data1 = length($long_data1);
my $len_data2 = length($long_data2);
# print "long_data0 length $len_data0\n";
# print "long_data1 length $len_data1\n";
# print "long_data2 length $len_data2\n";

# warn if some of the key aspects of the data sizing are tampered with
warn "long_data0 is > 64KB: $len_data0\n"
	if $len_data0 > 65535;
warn "long_data1 is < 64KB: $len_data1\n"
	if $len_data1 < 65535;
warn "long_data2 is not smaller than $long_data1 ($len_data2 > $len_data1)\n"
	if $len_data2 >= $len_data1;


if (!ADOTEST::tab_long_create($dbh, "midx", $tn, SQL_NUMERIC(), "lng", $type_name, $type_num)) {
    warn "Unable to create test table for '$type_name' data ($DBI::err). Tests skipped.\n";
    foreach (1..$tests_per_set) { ok(0) }
    return;
}
# Determine if an escape sequence is usable.
my $ti = ADOTEST::get_type_for_column( $dbh,'D');
my $pf = $ti->{LITERAL_PREFIX};
my $sf = $ti->{LITERAL_SUFFIX};
$pf = qq/{d \'/ unless $pf; #'
$sf = qq/\' }/  unless $sf; #'

# qeDBF needs a space after the table name!

# print "Building dates using: $pf $sf\n";

my $dt = qq{${pf}2001-10-11${sf}};

print " --- insert some $type_name data\n";

ok( $sth = $dbh->prepare("insert into $table(midx,lng,dt) values (?, ?, $dt)"), " --- insert some $type_name data" );
$sth->bind_param(1, 40, { TYPE => SQL_NUMERIC() } ) or die $DBI::errstr;
$sth->bind_param(2, $long_data0, { TYPE => $type_num } ) or die $DBI::errstr;
ok( $sth->execute(), "Inserted data" );

$sth->bind_param(1, 41, { TYPE => SQL_NUMERIC() } ) or die $DBI::errstr;
$sth->bind_param(2, $long_data1, { TYPE => $type_num } ) or die $DBI::errstr;
ok( $sth->execute(), "Inserted data" );

$sth->bind_param(1, 42, { TYPE => SQL_NUMERIC() } ) or die $DBI::errstr;
$sth->bind_param(2, $long_data2, { TYPE => $type_num } ) or die $DBI::errstr;
ok( $sth->execute(42, $long_data2), "Inserted data" );


print " --- fetch $type_name data back again -- truncated - LongTruncOk == 1\n";#
$dbh->{LongReadLen} = 20;
$dbh->{LongTruncOk} =  1;
print "LongReadLen $dbh->{LongReadLen}, LongTruncOk $dbh->{LongTruncOk}\n";

# This behaviour isn't specified anywhere, sigh: '
my $out_len = $dbh->{LongReadLen};
$out_len *= 2 if ($type_name =~ /RAW/i);

ok( $sth = $dbh->prepare("select midx, lng, dt from $table order by midx"), "select from table");
ok( $sth->execute, "execute select:" );
ok( $tmp = $sth->fetchall_arrayref );
is( $tmp->[0][1], substr($long_data0,0,$out_len),
	cdif($tmp->[0][1], substr($long_data0,0,$out_len), "Len ".length($tmp->[0][1])) );
is( $tmp->[1][1], substr($long_data1,0,$out_len),
	cdif($tmp->[1][1], substr($long_data1,0,$out_len), "Len ".length($tmp->[1][1])) );
is( $tmp->[2][1], substr($long_data2,0,$out_len),
	cdif($tmp->[2][1], substr($long_data2,0,$out_len), "Len ".length($tmp->[2][1])) );


print " --- fetch $type_name data back again -- truncated - LongTruncOk == 0\n";
$dbh->{LongReadLen} = $len_data1 - 10;
# so $long_data0 fits but long_data1 doesn't '
$dbh->{LongReadLen} = $dbh->{LongReadLen} / 2 if $type_name =~ /RAW/i;
$dbh->{LongTruncOk} = 0;
print "LongReadLen $dbh->{LongReadLen}, LongTruncOk $dbh->{LongTruncOk}\n";

ok($sth = $dbh->prepare("select midx, lng, dt from $table order by midx") );
ok($sth->execute );

ok($tmp = $sth->fetchrow_arrayref );
is($tmp->[1], $long_data0, " compare length : " . length($tmp->[1]));

ok( !defined $sth->fetchrow_arrayref,
	"truncation error not triggered "
	."(LongReadLen $dbh->{LongReadLen}, data ".length($tmp->[1]||0).")");
$tmp = $sth->err || 0;
ok( $tmp == 1406 || $tmp == 24345 );


print " --- fetch $type_name data back again -- complete - LongTruncOk == 0\n";
$dbh->{LongReadLen} = $len_data1 +1000;
$dbh->{LongTruncOk} = 0;
print "LongReadLen $dbh->{LongReadLen}, LongTruncOk $dbh->{LongTruncOk}\n";

ok( $sth = $dbh->prepare("select midx, lng, dt from $table order by midx") );
ok( $sth->execute );

ok( $tmp = $sth->fetchrow_arrayref );
# is( $tmp->[1], $long_data0, " compare length: " . length($tmp->[1]));

ok( $tmp = $sth->fetchrow_arrayref );
is( $tmp->[1], $long_data1, " compare length: " . length($tmp->[1]));

ok($tmp = $sth->fetchrow_arrayref, "fetchrow_arrayref to tmp" );
# is($tmp->[1], $long_data2, 'tmp[1] eq long_data2');
# ok( length($tmp->[1]) == length($long_data1)
#    and substr($tmp->[1], 0, length($long_data2)) eq $long_data2,
# 	"data match" );
# is( $tmp->[1], $long_data2, " compare lengths: " .
# 	cdif($tmp->[1],$long_data2, "Len ".length($tmp->[1])) );

print " --- fetch $type_name data back again -- via blob_read\n";
$dbh->{LongReadLen} = 1024 * 90;
$dbh->{LongTruncOk} =  1;
ok( $sth = $dbh->prepare("select midx, lng, dt from $table order by midx"), "prepare select" );
ok( $sth->execute, "execute select" );
ok( $tmp = $sth->fetchrow_arrayref, "fetchrow_arrayref" );

print "idx ", $tmp->[0], "\n";
is( blob_read_all($sth, 1, \$p1, 4096), length($long_data0), "blob_read_all: " );
is( $p1, $long_data0, " compare differences: " . cdif($p1, $long_data0));

ok( $tmp = $sth->fetchrow_arrayref, "fetchrow_arrayref: " );
print "idx ", $tmp->[0], "\n";
is( blob_read_all($sth, 1, \$p1, 12345), length($long_data1), "blob_read_all: ");
is( $p1, $long_data1, " compare differences: " . cdif($p1, $long_data1) );

ok( $tmp = $sth->fetchrow_arrayref, 1);
print "idx ", $tmp->[0], "\n";
my $len = blob_read_all($sth, 1, \$p1, 34567);

# if ($len == length($long_data2)) {
#     is( $len, length($long_data2), " length compare: " . length($len));
# 	# Oracle may return the right length but corrupt the string.
#     is( $p1, $long_data2, cdif($p1, $long_data2) );
# }
# elsif ($len == length($long_data1)
#    && substr($p1, 0, length($long_data2)) eq $long_data2
# ) {
#   pass( "Length correct" );
# }
# else {
#     fail("Fetched length $len, expected ".length($long_data2));
# }

$sth->finish;

return
} # end of run_long_tests

if ($failed) {
    warn "Meanwhile, if the other tests have passed you can use DBD::ADO.\n\n";
}

exit 0;

END {
    $dbh->do(qq{ drop table $table }) if $dbh;
}
# end.


# ----

sub create_table {
    my ($fields, $drop) = @_;
    my $sql = "create table $table ( $fields )";
    $dbh->do(qq{ drop table $table }) if $drop;
    $dbh->do($sql);
    if ($dbh->err && $dbh->err==955) {
	$dbh->do(qq{ drop table $table });
	warn "Unexpectedly had to drop old test table '$table'\n" unless $dbh->err;
	$dbh->do($sql);
    }
    return 0 if $dbh->err;
    print "$sql\n";
    return 1;
}

sub blob_read_all {
    my ($sth, $field_idx, $blob_ref, $lump) = @_;

    $lump ||= 4096; # use benchmarks to get best value for you
    my $offset = 0;
    my @frags;
    while (1) {
	my $frag = $sth->blob_read($field_idx, $offset, $lump);
	return unless defined $frag;
	my $len = length $frag;
	last unless $len;
	push @frags, $frag;
	$offset += $len;
    }
    $$blob_ref = join "", @frags;
    return length($$blob_ref);
}

sub unc {
    my @str = @_;
    foreach (@str) { s/([\000-\037\177-\377])/ sprintf "\\%03o", ord($_) /eg; }
    return join "", @str unless wantarray;
    return @str;
}

sub cdif {
    my ($s1, $s2, $msg) = @_;
    $msg = ($msg) ? ", $msg" : "";
    my ($l1, $l2) = (length($s1), length($s2));
    return "Strings are identical$msg" if $s1 eq $s2;
    return "Strings are of different lengths ($l1 vs $l2)$msg" # check substr matches?
	if $l1 != $l2;
    my $i;
    for($i=0; $i < $l1; ++$i) {
	my ($c1,$c2) = (ord(substr($s1,$i,1)), ord(substr($s2,$i,1)));
	next if $c1 == $c2;
        return sprintf "Strings differ at position %d (\\%03o vs \\%03o)$msg",
		$i,$c1,$c2;
    }
    return "(cdif error $l1/$l2/$i)";
}
