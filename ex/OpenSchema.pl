use DBI();
use DBD::ADO::Const();

$\ = "\n";
$, = " | ";

print "\nCalling OpenSchema", @ARGV, "\n";

my ( $QueryType, @Criteria ) = @ARGV;

for ( @Criteria ) { undef $_ unless $_ }

unless ( $QueryType )
{
  print "Usage: $0 [QueryType] [Criteria]\n";
  print '  QueryTypes:';
  print "    $_" for sort keys %{DBD::ADO::Const->Enums->{SchemaEnum}};
  exit;
}
my $dbh = DBI->connect or die $DBI::errstr;
   $dbh->{RaiseError} = 1;
   $dbh->{PrintError} = 0;

my $sth = $dbh->func( $QueryType, @Criteria, 'OpenSchema')
  or die "Statement returned undef" unless $sth;

print @{$sth->{NAME}};
print map { '-' x length } @{$sth->{NAME}};

while ( my $row = $sth->fetch ) {
  print @$row
}
$dbh->disconnect;
