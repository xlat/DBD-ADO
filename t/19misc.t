#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use ADOTEST();

use Test::More;

if ( defined $ENV{DBI_DSN} ) {
  plan tests => 22;
} else {
  plan skip_all => 'Cannot test without DB info';
}

my ( $pf, $sf );

my $longstr = 'THIS IS A STRING LONGER THAN 80 CHARS.  THIS SHOULD BE CHECKED FOR TRUNCATION AND COMPARED WITH ITSELF.';
my $longstr2 = $longstr . '  ' . $longstr . '  ' . $longstr . '  ' . $longstr;

pass('Beginning test, modules loaded');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');


my $rc = 0;

ok( $rc = ADOTEST::tab_create( $dbh ),'Create test table');

ok( $rc = tab_insert( $dbh ),'Insert test data');
ok( $rc = tab_select( $dbh ),'Select test data');

$dbh->{LongReadLen} = 50;
$dbh->{LongTruncOk} = 1;
is( select_long( $dbh ), 1, 'Test LongTruncOk ON');

$dbh->{LongTruncOk} = 0;
is( select_long( $dbh ), 0, 'Test LongTruncOk OFF');

#
# some ADO drivers will prepare this OK, but not execute.
#
{
  # Turn the warnings off at this point.  Expecting statement to fail.
  local ( $dbh->{Warn}, $dbh->{RaiseError}, $dbh->{PrintError} );
  $dbh->{RaiseError} = $dbh->{PrintError} = $dbh->{Warn} = 0;

  my $sth = $dbh->prepare("SELECT XXNOTCOLUMN FROM $ADOTEST::table_name");
  $sth->execute if $sth;
  ok( $sth->err,'Check error returned, statement handle');
  ok( $dbh->err,'Check error returned, database handle');
  ok( $DBI::err,'Check error returned, DBI::err');
}

my $dt = qq{${pf}1998-05-13${sf}};
my $sth = $dbh->prepare("SELECT D FROM $ADOTEST::table_name WHERE D > $dt");
$sth->execute;
my $count = 0;
while ( my $row = $sth->fetch ) {
  $count++ if $row->[0];
  # print "$row->[0]\n";
}
ok( $count != 0,"Test date value: $dt");

$sth = $dbh->prepare("SELECT A, COUNT(*) FROM $ADOTEST::table_name GROUP BY A");
$sth->execute;
$count = 0;
while ( my $row = $sth->fetch ) {
  $count++ if $row->[0];
  # print "$row->[0], $row->[1]\n";
}
ok( $count != 0,'Test group by queries');


my $sth1 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A")
  or warn $dbh->errstr;
my $sth2 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A")
  or warn $dbh->errstr;
ok( defined $sth1,'Statement handle 1 created');
ok( defined $sth2,'Statement handle 2 created');

$sth1 = undef; $sth2 = undef; $sth = undef;

$count = 0;
$sth1 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name where A = ?")
  or warn $dbh->errstr;
ok( defined $sth1,'Prepared statement * and Parameter');

{
  # Turn PrintError and RaiseError off
  local ( $dbh->{PrintError}, $dbh->{RaiseError} );
  $dbh->{PrintError} = 0; $dbh->{RaiseError} = 0;
  $sth1 = $dbh->prepare("SELECT Stuff_and_Things FROM $ADOTEST::table_name where A = ?")
    or warn $dbh->errstr;
  ok( defined $sth1,'Prepared statement bad column and Parameter');

  my @row = $sth1->fetchrow;
  ok( $sth1->err,'Call to fetchrow without call to execute. ' . $sth1->errstr );
  ok( scalar @row == 0,'Call to fetchrow without call to execute, should return 0. ' . scalar @row );
}

{
  $count = 0;
  $sth1 = $dbh->prepare("SELECT * FROM $ADOTEST::table_name where A = ?")
    or warn $dbh->errstr;
  ok( defined $sth1,'Prepared statement * and Parameter');

  $sth1 = $dbh->prepare("SELECT Stuff_and_Things FROM $ADOTEST::table_name where A = ?")
    or warn $dbh->errstr;
  ok( defined $sth1,'Prepared statement bad column and Parameter');

  eval {
    local ( $sth1->{PrintError}, $sth1->{RaiseError} );
    $sth1->{PrintError} = 0; $sth1->{RaiseError} = 1;
    $sth1->execute( 99 );
    my @row = $sth1->fetchrow;
  };
  ok( defined $@,"RaiseError caught error:\n$@");
}

ok( $dbh->disconnect,'Disconnect');


