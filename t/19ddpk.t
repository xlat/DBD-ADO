#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:ai:aw:nu:
$| = 1;

use strict;
use ADOTEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
	plan tests => 8;
} else {
	plan skip_all => 'Cannot test without DB info';
}

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh, 'Connection');

my $catalog = undef;  # TODO: current catalog?
my $schema  = undef;  # TODO: current schema?
my $table   = $ADOTEST::table_name;

my @types = ADOTEST::get_type_for_column( $dbh, 'A');
ok( @types > 0, 'Type info');
my $type = $types[0];

{
	local ($dbh->{Warn}, $dbh->{PrintError});
	$dbh->{PrintError} = $dbh->{Warn} = 0;
	$dbh->do("DROP TABLE $table");
}

# Oracle constraint ...
# CONSTRAINT pk_docindex PRIMARY KEY (token, doc_oid)

my $sql = <<"SQL";
CREATE TABLE $table
(
		K1 $type->{TYPE_NAME}
	, K2 $type->{TYPE_NAME}
	, CONSTRAINT ${table}_pk PRIMARY KEY (K1, K2)
)
SQL
print $sql;

ok( $dbh->do( $sql ), 'Create table');

{
  my $sth = $dbh->primary_key_info( $catalog, $schema, $table );
  ok( defined $sth, 'Statement handle defined');

  print "Primary key columns:\n";
  my @cols;
  while ( my $row = $sth->fetch )
  {
    local $^W = 0;
    local $,  = "\t";
    print @$row, "\n";
    push @cols, $row->[3];
  }
  is( @cols, 2, 'Primary key columns');
  for ( 1, 2 )
  {
    is( $cols[$_-1], 'K' . $_, 'Primary key column names');
  }
}

ok(!$dbh->disconnect, q{Disconnect});

exit;

END {}
__END__
