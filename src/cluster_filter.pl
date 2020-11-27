#!/usr/bin/perl

use strict;
use warnings;


my $cluster_len_cutoff = shift;
my $cluster_size_cutoff = shift;
my $synteny_bed_f = shift;
my $cluster_f = shift;

my %cluster_len = ();
open(F,$synteny_bed_f);
while(<F>){
	chomp;
	my @arr = split(/\t/);
	my $len = $arr[2] - $arr[1];
	if($len < $cluster_len_cutoff){next;}
	$cluster_len{$arr[3]} = $len;
}
close(F);

my %cluster_size = ();
open(F,$cluster_f);
while(<F>){
	chomp;
	my ($cluster,$m) = split(/\t/);
	if(!exists $cluster_len{$cluster}){next;}
	if(!exists $cluster_size{$cluster}){
		$cluster_size{$cluster} = 1;
	} else {
		$cluster_size{$cluster}++;
	}
}
close(F);

foreach my $cluster (keys %cluster_size){
	if($cluster_size{$cluster} < $cluster_size_cutoff){
		delete $cluster_size{$cluster};
	}
}

open(F,$cluster_f);
while(<F>){
	chomp;
	my ($cluster,$m) = split(/\t/);
	if(!exists $cluster_size{$cluster}){next;}

	print "$_\n";

}
close(F);
