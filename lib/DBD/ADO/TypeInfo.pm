package DBD::ADO::TypeInfo;

use strict;
use warnings;

use DBI();
use DBD::ADO::Const();

$DBD::ADO::TypeInfo::VERSION = '2.81';

$DBD::ADO::TypeInfo::Fields = {
  TYPE_NAME          =>  0
, DATA_TYPE          =>  1
, COLUMN_SIZE        =>  2
, LITERAL_PREFIX     =>  3
, LITERAL_SUFFIX     =>  4
, CREATE_PARAMS      =>  5
, NULLABLE           =>  6
, CASE_SENSITIVE     =>  7
, SEARCHABLE         =>  8
, UNSIGNED_ATTRIBUTE =>  9
, FIXED_PREC_SCALE   => 10
, AUTO_UNIQUE_VALUE  => 11
, LOCAL_TYPE_NAME    => 12
, MINIMUM_SCALE      => 13
, MAXIMUM_SCALE      => 14
, SQL_DATA_TYPE      => 15
, SQL_DATETIME_SUB   => 16
# NUM_PREC_RADIX     => 17
# INTERVAL_PRECISION => 18
};

my $Enums = DBD::ADO::Const->Enums;
my $Dt = $Enums->{DataTypeEnum};

$DBD::ADO::TypeInfo::dbi2ado = {
  DBI::SQL_GUID()            => $Dt->{adGUID}            # -11
, DBI::SQL_WLONGVARCHAR()    => $Dt->{adLongVarWChar}    # -10
, DBI::SQL_WVARCHAR()        => $Dt->{adVarWChar}        #  -9
, DBI::SQL_WCHAR()           => $Dt->{adWChar}           #  -8
# DBI::SQL_BIT()                                         #  -7
, DBI::SQL_TINYINT()         => $Dt->{adTinyInt}         #  -6
, -5                         => $Dt->{adBigInt}          # SQL_BIGINT
, DBI::SQL_LONGVARBINARY()   => $Dt->{adLongVarBinary}   #  -4
, DBI::SQL_VARBINARY()       => $Dt->{adVarBinary}       #  -3
, DBI::SQL_BINARY()          => $Dt->{adBinary}          #  -2
, DBI::SQL_LONGVARCHAR()     => $Dt->{adLongVarChar}     #  -1
# DBI::SQL_UNKNOWN_TYPE()    =>                          #   0
, DBI::SQL_CHAR()            => $Dt->{adChar}            #   1
, DBI::SQL_NUMERIC()         => $Dt->{adNumeric}         #   2
, DBI::SQL_DECIMAL()         => $Dt->{adDecimal}         #   3
, DBI::SQL_INTEGER()         => $Dt->{adInteger}         #   4
, DBI::SQL_SMALLINT()        => $Dt->{adSmallInt}        #   5
, DBI::SQL_FLOAT()           => $Dt->{adSingle}          #   6
# DBI::SQL_REAL()            =>                          #   7
, DBI::SQL_DOUBLE()          => $Dt->{adDouble}          #   8
, DBI::SQL_DATE()            => $Dt->{adDBDate}          #   9  # deprecated!
# DBI::SQL_INTERVAL()        =>                          #  10
, DBI::SQL_TIMESTAMP()       => $Dt->{adDBTimeStamp}     #  11  # deprecated!
, DBI::SQL_VARCHAR()         => $Dt->{adVarChar}         #  12
, DBI::SQL_BOOLEAN()         => $Dt->{adBoolean}         #  16
, DBI::SQL_UDT()             => $Dt->{adUserDefined}     #  17
# DBI::SQL_UDT_LOCATOR()     =>                          #  18
# DBI::SQL_ROW()             =>                          #  19
# DBI::SQL_REF()             =>                          #  20
, 25                         => $Dt->{adBigInt}          # SQL_BIGINT
, DBI::SQL_BLOB()            => $Dt->{adLongVarBinary}   #  30
# DBI::SQL_BLOB_LOCATOR()    =>                          #  31
, DBI::SQL_CLOB()            => $Dt->{adLongVarChar}     #  40
# DBI::SQL_CLOB_LOCATOR()    =>                          #  41
, DBI::SQL_ARRAY()           => $Dt->{adArray}           #  50
# DBI::SQL_ARRAY_LOCATOR()   =>                          #  51
# DBI::SQL_MULTISET()        =>                          #  55
# DBI::SQL_MULTISET_LOCATOR()=>                          #  56
, DBI::SQL_TYPE_DATE()       => $Dt->{adDBDate}          #  91
, DBI::SQL_TYPE_TIME()       => $Dt->{adDBTime}          #  92
, DBI::SQL_TYPE_TIMESTAMP()  => $Dt->{adDBTimeStamp}     #  93
# DBI::SQL_TYPE_TIME_WITH_TIMEZONE()                     #  94
# DBI::SQL_TYPE_TIMESTAMP_WITH_TIMEZONE()                #  95
# DBI::SQL_INTERVAL_YEAR()                               #  101
# DBI::SQL_INTERVAL_MONTH()                              #  102
# DBI::SQL_INTERVAL_DAY()                                #  103
# DBI::SQL_INTERVAL_HOUR()                               #  104
# DBI::SQL_INTERVAL_MINUTE()                             #  105
# DBI::SQL_INTERVAL_SECOND()                             #  106
# DBI::SQL_INTERVAL_YEAR_TO_MONTH()                      #  107
# DBI::SQL_INTERVAL_DAY_TO_HOUR()                        #  108
# DBI::SQL_INTERVAL_DAY_TO_MINUTE()                      #  109
# DBI::SQL_INTERVAL_DAY_TO_SECOND()                      #  110
# DBI::SQL_INTERVAL_HOUR_TO_MINUTE()                     #  111
# DBI::SQL_INTERVAL_HOUR_TO_SECOND()                     #  112
# DBI::SQL_INTERVAL_MINUTE_TO_SECOND()                   #  113
};

