#!perl -I./t
# vim:ts=2:sw=2:ai:aw:nu:

$| = 1;

use strict;
use warnings;
use DBI ();
use ADOTEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 16;
} else {
  plan skip_all => 'Cannot test without DB info';
}

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh,'Connection');

# Test the different methods, so are expected to fail.

# XXX

my $sth;

eval {
  ok( $dbh->ping,'Testing Ping');
};
ok ( !$@,'Ping Tested');

eval {
  $sth = $dbh->type_info_all;
};
ok ( ( !$@ and defined $sth ),'type_info_all tested');
$sth = undef;

eval {
  my @types = $dbh->type_info;
  die unless @types;
};
ok ( !$@,'type_info( undef )');
$sth = undef;

eval {
  $dbh->quote
};
ok( $@,"Call to quote() with 0 arguments, error expected: $@ ");

my @qt_vals   = (   1  ,    2  , undef ,   'NULL' ,   'ThisIsAString',    'This is Another String' );
my @expt_vals = (q{'1'}, q{'2'}, 'NULL', q{'NULL'}, q{'ThisIsAString'}, q{'This is Another String'});
for ( my $x = 0; $x <= $#qt_vals; $x++ ) {
  my $val1 = defined $qt_vals[$x] ? $qt_vals[$x] : 'undef';
  my $val = $dbh->quote( $qt_vals[$x] );
  is( $val, $expt_vals[$x],"$x: quote on $val1 returned $val");
}
is( $dbh->quote( 1, DBI::SQL_INTEGER() ), 1,'quote( 1, SQL_INTEGER )');

eval { $dbh->quote_identifier };

ok( $@,"Call to quote_identifier() with 0 arguments, error expected: $@ ");

my $qt  = $dbh->get_info( 29 );  # SQL_IDENTIFIER_QUOTE_CHAR
my $sep = $dbh->get_info( 41 );  # SQL_CATALOG_NAME_SEPARATOR

my $cmp_str = qq{${qt}link${qt}${sep}${qt}schema${qt}${sep}${qt}table${qt}};
is( $dbh->quote_identifier( "link", "schema", "table" )
  , $cmp_str
  , q{quote_identifier( "link", "schema", "table" )}
);

ok( $dbh->disconnect,'Disconnect');
