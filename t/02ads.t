#!perl -I./t

$| = 1;

use strict;
use warnings;
use DBI();

use Test::More;

if (defined $ENV{DBI_DSN}) {
  plan tests => 2;
} else {
  plan skip_all => 'Cannot test without DB info';
}

pass('ADO data sources tests');

my @ds = DBI->data_sources('ADO');

print "\n# ADO data sources:\n";
print '# ', $_, "\n" for @ds;

pass('ADO data sources tested');
