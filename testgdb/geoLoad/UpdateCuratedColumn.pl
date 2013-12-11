#!/usr/bin/perl
#------------------------------------------------------------------------------------------
# FileName    : geoloader.pl
#
# Description : Load Geo Mage-ML xml files into oracle table
# Update columns f Curated table
#
# Author      : czhang
# DateCreated : Nov 2013
# Version     : 1.0
#------------------------------------------------------------------------------------------
# Copyright (c) 2013 VT
#------------------------------------------------------------------------------------------
#
#	try changing encoding from UTF-8 to ISO-8859-1 in family.xml
#
#------------------------------------------------------------------------------------------
package main;
$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';
use XML::Xerces;
use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";
use OracleDb;
use GeoContributor;
use GeoDatabase;
use GeoPlatform;
use GeoSample;
use GeoSeries;


our $fileLoc = "./";
our ( $dbh, $sth, $sql, $row );

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
  
#==============================================================================
## Main
#==============================================================================
my $parm = ( $ARGV[0] ) ? $ARGV[0] : '';
my @gse;
if ( $parm =~ /^updateColumn$/i )
{
	my $gseRef = db::getPendingGSEs();    #get all addPending
	@gse = @$gseRef;
} elsif ( $parm =~ /^GSE[0-9]+$/i )
{
	push @gse, $parm;
} else
{
	print "\n\tUsage: $0 [updateColumn]\n
	\tLoad Geo Accession Mage-ML xml files into oracle table
	\t\tGSE_accession - load this accession
	\t\taddPending - load all addPending from curated table.\n";
	exit(-1);
}
my $dataDir = "../accessions/";

for my $id (@gse)
{
	#change into upper case
	$id = uc($id);
	print "accession= $id";
	updateCurated($id);
}


#
## All done
#
print STDOUT "Done\n";
XML::Xerces::XMLPlatformUtils::Terminate();
exit(0);
#================== end main function ============================


sub updateCurated{
	my $gse   = shift;
	
	#change into upper case
	my $id = uc($gse);
	
	my $dataDir = "../../accessions/";
	
	#check if the directory exists
	if ( !-d $dataDir . $id )
	{
		print STDERR
		  "\tERROR: accession $id has not been downloaded from GEO!\n";
		  return;
	}
	my $xmlFile = $dataDir . $id . "/$id" . "_family.xml";

	#check if the XXXX_family.xml file exists
	if ( !-f $xmlFile )
	{
		print STDERR "\tERROR: accession $id XML not found!\n";
		return ;
		
	}else{
	print STDERR "\t: accession $id XML found!\n";	
	
	XML::Xerces::XMLPlatformUtils::Initialize();
	my $DOM           = XML::Xerces::XercesDOMParser->new();
	my $ERROR_HANDLER = XML::Xerces::PerlErrorHandler->new();
	$DOM->setErrorHandler($ERROR_HANDLER);
	$DOM->setValidationScheme($XML::Xerces::AbstractDOMParser::Val_Auto);

	$DOM->parse($xmlFile);
	print STDOUT "getDocument...";
	my $doc = $DOM->getDocument();
	print STDOUT "getDocumentElement...";
	my $root = $doc->getDocumentElement();
	#get contributor's information
	
	my $hash=getContributors($doc);	
		
	update($id, $hash);
				
	}
	#XML::Xerces::XMLPlatformUtils::Terminate();
	
}



#==============================================================================
## main-subroutines
#==============================================================================


sub getContributors
{
	my $subdoc    = $_[0];
	my %hash      = ( 'FName' => '', 'LName' => '', 'Organization' => '' );
	my $nodelist  = $subdoc->getElementsByTagName("Contributor");
	my $nodecount = $nodelist->getLength();
	print "\nlist count= $nodecount \n";
	my $nodeName;
	my $nodeValue;
	my $node;

	for ( my $i = 0 ; $i < $nodecount ; $i++ )
	{
		$node = $nodelist->item($i);
		print "circle= $i \n";
		if ( $node->getNodeType() == 1 )
		{
			getTextContents( $node, \%hash );
		}
	}
	print "start +++++++++ ";
	print $hash{'LName'};
	print $hash{'FName'};
	print $hash{'Organization'};
	print "End **********";
	return \%hash;
}


sub update
{
	my $gse=$_[0];
	my $hashRef = $_[1];	#get hash reference
		
	my $Organization     = $hashRef->{'Organization'};
	my $first_name     = $hashRef->{'FName'};
	my $last_name     = $hashRef->{'LName'};
	my $author=$first_name ." ". $last_name;
	#my $email     = $hashRef->{"Email"};
	my $email     ="czhang\@vbi.vt.edu";
	print " org= $Organization \tauthor=$author\t$email";
	
	my $sql ="UPDATE CURATED_TEST set Institution=?, AUTHOR=?, EMAIL=? WHERE ACCESSION='".$gse."'";

	$sth = $dbh->prepare($sql);
	$sth->bind_param( 1, $Organization);
	$sth->bind_param( 2, $author);
	$sth->bind_param( 3, $email);			
	$sth->execute();		
	print "end updating $gse";
}



sub getTextContents
{
	my $node     = $_[0];
	my $hash_ref = $_[1];
	my $nodeValue;
	my $nodeName;
	my $length;
	for my $child ( $node->getChildNodes() )
	{
		if ( $child->getNodeType() == 1 )
		{
			getTextContents( $child, $hash_ref );
		} else
		{
			$nodeName = $child->getParentNode()->getNodeName();
			if ( $nodeName eq "Organization" )
			{
				$nodeValue = $child->getNodeValue();
				print $nodeName . "\t" . $nodeValue . "\n";
				$length = length( $hash_ref->{'Organization'} );

				#get first Oragnization
				if ( $length < 2 )
				{
					$hash_ref->{'Organization'} = $nodeValue;
					print $nodeName . "\t" . $nodeValue . "\n";
				} else
				{
					print "else org  " . $nodeName . "\t" . $nodeValue . "\n";
				}
			} elsif ( $nodeName eq "Email" )
			{
				$nodeValue = $child->getNodeValue();
				#print $nodeName . "\t" . $nodeValue . "\n";
			}
			if ( $nodeName eq "Last" )
			{
				$nodeValue = $child->getNodeValue();
				#print $nodeName . "\t" . $nodeValue . "\n";

				#get last person Last Name
				$hash_ref->{'LName'} = $nodeValue;
			} elsif ( $nodeName eq "First" )
			{
				$nodeValue = $child->getNodeValue();
				#print $nodeName . "\t" . $nodeValue . "\n";

				#get last person Fast Name
				$hash_ref->{'FName'} = $nodeValue;
			}
		}
	}
}

#==============================================================================
## end
#==============================================================================
