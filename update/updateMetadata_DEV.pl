#!/usr/bin/perl
#------------------------------------------------------------------------------------------
# FileName    : updateMetadata.pl
#
# Description : (re)based on the metadata.txt to update the PEXP table
#				example:
#				select  accession, samples , count(*) from pexp
#				where accession='GSE43205' group by (samples ,accession) having count(*)>1
#
# Author      : czhang
# DateCreated : Sep 10, 2013
# Version     : 1.0
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 VBI
#------------------------------------------------------------------------------------------
$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';
use lib qw(/var/www/modperl);
use gdb::oracle;
use gdb::plot;
use gdb::util;
use DBI;
use POSIX;
use List::Util qw(sum min max);
use Data::Dumper;    # print Dumper( %frmData );

#our $fileLoc = "/var/www/modperl/data";
our $fileLoc = "./";
our ( $dbh, $sth, $sql, $row );
our ( $ousql, $ousth );
my $user          = "genexpdb";
my $passwd        = "vb1g3n3xpdb";
my $host          = "genexpdb-dev.ccrlikknzibd.us-east-1.rds.amazonaws.com";
my $sid           = "GENEXPDB";
my $database_name = "GENEXPDB";
my $port          = "3306";
$dbh = DBI->connect( "dbi:Oracle:host=$host;port=3306;sid=$sid",
					 $user, $passwd, { RaiseError => 1 } )
  or die "$DBI::errstr";

#----------------------------------------------------------------------
# Main
#----------------------------------------------------------------------
my $parm = ( $ARGV[0] ) ? $ARGV[0] : '';
if ( $parm =~ /^metadata.txt/ )
{
	update();
} else
{
	print "\n\tUsage: $0  there is no metadata.txt\n\n";
	exit(-1);
}
print STDERR "update Done.\n";
exit;

sub update
{
	if ( !-e "$fileLoc/metadata.txt" )
	{
		print "\nFile metadata.txt not found!!";
		print "\t\t[run UpdateMetadata.pl needs a metadata.txt]\n\n";
		return;
	}
	open( PEXPPARMS, "$fileLoc/metadata.txt" );
	my @pexpfile = <PEXPPARMS>;
	close(PEXPPARMS);
	$sql =
qq{update pexp set timepoint=?, organism=?, strain=?, mutant=?, condition=?, source=? where accession=? and samples=?};
	$sth = $dbh->prepare($sql);
	my $i = 0;
	for my $line (@pexpfile)
	{
		chomp($line);
		my (
			 $accession, $samples, $timepoint, $organism,
			 $strain,    $mutant,  $condition, $source
		) = split( /\t/, $line );
		$sth->bind_param( 1, $timepoint );
		$sth->bind_param( 2, $organism );
		$sth->bind_param( 3, $strain );
		$sth->bind_param( 4, $mutant );
		$sth->bind_param( 5, $condition );
		$sth->bind_param( 6, $source );
		$sth->bind_param( 7, $accession );
		$sth->bind_param( 8, $samples );
		$sth->execute();
		$i++;
	}
	print "updated $i records.\n";
}
