#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:ai:aw:nu:
$| = 1;

# XXX This file should be named XXtimeout.t.
# XXX A separate XXXwarn.t would be useful.
# XXX Is there a portable way to implement these tests?

# Generate large number of test rows.

use strict;
use warnings;
use DBI();
#use Time::HiRes qw(gettimeofday tv_interval);

use Test::More;

if (defined $ENV{DBI_DSN}) {
	plan tests => 2;
} else {
	plan skip_all => 'Cannot test without DB info';
}

#use constant MAX_ROWS => 200;

pass('Beginning test, modules loaded');

my $att = { ado_commandtimeout => 20 };  # ado_cursortype => 'adOpenStatic'

my $dbh = DBI->connect( $ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, $att )
  or die "Connect failed: $DBI::errstr\n";
pass('Database connection created');

#my $sth = $dbh->prepare(q{select * from products});
#ok( defined $sth, "Prepared select statement" );
#$sth->execute;
#$sth->dump_results;

$dbh->disconnect;
