package ADOTEST;

=head1 DESCRIPTION

This package is a common set of routines for the DBD::ADO tests.
This is a set of routines to create, drop and test for existance of
a table for a given DBI database handle (dbh).

This set of routines currently depends greatly upon some ADO meta-data.
The meta data required is the driver's native type name for various ADO/DBI
SQL types. For example, SQL_VARCHAR would produce VARCHAR2 under Oracle and
TEXT under MS-Access. This uses the type_info() method.

The SQL_TIMESTAMP may be dubious on many platforms, but SQL_DATE was not
supported under Oracle, MS SQL Server or Access. Those are pretty common ones.

=cut

use strict;
use warnings;
use DBI qw(:sql_types);

use vars qw($VERSION $table_name %TestFieldInfo %LTestFieldInfo);

$VERSION = '0.05';
$table_name = 'PERL_DBD_TEST';

%TestFieldInfo = (
 'A' => [SQL_INTEGER, SQL_SMALLINT, SQL_TINYINT, SQL_NUMERIC, SQL_DECIMAL, SQL_FLOAT, SQL_REAL, SQL_DOUBLE]
,'B' => [SQL_WVARCHAR, SQL_VARCHAR, SQL_WCHAR, SQL_CHAR]
,'C' => [SQL_WLONGVARCHAR, SQL_LONGVARCHAR, SQL_WVARCHAR, SQL_VARCHAR]
,'D' => [SQL_TYPE_DATE, SQL_TYPE_TIMESTAMP, SQL_DATE, SQL_TIMESTAMP]
);

%LTestFieldInfo = (
 'dt' => [SQL_TYPE_DATE, SQL_TYPE_TIMESTAMP, SQL_DATE, SQL_TIMESTAMP]
);

sub get_type_for_column {
  my $dbh = shift;
  my $col = shift;

  $dbh->type_info( $TestFieldInfo{$col} );
}

sub tab_create {
  my $dbh = shift;
  my $tbl = shift || $table_name;
  {
    local ($dbh->{PrintError}, $dbh->{RaiseError}, $dbh->{Warn});
    $dbh->{PrintError} = $dbh->{RaiseError} = $dbh->{Warn} = 0;
    $dbh->do("DROP TABLE $tbl");
  }
  # trying to use ADO to tell us what type of data to use, instead of the above.
  my $fields = undef;
  for my $f ( sort keys %TestFieldInfo ) {
    #print "# $f: @{$TestFieldInfo{$f}}\n";
    $fields .= ', ' unless !$fields;
    $fields .= "$f ";
    print "# -- $fields\n";

    my @ti = get_type_for_column( $dbh, $f );
    shift @ti if ($ti[0])->{TYPE_NAME} =~ /identity$/i;
    shift @ti if ($ti[0])->{TYPE_NAME} =~ /nclob/i;

    my $ti = shift @ti;

    $fields .= $ti->{TYPE_NAME};

    # Oracle is having problems with nvarchar2(4000), cut the column size in
    # half, for now.
    if ( defined $ti->{CREATE_PARAMS} ) {
      $fields .= '(' . int( $ti->{COLUMN_SIZE} / 2 ) . ')'  # /
        if $ti->{CREATE_PARAMS} =~ /LENGTH/i;
      $fields .= '(' . $ti->{COLUMN_SIZE} . ', 0)'
        if $ti->{CREATE_PARAMS} =~ /PRECISION,SCALE/i;
    }
    print "# -- $fields\n";
  }
  print "# Using fields: $fields\n";
  return $dbh->do("CREATE TABLE $tbl( $fields )");
}

sub tab_delete {
  my $dbh = shift;
  $dbh->do("DELETE FROM $table_name");
}

