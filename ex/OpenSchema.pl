use DBI();

$\ = "\n";
$, = " | ";

  print "\nCalling OpenSchema", @ARGV, "\n";

  my ( $QueryType, @Criteria ) = @ARGV;

  for ( @Criteria ) { undef $_ unless $_ }

  if ( !$QueryType )
  {
    print "Usage: $0 [QueryType] [Criteria]\n";
    print '  QueryTypes:';
    print <DATA>;
    exit;
  }
  my $dbh = DBI->connect or die $DBI::errstr;
     $dbh->{ RaiseError } = 1;
     $dbh->{ PrintError } = 1;

  my $sth = $dbh->func( $QueryType, @Criteria, 'OpenSchema');

  die "statement returned undef" unless $sth;
  
  print @{$sth->{NAME}};
  print map { '-' x length } @{$sth->{NAME}};

  print "\n";
  while ( my $row = $sth->fetch ) { 
  	print @$row
  }

__END__

adSchemaAsserts
adSchemaCatalogs
adSchemaCharacterSets
adSchemaCheckConstraints
adSchemaCollations
adSchemaColumnPrivileges
adSchemaColumns
adSchemaColumnsDomainUsage
adSchemaConstraintColumnUsage
adSchemaConstraintTableUsage
adSchemaCubes
adSchemaDBInfoKeywords
adSchemaDBInfoLiterals
adSchemaDimensions
adSchemaForeignKeys
adSchemaHierarchies
adSchemaIndexes
adSchemaKeyColumnUsage
adSchemaLevels
adSchemaMeasures
adSchemaMembers
adSchemaPrimaryKeys
adSchemaProcedureColumns
adSchemaProcedureParameters
adSchemaProcedures
adSchemaProperties
adSchemaProviderSpecific
adSchemaProviderTypes
adSchemaReferentialConstraints
adSchemaSchemata
adSchemaSQLLanguages
adSchemaStatistics
adSchemaTableConstraints
adSchemaTablePrivileges
adSchemaTables
adSchemaTranslations
adSchemaTrustees
adSchemaUsagePrivileges
adSchemaViewColumnUsage
adSchemaViews
adSchemaViewTableUsage
