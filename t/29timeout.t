#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use ADOTEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 7;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('Timeout tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

SKIP: {
  skip('SQLOLEDB specific tests', 4 )
    if $dbh->{ado_conn}{Provider} !~ /^SQLOLEDB/;

  $dbh->{AutoCommit} = 0;

  my $proc = $ADOTEST::table_name . '_WAIT';

  my $sql = "CREATE PROCEDURE $proc AS waitfor delay '00:00:07'";

  ok( $dbh->do( $sql ), $sql );

  ok( $dbh->do( $proc ), $proc );

  $dbh->{ado_commandtimeout} = 2;
  $dbh->{RaiseError} = 1;
  $dbh->{PrintError} = 0;
  $dbh->{Warn}       = 0;

  my $rc = eval { $dbh->do( $proc ) };
  ok(!$rc,"$proc (timeout=$dbh->{ado_commandtimeout})");
  like( $@, qr/HYT00/,'Error expected: HYT00');

  # TODO: uninitialized ... Why?
  #like( $dbh->errstr, qr/Timeout expired/, "Error expected: Timeout expired");  # language dependent?
  #like( $dbh->errstr, qr/HYT00/          ,'Error expected: HYT00');
  #is  ( $dbh->state ,'HYT00'             ,'SQLState');
  #is  ( $dbh->err   , -2147217871        ,'Error Number'); # 0x80040E31
}
ok( $dbh->disconnect,'Disconnect');
