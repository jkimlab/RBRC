#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use FindBin '$Bin';

my $in_readlist = $ARGV[0];
my $in_bam = $ARGV[1];
my $out_dir = $ARGV[-1];
`mkdir -p $out_dir`;
my $b_name = basename($in_bam,".bam");

my %hs_list = ();
my %hs_dup = ();
open(FRL, "$in_readlist");
while(<FRL>){
		chomp;
		my ($new_id, $old_id) = split(/\t/,$_);
		my ($oid, $ost) = split(/\//,$old_id);
		$hs_list{$oid}{$ost} = $new_id;
}
close(FRL);
open(FOSAM, ">$out_dir/$b_name.sam");
open(FBAM, "$Bin/../third_party/samtools-1.9/samtools view -h -F 0xF00 $in_bam|");
while(<FBAM>){
		chomp;
		if($_ =~ /^@/){ print FOSAM "$_\n"; next; }
		my @t = split(/\t/,$_);
		if($t[1] & 0x40){
				if(exists($hs_list{$t[0]}{1})){
#						print FOSAM "$hs_list{$t[0]}{1}";
						print FOSAM "$t[0]";
						for(my $n = 1; $n <= $#t; $n++){
								print FOSAM "\t$t[$n]";
						}
						print FOSAM "\n";
				}
		}
		elsif($t[1] & 0x80){
				if(exists($hs_list{$t[0]}{2})){
#						print FOSAM "$hs_list{$t[0]}{2}";
						print FOSAM "$t[0]";
						for(my $n = 1; $n <= $#t; $n++){
								print FOSAM "\t$t[$n]";
						}
						print FOSAM "\n";
				}
		}
}
close(FBAM);
close(FOSAM);
`$Bin/../third_party/samtools-1.9/samtools view -b $out_dir/$b_name.sam -o $out_dir/$b_name.bam`;
`$Bin/../third_party/bedtools2/bin/bedtools bamtobed -i $out_dir/$b_name.bam > $out_dir/$b_name.bed`;
`$Bin/../third_party/bedtools2/bin/bedtools sort -i $out_dir/$b_name.bed > $out_dir/sort.$b_name.bed`;
open(FBED, "$out_dir/sort.$b_name.bed");
open(FOBED, ">$out_dir/sort.NewID.$b_name.bed");
while(<FBED>){
		chomp;
		my @t = split(/\t/,$_);
		my ($oid, $ost) = split(/\//,$t[3]);
		$t[3] = $hs_list{$oid}{$ost};
		if(!exists($hs_dup{$t[3]})){ $hs_dup{$t[3]} = 1; }
		else{ print "ERR: $t[3]\n"; }
		print FOBED "$t[0]";
		for(my $i = 1; $i <= $#t; $i++){
				print FOBED "\t$t[$i]";
		}
		print FOBED "\n";
}
close(FBED);
close(FOBED);
