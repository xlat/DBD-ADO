package DBD::ADO::TypeInfo;

use strict;
use warnings;

use DBI();
use DBD::ADO::Const();

use vars qw($VERSION);

$VERSION = '2.78';

my $Enums = DBD::ADO::Const->Enums;
my $Dt = $Enums->{DataTypeEnum};

my $ado2dbi = {
  $Dt->{adArray}            => DBI::SQL_ARRAY
# $Dt->{adBigInt}           => DBI::SQL_BIGINT
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
, $Dt->{adUnsignedBigInt}   => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adUnsignedInt}      => DBI::SQL_WCHAR
, $Dt->{adUnsignedSmallInt} => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adUnsignedTinyInt}  => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adUserDefined}      => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adVarBinary}        => DBI::SQL_VARBINARY
, $Dt->{adVarChar}          => DBI::SQL_VARCHAR
, $Dt->{adVariant}          => DBI::SQL_UNKNOWN_TYPE
, $Dt->{adVarNumeric}       => DBI::SQL_INTEGER
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

#  unless( $dbh->{ado_types_supported} ) {
#    &_determine_type_support($dbh);
#  }

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
sub Enums
# -----------------------------------------------------------------------------
{
  my $class = shift;

  warn 'DBD::ADO::TypeInfo->Enums is deprecated! Use DBD::ADO::Const->Enums instead';

  return DBD::ADO::Const->Enums;
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

DBD::ADO::TypeInfo - ADO TypeInfo

=head1 SYNOPSIS

  use DBD::ADO::TypeInfo();

=head1 DESCRIPTION

DBD::ADO::TypeInfo->Enums is deprecated!
Use DBD::ADO::Const->Enums instead.

=head1 AUTHOR

Steffen Goeldner (sgoeldner@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2002-2003 Steffen Goeldner. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
