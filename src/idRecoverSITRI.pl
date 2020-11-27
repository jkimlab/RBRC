#!/usr/bin/perl

use strict;
use warnings;

my $idmap_f = shift;
my $sitri_cluster_f = shift;

my %idmap = ();
open(F,$idmap_f);
while(<F>){
	chomp;
	my @arr = split(/\s+/);
	$idmap{$arr[0]} = $arr[1];
}
close(F);


open(F,$sitri_cluster_f);
while(<F>){
	chomp;
	my @arr = split(/\s+/);
	print "$arr[0]\t$idmap{$arr[1]}\n";
}
close(F);
