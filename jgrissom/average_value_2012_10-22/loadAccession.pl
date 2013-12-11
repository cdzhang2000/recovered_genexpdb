#!/usr/bin/perl
#
# Program Name: loadAccession.pl
#                Using BioPerl
#                 load Accession.gbk into genome table
#  20 Aug 2004...jeg
#
#  26 Jun 2008 modified to load accessions into jacob-mage
#  11 Jul 2008 modified to load accessions into bioDB01-oudb
#  11 Nov 2008 modified to load accessions into table genome
#  13 Dec 2010 loaded into GBD
#
#==============================================================================

$| = 1;    # dump buffer immediately
use strict;
use warnings FATAL => 'all';

use Bio::SeqIO;

use DBI;
use DBD::Oracle qw(:ora_types);

our ( $dbh, $sth, $sql, $row );
$dbh = DBI->connect( 'dbi:Oracle:oubcf', 'gdb', 'gdb_bioweb', { PrintError => 1, RaiseError => 1, AutoCommit => 1 } );

use Data::Dumper;    # print "<pre>" . Dumper( %frmData ) . "</pre>";

#==============================================================================
## Main
#==============================================================================

if ( $#ARGV < 0 ) {
	print "\n  Usage: loadAccession refseq(NC_000913.gbk)\n\n";
	exit(-1);
}

my %accCategory = (
	"NC_000913", "Laboratory", "AC_000091", "Laboratory",            "NC_010473", "Laboratory", "NC_010468", "Commensal",  "NC_009800", "Commensal",
	"NC_011415", "Commensal",  "NC_010498", "Environmental isolate", "FN554766",  "EAEC",       "NC_002655", "EHEC",       "NC_002695", "EHEC",
	"NC_011353", "EHEC",       "NC_009801", "ETEC",                  "NC_011601", "EPEC",       "NC_004431", "UPEC",       "NC_007946", "UPEC",
	"NC_008253", "UPEC",       "NC_008563", "Avian pathogen",        "NC_012947", "Laboratory", "NC_012967", "Laboratory", "NC_003197", "Pathogen",
	"NC_003277", "Pathogen",   "CP001363",  "Pathogen",              "NC_004337", "Pathogen",   "NC_004741", "Pathogen",   "NC_007606", "Pathogen",
	"NC_007613", "Pathogen",   "NC_007384", "Pathogen",              "NC_004668", "Pathogen",   "NC_000964", "Laboratory", "NC_007795", "Pathogen",
	"NC_002505", "Pathogen",   "NC_002506", "Pathogen",              "NC_004631", "Pathogen",   "NC_011147", "Pathogen",   "NC_006511", "Pathogen",
	"NC_004088", "Pathogen",   "NC_003143", "Pathogen",              "NC_010554", "Pathogen",   "NC_013716", "Pathogen"
);
my %validTags = (
	"ec_number", "", "function", "", "gene", "", "locus_tag", "", "note", "", "old_locus_tag", "", "organism", "", "product", "", "protein_id", "", "strain", "", "sub_strain", "", "translation", "",
	"gene_synonym", "", "go_component", "", "go_function", "", "go_process", "", "plasmid","", "db_xref",""
);

foreach $_ (@ARGV) {

	#cycle thru each file

	my $seqio_object = Bio::SeqIO->new( -file => $_ );
	my $seq_object = $seqio_object->next_seq;

	my $accession = '';
	my $adate     = '';
	$accession = $seq_object->display_id();

	my $category = ( $accCategory{$accession} ) ? $accCategory{$accession} : '';

	print "\n$accession - $category\n";

	my $annot_coll = $seq_object->annotation;
	for my $annot ( $annot_coll->get_Annotations ) {
		$adate = $annot->value if ( $annot->tagname eq "date_changed" );
	}

	my $cnt = 1;
	for my $feat_object ( $seq_object->get_SeqFeatures ) {

		my %record = ();

		$record{accession} = $accession;
		$record{category}  = $category;
		$record{adate}     = $adate if ( $feat_object->primary_tag =~ /^source/ );

		#cycle thru features
		$record{feature}     = $feat_object->primary_tag;
		$record{sstart}      = $feat_object->location->start;
		$record{sstop}       = $feat_object->location->end;
		$record{orientation} = ( $feat_object->location->strand == 1 ) ? 'cw' : 'ccw';

		my $splittype = '';
		if ( $feat_object->location->isa('Bio::Location::SplitLocationI') ) {
			for my $location ( $feat_object->location->sub_Location ) {
				$splittype .= $location->start . ".." . $location->end . ",";
			}
			$splittype =~ s/\,$//;    # delete trailing comma
			$record{ $feat_object->location->splittype } = $splittype;
		}

		my ( $xtag, $xvalue );

		#cycle thru qualifiers under feature
		for my $tag ( $feat_object->get_all_tags ) {

			next if !exists $validTags{ lc($tag) };
			
			for my $value ( $feat_object->get_tag_values($tag) ) {
				if ( $tag =~ /^gene_synonym/ ) {
					$record{'synonyms'} = (exists $record{'synonyms'}) ? "$record{'synonyms'}, $value" : $value;
				}elsif ( $tag =~ /^db_xref/ ) {
					( $xtag, $xvalue ) = split( /\:/, $value );
					$xtag =~ s/^\s+//;
					$xtag =~ s/\s+$//;
					$xvalue =~ s/^\s+//;
					$xvalue =~ s/\s+$//;
					$xtag = "swissprot" if ( lc($xtag) =~ /^uniprotkb\/swiss/ );
					if (lc($xtag) =~ /^swissprot|^gi|^ecogene|^ecocyc|^geneid|^asap/) {
						$record{$xtag} = (exists $record{$xtag}) ? "$record{$xtag}, $xvalue" : $xvalue;
					}
				}elsif ( ( $tag =~ /^note/ ) and ( $value =~ /^synonym/ ) ) {
					( $xtag, $xvalue ) = split( /\:/, $value );
					$xvalue =~ s/^\s+//;
					$xvalue =~ s/\s+$//;
					$record{'synonyms'} = (exists $record{'synonyms'}) ? "$record{'synonyms'}, $xvalue" : $xvalue;
				}elsif ( $tag =~ /^old_locus_tag/ ) {
					$record{'old_locus_tag'} = (exists $record{'old_locus_tag'}) ? "$record{'old_locus_tag'}, $value" : $value;
				}else{
					$record{$tag} = (exists $record{$tag}) ? "$record{$tag}, $value" : $value;
				}
			}
		}	
		dbWrtRec( \%record );
	}
}

print "\nDone\n";
exit(0);

sub dbWrtRec {
	my ($recRef) = @_;
	my %record = %$recRef;

	my $i      = 1;
	my $field  = 'id';                       # start fields with sequence ID
	my $values = 'genome_id_seq.nextval';    # values placeholders, id sequence first

	while ( my ( $key, $value ) = each(%record) ) {

		# loop thru the hash to build the db fields and value placeholders
		$field  .= ',' . $key;
		$values .= ',?';
	}

	$sql = "INSERT into genome ($field) values ($values)";
	$sth = $dbh->prepare($sql);

	# bind all the data to the placeholders
	my $rc;
	while ( my ( $key, $value ) = each(%record) ) {
		if ( $key =~ /^translation/ ) {
			$rc = $sth->bind_param( $i, $value, { ora_type => ORA_CLOB } ) or die $sth->errstr;
		} else {
			$rc = $sth->bind_param( $i, $value ) or die $sth->errstr;
		}
		$i++;
	}

	# insert the row
	$sth->execute or die "Can't execute statement: $DBI::errstr";
	$sth->finish;
}

