package DBD::ADO::Const;

use strict;
use warnings;

use Win32::OLE();
use Win32::OLE::TypeInfo();

$DBD::ADO::Const::VERSION = '0.06';

my $ProgId  = 'ADODB.Connection';
my $VarSkip = Win32::OLE::TypeInfo::VARFLAG_FHIDDEN()
            | Win32::OLE::TypeInfo::VARFLAG_FRESTRICTED()
            | Win32::OLE::TypeInfo::VARFLAG_FNONBROWSABLE()
            ;
my $Enums;

# -----------------------------------------------------------------------------
sub Enums
# -----------------------------------------------------------------------------
{
  my $class = shift;

  return $Enums if $Enums;

  my $TypeLib = Win32::OLE->new( $ProgId )->GetTypeInfo->GetContainingTypeLib;

  for my $i ( 0 .. $TypeLib->_GetTypeInfoCount - 1 )
  {
    my $TypeInfo = $TypeLib->_GetTypeInfo( $i );
    my $TypeAttr = $TypeInfo->_GetTypeAttr;
    next unless $TypeAttr->{typekind} == Win32::OLE::TypeInfo::TKIND_ENUM();
    my $Enum = $Enums->{$TypeInfo->_GetDocumentation->{Name}} = {};
    for my $i ( 0 .. $TypeAttr->{cVars} - 1 )
    {
      my $VarDesc = $TypeInfo->_GetVarDesc( $i );
      next if $VarDesc->{wVarFlags} & $VarSkip;
      my $Documentation = $TypeInfo->_GetDocumentation( $VarDesc->{memid} );
      $Enum->{$Documentation->{Name}} = $VarDesc->{varValue};
    }
  }
  return $Enums;
}
# -----------------------------------------------------------------------------
1;

=head1 NAME

DBD::ADO::Const - ADO Constants

=head1 SYNOPSIS

  use DBD::ADO::Const();

  $\ = "\n";

  my $Enums = DBD::ADO::Const->Enums;

  for my $Enum ( sort keys %$Enums )
  {
    print $Enum;
    for my $Const ( sort keys %{$Enums->{$Enum}} )
    {
      printf "  %-35s 0x%X\n", $Const, $Enums->{$Enum}{$Const};
    }
  }

=head1 DESCRIPTION

In the OLE type library, many constants are defined as members of enums.
It's easy to lookup DBD::ADO constants by name, e.g.:

  $ado_consts->{adChar} == 129

Unfortunately, Win32::OLE::Const does not preserve the namespace of the enums.
It's a matter of taste, but I think

  $ado_consts->{DataTypeEnum}{adChar} == 129

makes the code more self-documenting.

Furthermore, many DBD::ADO methods return numeric codes. Transforming these
codes into human readable strings requires an inverse lookup by value.
Building the reverse hash for e.g. all datatypes requires that datatype
constants can be distinguished from other constants, i.e. we need the
namespace preserved.

The Enums() method of this package return a hash of hashes for exactly this
purpose.

=head1 TODO

Try a XS implementation and benchmark speed-up.

Suggest a more general version (parameterized by $ProgId) for inclusion
into Win32::OLE.

=head1 AUTHOR

Steffen Goeldner (sgoeldner@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2002-2003 Steffen Goeldner. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
