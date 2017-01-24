#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use DBD_TEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 9;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('More results tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

my $tbl = $DBD_TEST::table_name;

ok( DBD_TEST::tab_create( $dbh ),"CREATE TABLE $tbl");

my $info =  $dbh->get_info( 36 );
ok( ( $info eq 'Y') || ( $info eq 'N'),'SQL_MULT_RESULT_SETS is Y/N');

sub fetch_everything {
  my $sth = shift;
  my @a;
  do
  {
    push @a, $sth->{NUM_OF_FIELDS} ? $sth->fetchall_arrayref : [ undef ];
  }
  while ( $sth->more_results );
  return @a;
}

SKIP: {
  skip('More results not supported', 2 ) unless $info eq 'Y';

  my $sth = $dbh->prepare(<<"SQL");
SELECT A                  FROM $tbl;
INSERT                    INTO $tbl( A ) VALUES( ? );
SELECT A                  FROM $tbl;
SELECT A, 2  AS B, 3 AS C FROM $tbl;
INSERT                    INTO $tbl( A ) VALUES( ? );
SELECT A,'b' AS B         FROM $tbl;
DELETE                    FROM $tbl;
SQL
  ok( defined $sth,'Statement handle defined');
  $sth->execute( 7, 8 );
  my @a = fetch_everything( $sth );
  my @b =
  (
    []
  , [ undef ]
  , [ [ 7 ] ]
  , [ [ 7, 2, 3 ] ]
  , [ undef ]
  , [ [ 7,'b']
    , [ 8,'b'] ]
  , [ undef ]
  );
  is_deeply( \@a, \@b,'Results o.k.');
  
  #test with stored procedure
  $sth = $dbh->prepare("exec sp_helpconstraint '$tbl'");
  ok( defined $sth,'Statement handle defined for stored proc');
  $sth->execute;
  @a = fetch_everything( $sth );
  @b = (
    [ [ $tbl ] ],
    [ undef ],
  );
  is_deeply( \@a, \@b,'Results o.k. for stored procedure') or do {
	use Data::Dumper;
	print "got: \n",Dumper( \@a );
	print "expected: \n", Dumper( \@b );
  };
  
}

ok( $dbh->disconnect,'Disconnect');