sub tab_exists {
  my $dbh = shift;
  my $rc = -1;
  my $sth = $dbh->table_info;

  unless ( $sth ) {
    print "# Can't list tables: $DBI::errstr\n";
    return -1;
  }
  # TABLE_QUALIFIER,TABLE_OWNER,TABLE_NAME,TABLE_TYPE,REMARKS
  while ( my $row = $sth->fetchrow_hashref ) {
    # XXX not fully true.  The "owner" could be different.  Need to check!
    # In Oracle, testing $user against $row[1] works, but does NOT in SQL Server.
    # SQL server returns the device and something else I haven't quite taken the time
    # to figure it out, since I'm not a SQL server expert.  Anyone out there?
    # (mine returns "dbo" for the owner on ALL my tables.  This is obviously something
    # significant for SQL Server...one of these days I'll dig...
    if ( $table_name eq uc( $row->{TABLE_NAME} ) ) {
      # and (uc($user) eq uc($row[1])))
      # qeDBF driver returns null for TABLE_OWNER
      my $owner = $row->{TABLE_OWNER} || '(unknown owner)';
      print "# $owner.$row->{TABLE_NAME}\n";
      $rc = 1;
      last;
    }
  }
  $sth->finish;
  $rc;
}

sub tab_long_create {
  my $dbh = shift;
  my ($idx, $idx_type, $idx_num, $col_name, $lng_type, $type_num) = @_;
  my $table_name = 'PERL_DBD_ADO_LONG';
  {
    local ($dbh->{PrintError});
    $dbh->{PrintError} = 0;
    $dbh->do("DROP TABLE $table_name");
  }
  # trying to use ADO to tell us what type of data to use, instead of the above.
  my $fields = undef;
  my @row = $dbh->type_info( $idx_num );
  $fields .= "$idx ";
  shift @row if ($row[0])->{TYPE_NAME} =~ /identity$/;
  my $r = shift @row;
  $fields .= $r->{TYPE_NAME};
  if ($r->{CREATE_PARAMS}) {
    $fields .= '(' . $r->{COLUMN_SIZE} . ')'
    if $r->{CREATE_PARAMS} =~ /LENGTH/i;
      $fields .= '(' . $r->{COLUMN_SIZE} . ', 0)'
    if $r->{CREATE_PARAMS} =~ /PRECISION,SCALE/i;
  }

  # Determine the "long" type here.
  @row = $dbh->type_info( $type_num );
  for my $rt ( @row ) {
    next if $rt->{TYPE_NAME} =~ m/nclob/i;
    next if $rt->{TYPE_NAME} =~ m/raw/i;
    next if ($row[0])->{TYPE_NAME} =~ /identity$/i;
    $fields .= ', ';
    $fields .= "$col_name ";
    $fields .= $rt->{TYPE_NAME};
    if ($rt->{CREATE_PARAMS}) {
      $fields .= '(' . $rt->{COLUMN_SIZE} . ')'
        if $rt->{CREATE_PARAMS} =~ /LENGTH/i;
      $fields .= '(' . $rt->{COLUMN_SIZE} . ', 0)'
        if $rt->{CREATE_PARAMS} =~ /PRECISION,SCALE/i;
    }
    last;
  }

  for my $f ( sort keys %LTestFieldInfo ) {
    $fields .= ', ' unless !$fields;
    $fields .= "$f ";
    print "# -- $fields\n";
    @row = get_long_type_for_column($dbh, $f);
    shift @row if ($row[0])->{TYPE_NAME} =~ /identity$/;

    my $r = shift @row;
    $fields .= $r->{TYPE_NAME};
    if ( $r->{CREATE_PARAMS} ) {
      $fields .= '(' . $r->{COLUMN_SIZE} . ')'
        if $r->{CREATE_PARAMS} =~ /LENGTH/i;
      $fields .= '(' . $r->{COLUMN_SIZE} . ', 0)'
        if $r->{CREATE_PARAMS} =~ /PRECISION,SCALE/i;
    }
    print "# -- $fields\n";
  }
  print "# Using fields: $fields\n";
  return $dbh->do("CREATE TABLE $table_name( $fields )");
}

sub get_long_type_for_column {
  my $dbh = shift;
  my $col = shift;

  my @row;
  for my $type ( @{$LTestFieldInfo{$col}} ) {
    @row = $dbh->type_info( $type );
    # may not correct behavior, but get the first compat type
    #print "# Type $type rows: ", scalar(@row), "\n";
    last if @row;
  }
  die "Unable to find a suitable test type for field $col" unless @row;
  return @row;
}

1;