my $ado2dbi = {
  $Dt->{adArray}            => DBI::SQL_ARRAY
, $Dt->{adBigInt}           => 25
, $Dt->{adBinary}           => DBI::SQL_BINARY
, $Dt->{adBoolean}          => DBI::SQL_BOOLEAN
, $Dt->{adBSTR}             => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adChapter}          => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adChar}             => DBI::SQL_CHAR
, $Dt->{adCurrency}         => DBI::SQL_NUMERIC
, $Dt->{adDate}             => DBI::SQL_TYPE_TIMESTAMP # XXX Not really!
, $Dt->{adDBDate}           => DBI::SQL_TYPE_DATE
, $Dt->{adDBTime}           => DBI::SQL_TYPE_TIME
, $Dt->{adDBTimeStamp}      => DBI::SQL_TYPE_TIMESTAMP
, $Dt->{adDecimal}          => DBI::SQL_DECIMAL
, $Dt->{adDouble}           => DBI::SQL_DOUBLE
, $Dt->{adEmpty}            => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adError}            => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adFileTime}         => DBI::SQL_TIMESTAMP
, $Dt->{adGUID}             => DBI::SQL_GUID
, $Dt->{adIDispatch}        => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adInteger}          => DBI::SQL_INTEGER
, $Dt->{adIUnknown}         => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adLongVarBinary}    => DBI::SQL_LONGVARBINARY
, $Dt->{adLongVarChar}      => DBI::SQL_LONGVARCHAR
, $Dt->{adLongVarWChar}     => DBI::SQL_WLONGVARCHAR
, $Dt->{adNumeric}          => DBI::SQL_NUMERIC
, $Dt->{adPropVariant}      => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adSingle}           => DBI::SQL_FLOAT
, $Dt->{adSmallInt}         => DBI::SQL_SMALLINT
, $Dt->{adTinyInt}          => DBI::SQL_TINYINT
, $Dt->{adUnsignedBigInt}   => 25
, $Dt->{adUnsignedInt}      => DBI::SQL_INTEGER
, $Dt->{adUnsignedSmallInt} => DBI::SQL_SMALLINT
, $Dt->{adUnsignedTinyInt}  => DBI::SQL_TINYINT
, $Dt->{adUserDefined}      => DBI::SQL_UDT
, $Dt->{adVarBinary}        => DBI::SQL_VARBINARY
, $Dt->{adVarChar}          => DBI::SQL_VARCHAR
, $Dt->{adVariant}          => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adVarNumeric}       => DBI::SQL_NUMERIC
, $Dt->{adVarWChar}         => DBI::SQL_WVARCHAR
, $Dt->{adWChar}            => DBI::SQL_WCHAR
};

