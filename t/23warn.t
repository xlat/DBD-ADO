#!/usr/bin/perl -I./t
# vim:ts=2:sw=2:ai:aw:nu:
$| = 1;

# Generate large number of test rows.

use strict;
use warnings;
use DBI qw(:sql_types);
use Time::HiRes qw(gettimeofday tv_interval);

use Data::Dumper;

use vars qw($tests $table_name);
use constant MAX_ROWS => 200;

$table_name = "products";

use Test::More tests => 3;

pass( "Begining test, modules loaded" );

my $dbh = DBI->connect( $ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
	{
		ado_commandtimeout	=> 20
	}) 
	or die "Connect failed: $DBI::errstr\n";
		  # ado_cursortype			=> 'adOpenStatic'
pass( "Database connection created." );

my $sth = $dbh->prepare(q{select * from products});
ok( defined $sth, "Prepared select statement" );
$sth->execute;
$sth->dump_results;
$dbh->disconnect();

__END__
