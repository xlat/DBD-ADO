#!/usr/local/bin/perl -sw
#
# $Id: Makefile.PL,v 1.1.1.1 2000/06/01 17:52:31 talowery Exp $
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
#
BEGIN { require 5.004 }	# 5.004 is required for Win32
use Config;
use ExtUtils::MakeMaker 5.16, qw(&WriteMakefile $Verbose);
use File::Basename;
use Getopt::Long;

use DBI 0.93;		# must be installed first
use DBI::DBD;
use strict;

my %opts = 
(
    NAME	=> 'DBD::ADO',
    VERSION_FROM => 'lib/DBD/ADO.pm',
    clean	=> { },
    dist	=> {
	DIST_DEFAULT=> 'clean distcheck ci tardist',
	PREOP    => '$(MAKE) -f Makefile.old distdir',
	COMPRESS => 'gzip -v9', SUFFIX => 'gz'
    },
);
if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{AUTHOR} = 'Tim Bunce and Philip ( http://www.isc.org/dbi-lists.html )';
    $opts{ABSTRACT} = 'ADO driver for the DBI module.';
    $opts{PREREQ_PM} = { DBI => 0 };
    $opts{CAPI} = 'TRUE' if $Config{archname} =~ /-object\b/i;
}

$::opt_g = 0;
$::opt_o = '';
GetOptions(qw(g! o=s)) or die "Invalid arguments";

$opts{OPTIMIZE} = '-g -O0' if $::opt_g;


print "\nConfiguring DBD::ADO ...\n
>>>\tRemember to actually *READ* the README file!
   \tAnd re-read it if you have any problems.\n
";

my $dbi_dir      = dbd_dbi_dir();
my $dbi_arch_dir = dbd_dbi_arch_dir();

WriteMakefile(%opts);

local($^W)=0;
print qq{
The DBD::ADO tests will use these values for the database connection:
    DBI_DSN=$ENV{DBI_DSN}		e.g. dbi:ADO:demo
    DBI_USER=$ENV{DBI_USER}
    DBI_PASS=$ENV{DBI_PASS}
};
print "Warning: not all required environment variables are set.\n"
	unless ($ENV{DBI_DSN} && $ENV{DBI_USER} && $ENV{DBI_PASS});
print "Warning: DBI_DSN ($ENV{DBI_DSN}) doesn't start with 'dbi:ADO:'\n"
	if ($ENV{DBI_DSN} && $ENV{DBI_DSN} !~ m/^dbi:ADO:/);
print "\n";


sub MY::postamble {
    return dbd_postamble(@_);
}

__END__
