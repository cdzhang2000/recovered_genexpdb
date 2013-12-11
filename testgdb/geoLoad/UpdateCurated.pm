#!/usr/bin/perl
#------------------------------------------------------------------------------------------
# FileName    : UpdateCurated.pl
#
# Description : update Curated table basing on the accession list
#					step 1 - will read tab delimited text file having accessions (accessions.txt)
#					step 2 - upcate Curated table
#
# Author      : czhang
# DateCreated : Nov 5, 2103
# Version     : 1.0
#------------------------------------------------------------------------------------------
# Copyright (c) 2010 Virginia Bioinformatics Institute
#------------------------------------------------------------------------------------------

package main;

$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';
use lib qw(/var/www/modperl);
use OracleDb;
use DBI;
use POSIX;
use List::Util qw(sum min max);
use Data::Dumper;    # print Dumper( %frmData );
our $fileLoc = "./";
our ( $dbh, $sth, $sql, $row );
our ( $ousql, $ousth );
my $user   = "genexpdb";
my $passwd = "vb1g3n3xpdb";

#my $host="genexpdb-restore.ccrlikknzibd.us-east-1.rds.amazonaws.com";
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
if ( $parm =~ /^update/ )
{
	updateCurated();
} else
{
	print "\n\tUsage: $0  <update| filename> \n\n";
	exit(-1);
}
print STDERR "All Done.\n";
exit;

sub updateCurated
{
	if ( !-e "$fileLoc/accessions.txt" )
	{
		print "\nFile accessions.txt not found!!";
		return;
	}
	open( ACCESSIONS, "$fileLoc/accessions.txt" );
		
	my @gselist;
	my $line;
	my $status=0;
	
	my @addedGSE=0;
	
	while( $line = <ACCESSIONS> )
	{
		
		my ( $gse, $title, $organism, $pubid, $submitdate ) =
		  split( /\t/, $line );
		  
		$status = db::checkAccesion($gse);
				
		if ( $status == 0 )
		{
			loadGSEs( $gse, $title, $organism, $pubid, $submitdate );
			push( @addedGSE, $gse );
			
		} else
		{
			push( @gselist, $gse );
		}
	}
	
	close(ACCESSIONS);
	print "Inserted GSEs \n";
	print join(", ", @addedGSE);
	
	print "\n\nNeglected  GSEs \n";
	print join(", ", @gselist);
	print "\n";
	
}

sub loadGSEs
{
	my $gse        = $_[0];
	my $title      = $_[1];
	my $organism   = $_[2];
	my $strain     = $_[2];	
	my $pmid       = $_[3];
	my $submitdate = $_[4];
	my $substrain  = '';
	
	my $sql ="INSERT INTO CURATED_TEST(ACCESSION, TITLE, STRAIN, SUBSTRAIN, GEOMATCH, PMID, SUBMIT_DATE, status, Institution ) VALUES(?, ?, ?, ?, ?, ?, TO_DATE(?, 'MM/DD/YYYY'), ?, ?)";

	my $char = ';';
  	my $result = index($strain, $char);
	
	if($result>0){
		$strain= substr($organism, 0, $result-1);
		$substrain=substr($organism, $result+1);
	}
	$sth = $dbh->prepare($sql);
	
	$sth->bind_param( 1, $gse );
	$sth->bind_param( 2, $title );
	$sth->bind_param( 3, $strain );
	$sth->bind_param( 4, $substrain );
	$sth->bind_param( 5, $strain);
	$sth->bind_param( 6, $pmid);
	$sth->bind_param( 7, $submitdate);
	$sth->bind_param( 8, 2);
	$sth->bind_param( 9, ' ');
			
	$sth->execute();
		
}
