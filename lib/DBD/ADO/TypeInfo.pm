package DBD::ADO::TypeInfo;

use strict;
use warnings;

use DBD::ADO::Const();

use vars qw($VERSION);

$VERSION = '2.77';

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
