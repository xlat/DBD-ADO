#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use ADOTEST();

use Test::More;

if ( defined $ENV{DBI_DSN} ) {
  plan tests => 14;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('NULL tests');

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
   $dbh->{RaiseError} = 1;
   $dbh->{PrintError} = 0;
pass('Database connection created');

my $tbl = $ADOTEST::table_name;
my @col = sort keys %ADOTEST::TestFieldInfo;

ok( ADOTEST::tab_create( $dbh ),"CREATE TABLE $tbl");

for ( @col ) {
  ok( $dbh->do("INSERT INTO $tbl( $_ ) VALUES( ? )", undef, undef ),"Inserting NULL into $_");
}

my $Cols = join ', ', @col;
my $Qs   = join ', ', map {'?'} @col;
my $sth = $dbh->prepare("INSERT INTO $tbl( $Cols ) VALUES( $Qs )");
ok( defined $sth,'Prepare insert statement');

my $i = 0;
for ( @col ) {
  my @row = ADOTEST::get_type_for_column( $dbh, $_ );
  ok( $sth->bind_param( ++$i, undef, { TYPE => $row[0]->{DATA_TYPE} } ),"Bind parameter for column $_");
}
ok( $sth->execute,'Execute prepared statement with bind params');

ok( $dbh->disconnect,'Disconnect');
