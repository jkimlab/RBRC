#!/usr/bin/perl

use strict;
use warnings;
use Sort::Key::Natural 'natsort';

my $outdir = shift;
my %hs_cluster = ();
my %hs_multi_cluster = ();
my $prev_read = "";
my $prev_sf = "";
foreach my $bed_f (@ARGV){
	open(F,$bed_f);
	while(<F>){
		chomp;
		my @arr = split(/\s+/);
		if($arr[3] eq $prev_read){
			if($arr[15] ne $prev_sf){
				delete $hs_cluster{$prev_sf}{$prev_read};
				$hs_multi_cluster{$arr[3]} = "$prev_sf\t$arr[15]";
			}
		} else {
			$hs_cluster{$arr[15]}{$arr[3]} = 0;
		}
		$prev_read = $arr[3];
		$prev_sf = $arr[15];
	}
	close(F);
}

open(W2,">$outdir/multiple_syntenic.reads");
foreach my $read (natsort keys %hs_multi_cluster){
	print W2 "$hs_multi_cluster{$read}\t$read\n";

}
close(W2);

open(W,">$outdir/syntenic.cluster");
foreach my $sf (natsort keys %hs_cluster){
	foreach my $read (natsort keys %{$hs_cluster{$sf}}){
		print W "$sf\t$read\n";
	}
}
close(W);
