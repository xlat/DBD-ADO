#!/usr/bin/perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 6;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Beginning test, modules loaded');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

#### testing Tim's early draft DBI methods #'

$dbh->{AutoCommit} = 0;
my $sth;

$dbh->do(q(INSERT INTO PERL_DBD_TEST( A, B ) VALUES( 10,'Stuff here')));

$sth = $dbh->prepare('DELETE FROM PERL_DBD_TEST');
$sth->execute;
my $s = $sth->rows;
my $t = $DBI::rows;
is( $s, $t,"sth->rows: $s DBI::rows: $t");

$dbh->rollback;

$sth = $dbh->prepare('SELECT * FROM PERL_DBD_TEST WHERE 1 = 0');
$sth->execute;
my @row = $sth->fetchrow;
if ( $sth->err ) {
  print ' $sth->err   : ', $sth->err   , "\n";
  print ' $sth->errstr: ', $sth->errstr, "\n";
  print ' $dbh->state : ', $dbh->state , "\n";
# print ' $sth->state : ', $sth->state , "\n";
}
pass("Fetched empty result set: (@row)");

$sth = $dbh->prepare('SELECT A, B FROM PERL_DBD_TEST');
$sth->execute;
while ( my $row = $sth->fetch ) {
  print ' @row     a,b:', $row->[0], ',', $row->[1], "\n";
}

my $Ok;
$Ok = 1;
my ( $a, $b );
$sth->execute;
$sth->bind_col( 1, \$a );
$sth->bind_col( 2, \$b );
while ( $sth->fetch ) {
  print ' bind_col a,b:', $a, ',', $b, "\n";
  unless ( defined( $a ) && defined( $b ) ) {
    $Ok = 0;
    $sth->finish;
    last;
  }
}
is( $Ok, 1, 'All fields defined');

$Ok = 1;
( $a, $b ) = ( undef, undef );
$sth->execute;
$sth->bind_columns( undef, \$b, \$a );
while ( $sth->fetch )
{
  print ' bind_columns a,b:', $b, ',', $a, "\n";
  unless ( defined( $a ) && defined( $b ) ) {
    $Ok = 0;
    $sth->finish;
    last;
  }
}
is( $Ok, 1, 'All fields defined');

# turn off error warnings.  We expect one here (invalid transaction state)
$dbh->{RaiseError} = 0;
$dbh->{PrintError} = 0;
$dbh->disconnect;
