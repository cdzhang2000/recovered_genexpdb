#!/usr/bin/perl


open(FILE, "pexpInfo.txt");

print "open file to read \n";

my @gse;


while (<FILE>) {
 	chomp;
 	#print "$_\n";
 	push(@gse, $_);
 }
 close (FILE); 
 
 print "array size= ",scalar @gse,"\n";
 
foreach(@gse){
	print "$_\n";		
} 
 
 
 print "end poping array size= ",scalar @gse,"\n";
 

