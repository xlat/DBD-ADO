#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use ADOTEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 21;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Timeout tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

SKIP: {
  skip('SQLOLEDB specific tests', 18 )
    if $dbh->{ado_conn}{Provider} !~ /^SQLOLEDB/;

  $dbh->{AutoCommit} = 0;

  my $proc = $ADOTEST::table_name . '_WAIT';

  my $sql = "CREATE PROCEDURE $proc AS waitfor delay '00:00:07'";

  ok( $dbh->do( $sql ),"do: $sql");

  is( $dbh->{ado_commandtimeout}, 30,'dbh ado_commandtimeout');

  ok( $dbh->do( $proc ),"do: $proc");

  $dbh->{ado_commandtimeout} = 2;
  is( $dbh->{ado_commandtimeout}, 2,'dbh ado_commandtimeout');

  $dbh->{PrintError} = 0;
  $dbh->{Warn}       = 0;

  ok(!$dbh->do( $proc ),"do: $proc (timeout=$dbh->{ado_commandtimeout})");

  like( $dbh->errstr, qr/HYT00/          ,'Error expected: HYT00');
# like( $dbh->errstr, qr/Timeout expired/,'Error expected: Timeout expired');  # language dependent?
  is  ( $dbh->state ,'HYT00'             ,'SQLState');
  is  ( $dbh->err   , -2147217871        ,'Error Number');  # 0x80040E31

  my $sth = $dbh->prepare( $proc );
  is( $sth->{ado_commandtimeout}, 2,'sth ado_commandtimeout');

  ok(!$sth->execute,'execute');
  like( $sth->errstr, qr/HYT00/          ,'Error expected: HYT00');
  is  ( $sth->state ,'HYT00'             ,'SQLState');
  is  ( $sth->err   , -2147217871        ,'Error Number');

  $sth->{ado_commandtimeout} = 1;
  is( $sth->{ado_commandtimeout}, 1,'sth ado_commandtimeout');

  ok(!$sth->execute,'execute');
  like( $sth->errstr, qr/HYT00/          ,'Error expected: HYT00');
  is  ( $sth->state ,'HYT00'             ,'SQLState');
  is  ( $sth->err   , -2147217871        ,'Error Number');
}
ok( $dbh->disconnect,'Disconnect');