my $ado2dbi3 = {
      # AdoType           IsLong IsFixed => SqlType
  $Dt->{adBinary   } => { 0 => { 0 => DBI::SQL_VARBINARY
                               , 1 => DBI::SQL_BINARY        }
                        , 1 => { 0 => DBI::SQL_LONGVARBINARY
                               , 1 => DBI::SQL_UNKNOWN_TYPE  }}
, $Dt->{adChar     } => { 0 => { 0 => DBI::SQL_VARCHAR
                               , 1 => DBI::SQL_CHAR          }
                        , 1 => { 0 => DBI::SQL_LONGVARCHAR
                               , 1 => DBI::SQL_UNKNOWN_TYPE  }}
, $Dt->{adWChar    } => { 0 => { 0 => DBI::SQL_WVARCHAR
                               , 1 => DBI::SQL_WCHAR         }
                        , 1 => { 0 => DBI::SQL_WLONGVARCHAR
                               , 1 => DBI::SQL_UNKNOWN_TYPE  }}
# $Dt->{adVarBinary} =>
# $Dt->{adVarChar  } =>
# $Dt->{adVarWChar } =>
};

# Attempt to convert an ADO data type into an DBI/ODBC/SQL data type.
sub ado2dbi {
  my ($AdoType, $IsFixed, $IsLong ) = @_;

  # Set default values for IsFixed and IsLong.
  $IsFixed = 0 unless $IsFixed;
  $IsLong  = 0 unless $IsLong ;

#  return $dbh->set_err( $DBD::ADO::err || -1,
#    "convert_ado_to_odbc: call without any attributes.")
#  unless $AdoType;

  my $SqlType = 0;

  if ( $AdoType & $Dt->{adArray} ) {  # XXX: & vs. ==
    $SqlType = 50;  # XXX DBI::SQL_ARRAY();
  }
  elsif ( exists $ado2dbi3->{$AdoType}{$IsLong}{$IsFixed} ) {
    $SqlType = $ado2dbi3->{$AdoType}{$IsLong}{$IsFixed};
    }
  elsif ( exists $ado2dbi->{$AdoType} ) {
    $SqlType = $ado2dbi->{$AdoType};
  }
# print "==> $AdoType, $IsFixed, $IsLong => $SqlType\n";

  if ( wantarray ) {  # DATA_TYPE, SQL_DATA_TYPE, SQL_DATETIME_SUB
    my @a = ( $SqlType );

    if ( 90 < $SqlType && $SqlType < 100 ) {  # SQL_DATETIME
      push @a, 9, $SqlType - 90;
    }
    elsif ( 100 < $SqlType && $SqlType < 120 ) {  # SQL_INTERVAL
      push @a, 10, $SqlType - 100;
    }
    else {
      push @a, $SqlType, undef;
    }
    return @a;
  }
  return $SqlType;
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

DBD::ADO::TypeInfo - ADO TypeInfo

=head1 SYNOPSIS

  use DBD::ADO::TypeInfo();
  ...

=head1 DESCRIPTION

This module helps to handle DBI datatype information.
It provides mappings between DBI (SQL/CLI, ODBC) and ADO datatypes.

=head1 AUTHOR

Steffen Goeldner (sgoeldner@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2002-2004 Steffen Goeldner. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