sub tab_select
{
  my $dbh = shift;
  my $rowcount = 0;

  my $sth = $dbh->prepare("SELECT * FROM $ADOTEST::table_name ORDER BY A")
    or return undef;
  $sth->execute;
  while ( my $row = $sth->fetch ) {
    print "# -- $row->[0] $row->[1] $row->[2] $row->[3]\n";
    ++$rowcount;
  }
  if ( $rowcount == 0 ) {
    print "# -- Basic retrieval of rows not working!\n";
    return;
  }

  $sth = $dbh->prepare("SELECT A,C FROM $ADOTEST::table_name WHERE A>=4")
    or return undef;
  $rowcount = 0;
  $sth->execute;
  while ( my $row = $sth->fetch ) {
    $rowcount++;
    if ( $row->[0] == 4 ) {
      if ( $row->[1] eq $longstr ) {
        print '# -- Retrieved ', length( $longstr ), " byte string OK\n";
      } else {
        print "# -- Basic retrieval of longer rows not working!\n-- Retrieved value = $row->[0]\n";
        return 0;
      }
    } elsif ( $row->[0] == 5 ) {
      if ( $row->[1] eq $longstr2 ) {
        print '# -- Retrieved ', length( $longstr2 ), " byte string OK\n";
      } else {
        print "# -- Basic retrieval of row longer than 255 chars not working!",
            "\n-- Retrieved ", length( $row->[1] ), ' bytes instead of ',
            length( $longstr2 ), "\n-- Retrieved value = $row->[1]\n";
        return 0;
      }
    }
  }
  if ( $rowcount == 0 ) {
    print "# -- Basic retrieval of rows not working!\n-- Rowcount = $rowcount\n";
    return 0;
  }
  return 1;
}

#
# show various ways of inserting data without binding parameters.
# Note, these are not necessarily GOOD ways to show this...
#
sub tab_insert {
  my $dbh = shift;

  # Determine if an escape sequence is usable.
  my $ti = ADOTEST::get_type_for_column( $dbh,'D');
# while ( my ( $k, $v ) = each %$ti ) { print "#  $k => $v\n" }
  $pf = $ti->{LITERAL_PREFIX};
  $sf = $ti->{LITERAL_SUFFIX};
  $pf = qq/{d \'/ unless $pf;  # '
  $sf = qq/\' }/  unless $sf;  # '
  # qeDBF needs a space after the table name!

  print "# -- Building dates using: $pf $sf\n";
  my $dt = qq{${pf}1998-05-10${sf}};
  my $stmt = "INSERT INTO $ADOTEST::table_name ( A, B, C, D ) VALUES ("
    . join(', ', 3, $dbh->quote('bletch'), $dbh->quote('bletch varchar'), $dt ) . ')';
  my $sth = $dbh->prepare( $stmt ) or die "prepare: $stmt: $DBI::errstr";
  $sth->execute or die "execute: $stmt: $DBI::errstr";
  $sth->finish;

  $dt = qq{${pf}1998-05-11${sf}};
  $dbh->do( qq{INSERT INTO $ADOTEST::table_name ( A, B, C, D ) VALUES ( 1, 'foo', 'foo varchar', $dt )} );
  $dt = qq{${pf}1998-05-12${sf}};
  $dbh->do( qq{INSERT INTO $ADOTEST::table_name ( A, B, C, D ) VALUES ( 2, 'bar', 'bar varchar', $dt )} );
  $dt = qq{${pf}1998-05-13${sf}};
  print '# -- Length of long string ', length( $longstr ), "\n";
  $stmt = "INSERT INTO $ADOTEST::table_name ( A, B, C, D ) VALUES ("
    . join(', ', 4, $dbh->quote('80char'), $dbh->quote( $longstr ), $dt ) . ')';
  $sth = $dbh->prepare( $stmt ) or die "prepare: $stmt: $DBI::errstr";
  $sth->execute or die "execute: $stmt: $DBI::errstr";
  $sth->finish;
  $dt = qq{${pf}1998-05-14${sf}};
  print '# -- Length of long string 2 ', length( $longstr2 ), "\n";
  $stmt = "INSERT INTO $ADOTEST::table_name ( A, B, C, D ) VALUES ("
    . join(', ', 5, $dbh->quote('gt250char'), $dbh->quote( $longstr2 ), $dt ) . ')';
  $sth = $dbh->prepare( $stmt ) or die "prepare: $stmt: $DBI::errstr";
  $sth->execute or die "execute: $stmt: $DBI::errstr";
  $sth->finish;
  return 1;
}

sub select_long
{
  my $dbh = shift;
  my $rc = 0;

  local $dbh->{RaiseError} = 1;
  local $dbh->{PrintError} = 0;
  my $sth = $dbh->prepare("SELECT A,C FROM $ADOTEST::table_name WHERE A=4");
  if ( $sth ) {
    $sth->execute;
    eval {
      while ( my $row = $sth->fetch ) {
      }
    };
    $rc = 1 unless $@;
  }
  $rc;
}
