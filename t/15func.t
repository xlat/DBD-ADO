#!/usr/bin/perl -I./t
$| = 1;

# vim:ts=2:sw=2:ai:aw:nu:
use DBI qw(:sql_types);
use ADOTEST;
use Data::Dumper;
use strict;
my ($pf, $sf);

use Test::More tests => 8;

BEGIN { use_ok( 'DBD::ADO' ); }

my $non_supported = '-2146825037';

my $dbh = DBI->connect() or die "Connect failed: $DBI::errstr\n";
ok ( defined $dbh, "Connection" ); # print "ok 2\n";

# Test call to primary_key_info

my $sth = $dbh->primary_key_info(undef, undef, undef );
ok( defined $dbh->err, "Call dbh->primary_key_info() ... " );
ok( defined $sth, "Statement handle defined for primary_key_info()" );

while( my $row = $sth->fetchrow_arrayref ) {
	{
		local $^W = 0;
		print join( ", ", @$row, "\n" );	
	}
}

undef $sth;

eval {
	$sth = $dbh->primary_key_info();
};
ok ($@, "Call to primary_key_info with 0 arguements, error expected: $@" );

$sth = $dbh->primary_key_info(undef, undef, undef );
ok( defined $dbh->err, "Call dbh->primary_key_info() ... " .
	($dbh->err? $dbh->errstr : 'no error message' ));
ok( defined $sth, "Statement handle defined for primary_key_info()" );

my ( %catalogs, %schemas, %tables);

my $cnt = 0;
while( my ($catalog, $schema, $table) = $sth->fetchrow_array ) {
	$catalogs{$catalog}++	if $catalog;
	$schemas{$schema}++		if $schema;
	$tables{$table}++			if $table;
	$cnt++;
}

ok( $cnt > 0, "At least one table has a primary key." );
print "\nUnique Catalogs: \n\t", join( "\n\t", sort keys %catalogs ), "\n";
print "\nUnique Schemas : \n\t", join( "\n\t", sort keys %schemas ), "\n";
print "\nUnique Tables  : \n\t", join( "\n\t", sort keys %tables ), "\n";

exit(0);

