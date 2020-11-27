#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;

my $out_dir = $ARGV[-1];

my %hs_mapped_read_all_ref = ();

for(my $i = 0; $i < $#ARGV; $i++){
		my $cur_bed = $ARGV[$i];
		open(FBED, "$cur_bed");
		while(<FBED>){
				chomp;
				my @t = split(/\t/,$_);
				if(!exists($hs_mapped_read_all_ref{$t[3]})){
						$hs_mapped_read_all_ref{$t[3]} = 1;
				}
				else{ $hs_mapped_read_all_ref{$t[3]} += 1; }
		}
		close(FBED);
}

for(my $i = 0; $i < $#ARGV; $i++){
		my $cur_bed = $ARGV[$i];
		my $file_name = basename($cur_bed, ".bed");
		open(FBED, "$cur_bed");
		open(FOUT, ">$out_dir/$file_name.filt.bed");
		while(<FBED>){
				chomp;
				my @t = split(/\t/,$_);
				if(!exists($hs_mapped_read_all_ref{$t[3]})){ next; }
				elsif($hs_mapped_read_all_ref{$t[3]} < $#ARGV){ next; }
				print FOUT "$_\n";
		}
		close(FBED);
		close(FOUT);
}
