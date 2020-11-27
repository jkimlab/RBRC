#!/usr/bin/perl

use strict;
use warnings;

my $final_cluster = shift;
my @idmaps = @ARGV;

my %idmap = ();

foreach my $idmap_f (@idmaps){
	open(F,$idmap_f);
	while(<F>){
		chomp;
		my ($ori,$post) = split(/\t/);
		$ori =~ s/\@//; $post =~ s/\@//;
		$idmap{$post} = $ori;
	}
	close(F);
}

open(F,$final_cluster);
while(<F>){
	chomp;
	my @arr = split(/\s+/);
	print "$arr[0]\t$idmap{$arr[1]}\n";
}
close(F);
