#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();
use ADOTEST();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 3;
} else {
  plan skip_all => 'Cannot test without DB info';
}

my $dbh = DBI->connect or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh, 'Connection');

# -----------------------------------------------------------------------------
SKIP: {
  local ($dbh->{Warn}, $dbh->{PrintError});
  $dbh->{PrintError} = $dbh->{Warn} = 0;
  my $sth = $dbh->foreign_key_info( undef, undef, undef, undef, undef, undef );
  my $non_supported = '-2146825037';
  skip 'foreign_key_info not supported by provider', 1
    if $dbh->err && $dbh->err == $non_supported;
  ok( defined $sth,"Statement handle defined for foreign_key_info()");
  DBI::dump_results($sth) if defined $sth;
}
# -----------------------------------------------------------------------------

ok( $dbh->disconnect,'Disconnect');
