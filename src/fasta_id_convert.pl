#!/usr/bin/perl

use strict;
use warnings;
use Cwd "abs_path";
use File::Basename;

my $fasta_f = abs_path(shift);
my $out_fa = shift;

my $num = 0;
open(W,">$out_fa");
open(MAP,">$out_fa.idmap");
if($fasta_f =~ /gz$/){
	open(F,"gunzip -c $fasta_f|");
} else {
	open(F,$fasta_f);
}
while(<F>){
	chomp;
	if($_ =~ /^>(\S+)/){
		$num++;
		print W ">seq$num\n";
		print MAP "$1\tseq$num\n";
	} else {
#		my $uc = uc($_);
#		print W "$uc\n";
		print W "$_\n";
	}
}
close(F);
