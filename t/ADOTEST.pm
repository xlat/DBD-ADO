#
# Package ADOTEST
# vim:ts=2:sw=2:ai:aw:
# 
# This package is a common set of routines for the DBD::ADO tests.
# This is a set of routines to create, drop and test for existance of
# a table for a given DBI database handle (dbh).
#
# This set of routines currently depends greatly upon some ADO meta-data.
# The meta data required is the driver's native type name for various ADO/DBI
# SQL types.  For example, SQL_VARCHAR would produce VARCHAR2 under Oracle and TEXT
# under MS-Access.  This uses the function SQLGetTypeInfo.  This is obtained via
# the DBI C<func> method, which is implemented as a call to the driver.  In this case,
# of course, this is the DBD::ADO.
#
# the SQL_TIMESTAMP may be dubious on many platforms, but SQL_DATE was not supported
# under Oracle, MS SQL Server or Access.  Those are pretty common ones.
#

require 5.004;
{
    package ADOTEST;

    use DBI qw(:sql_types);

    $VERSION = '0.01';
    $table_name = "PERL_DBD_TEST";

    %TestFieldInfo = (
	'A' => [SQL_SMALLINT, SQL_TINYINT, SQL_NUMERIC, SQL_DECIMAL, SQL_FLOAT, SQL_REAL, SQL_DOUBLE],
	'B' => [SQL_WVARCHAR, SQL_VARCHAR, SQL_WCHAR, SQL_CHAR],
	'C' => [SQL_WLONGVARCHAR, SQL_LONGVARCHAR, SQL_WVARCHAR, SQL_VARCHAR],
	'D' => [SQL_DATE, SQL_TIMESTAMP],
    );

    %LTestFieldInfo = (
			'dt' => [SQL_DATE, SQL_TIMESTAMP],
    );

sub get_type_for_column {
	my $dbh = shift;
	my $column = shift;

	my $type;
	my @row;
	my $sth;
	foreach $type (@{ $TestFieldInfo{$column} }) {
	    @row = $dbh->type_info($type);
	    # may not correct behavior, but get the first compat type
			#print "Type $type rows: ", scalar(@row), "\n";
	    last if @row;
	}
	die "Unable to find a suitable test type for field $column"
	    unless @row;
	return @row;
}
	
sub tab_create {
	my $dbh = shift;
			{
				local ($dbh->{PrintError}, $dbh->{RaiseError}, $dbh->{Warn});
				$dbh->{PrintError} = $dbh->{RaiseError} = $dbh->{Warn} = 0;
	    	$dbh->do("DROP TABLE $table_name");
			}

	# $dbh->{PrintError} = 1;

	# trying to use ADO to tell us what type of data to use,
	# instead of the above.
	my $fields = undef;
	my ($f,$r);
	foreach $f (sort keys %TestFieldInfo) {
	    #print "$f: @{$TestFieldInfo{$f}}\n";
	    $fields .= ", " unless !$fields;
	    $fields .= "$f ";
	    print "-- $fields\n";

	    my @row = get_type_for_column($dbh, $f);
			shift @row if ($row[0])->{TYPE_NAME} =~ /identity$/i;
			shift @row if ($row[0])->{TYPE_NAME} =~ /nclob/i;

			#my $rchk = ($row[0])->{DATA_TYPE};

			$r = shift @row;

	    $fields .= $r->{TYPE_NAME};

			# Oracle is having problems with nvarchar2(4000), cut the column size in
			# half, for now.
			if (defined $r->{CREATE_PARAMS}) {
				$fields .= qq{(} . int($r->{COLUMN_SIZE}/2) . qq{)} 
					if ($r->{CREATE_PARAMS} =~ /LENGTH/i);
				$fields .= qq{(} . $r->{COLUMN_SIZE} . qq{, 0)} 
					if ($r->{CREATE_PARAMS} =~ /PRECISION,SCALE/i);
			}
print "-- $fields\n";
}
print "Using fields: $fields\n";
return $dbh->do(qq{CREATE TABLE $table_name ($fields)});
}


    sub tab_delete {
			my $dbh = shift;
			$dbh->do("DELETE FROM $table_name");
    }

    sub tab_exists {
	my $dbh = shift;
	my (@rows, @row, $rc);

	$rc = -1;

	unless ($sth = $dbh->table_info()) {
	    print "Can't list tables: $DBI::errstr\n";
	    return -1;
	}
	# TABLE_QUALIFIER,TABLE_OWNER,TABLE_NAME,TABLE_TYPE,REMARKS
	while ($row = $sth->fetchrow_hashref()) {
	    # XXX not fully true.  The "owner" could be different.  Need to check!
	    # In Oracle, testing $user against $row[1] works, but does NOT in SQL Server.
	    # SQL server returns the device and something else I haven't quite taken the time
	    # to figure it out, since I'm not a SQL server expert.  Anyone out there?
	    # (mine returns "dbo" for the owner on ALL my tables.  This is obviously something
	    # significant for SQL Server...one of these days I'll dig...
	    if (($table_name eq uc($row->{TABLE_NAME}))) {
		# and (uc($user) eq uc($row[1]))) 
		# qeDBF driver returns null for TABLE_OWNER
		my $owner = $row->{TABLE_OWNER} || '(unknown owner)';
		print "$owner.$row->{TABLE_NAME}\n";
		$rc = 1;
		last;
	    }
	}
	$sth->finish();
	$rc;
    }

sub tab_long_create {
	my $dbh = shift;
	my ($idx, $idx_type, $idx_num,
		$col_name, $lng_type, $type_num) = @_;
	my $table_name = qw/perl_dbd_ado_long/;
	{
			local ($dbh->{PrintError});
			$dbh->{PrintError} = 0;
    	$dbh->do("DROP TABLE $table_name");
	}


#	$dbh->{PrintError} = 1;

	# trying to use ADO to tell us what type of data to use,
	# instead of the above.
	my $fields = undef;
	my @row = $dbh->type_info( $idx_num );
	$fields .= "$idx ";
	shift @row if ($row[0])->{TYPE_NAME} =~ /identity$/;
	$r = shift @row;
	$fields .= $r->{TYPE_NAME};
	if ($r->{CREATE_PARAMS}) {
		$fields .= qq{(} . $r->{COLUMN_SIZE} . qq{)} 
		if ($r->{CREATE_PARAMS} =~ /LENGTH/i);
			$fields .= qq{(} . $r->{COLUMN_SIZE} . qq{, 0)} 
		if ($r->{CREATE_PARAMS} =~ /PRECISION,SCALE/i);
  }

	# Determine the "long" type here.
	@row = $dbh->type_info( $type_num );
	foreach my $rt ( @row ) {
		next if ( $rt->{TYPE_NAME} =~ m/nclob/i );
		next if ( $rt->{TYPE_NAME} =~ m/raw/i );
		next if ($row[0])->{TYPE_NAME} =~ /identity$/i;
		$fields .= ", ";
		$fields .= "$col_name ";
		$fields .= $rt->{TYPE_NAME};
		if ($rt->{CREATE_PARAMS}) {
			$fields .= qq{(} . $rt->{COLUMN_SIZE} . qq{)} 
			if ($rt->{CREATE_PARAMS} =~ /LENGTH/i);
				$fields .= qq{(} . $rt->{COLUMN_SIZE} . qq{, 0)} 
			if ($rt->{CREATE_PARAMS} =~ /PRECISION,SCALE/i);
		}
		last;
	}

	my ($f,$r);
	foreach $f (sort keys %LTestFieldInfo) {
	    $fields .= ", " unless !$fields;
	    $fields .= "$f ";
	    print "-- $fields\n";
	    @row = get_long_type_for_column($dbh, $f);
			shift @row if ($row[0])->{TYPE_NAME} =~ /identity$/;
			my $rchk = ($row[0])->{DATA_TYPE};
			
			$r = shift @row;
	    $fields .= $r->{TYPE_NAME};
	    if ($r->{CREATE_PARAMS}) {
		$fields .= qq{(} . $r->{COLUMN_SIZE} . qq{)} 
			if ($r->{CREATE_PARAMS} =~ /LENGTH/i);
		$fields .= qq{(} . $r->{COLUMN_SIZE} . qq{, 0)} 
			if ($r->{CREATE_PARAMS} =~ /PRECISION,SCALE/i);
	    }

	    print "-- $fields\n";
	}

	print "Using fields: $fields\n";
	return $dbh->do(qq{CREATE TABLE $table_name ($fields)});
}

sub get_long_type_for_column {
	my $dbh = shift;
	my $column = shift;

	my @row;
	foreach $type (@{ $LTestFieldInfo{$column} }) {
	    @row = $dbh->type_info($type);
	    # may not correct behavior, but get the first compat type
			#print "Type $type rows: ", scalar(@row), "\n";
	    last if @row;
	}
	die "Unable to find a suitable test type for field $column"
	    unless @row;
	return @row;
}
	
    1;
}

