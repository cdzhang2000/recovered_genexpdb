#!/usr/bin/perl
#------------------------------------------------------------------------------------------
# FileName    : getEcoli.pl
#
# Description : find GSEs from OUEcoli.txt that are in pexpParms.txt
#					so we can reload only ecoli experiments
#
#				pexpParms.txt contains all experiments
#				OUEcoli.txt contains all OU ecoli experiments
#
# Author      : jgrissom
# DateCreated : 17 May 2012
# Version     : 1.0
# Modified    :
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 University of Oklahoma
#------------------------------------------------------------------------------------------
$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";
#----------------------------------------------------------------------
# Main
#----------------------------------------------------------------------

my $parm = ( $ARGV[0] ) ? $ARGV[0] : '';

if ( $parm !~ /^parse/ ) {
	print "\n\tUsage: $0  <parse>
	
	find GSEs from OUEcoli.txt that are in pexpParms.txt
	\n\n";
	exit(-1);
}

open( ECOLI, "OUEcoli.txt" );
my @ecolifile = <ECOLI>;
close(ECOLI);

my %ec;
for my $line (@ecolifile) {
	chomp($line);
	$ec{$line}=1;
}



open( PEXPPARMS, "pexpParms.txt" );
my @pexpfile = <PEXPPARMS>;
close(PEXPPARMS);

open( NEWPEXP, ">ecoliExps.txt" );

for my $line (@pexpfile) {
	chomp($line);
	my @data = split("\t", $line);
	
	if ($ec{$data[2]}) {
		print NEWPEXP "$line\n";
	}
}
close(NEWPEXP);


print STDERR "All Done.\n";
exit;

