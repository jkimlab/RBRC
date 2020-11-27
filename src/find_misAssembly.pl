#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

my $coverage_F = shift;
my $chr_F = shift;
my $cutoff = shift;
my $work_dir = shift;

my $library = basename($coverage_F, ".physicalCov.txt");
my %synteny = ();
open(RF, $chr_F);
open(WF,">$work_dir/putMisassemblyRegions_$library.txt");
while(<RF>){
	chomp;
	$synteny{$_} = 1;
}
close RF;

my $prev_chr = "";
my $misAsm = "";
open(RF,$coverage_F);
while(<RF>){
	chomp;
	
	my @cols = split(/\s+/);
	my $chr = $cols[0];
	my $pos_0 = $cols[1]-1;
	my $pos_1 = $cols[1];
	my $cov = $cols[2];

	if(!exists $synteny{$chr}){next;}

	if($prev_chr ne $chr && $misAsm ne ""){
		print WF "$misAsm\n";
		$misAsm = "";
	}

	if($cutoff > $cov){
		my $newPos = "$chr\t$pos_0\t$pos_1";
		if($misAsm eq ""){
			$misAsm = $newPos;
		}else{
			my @arr_pos = split(/\s+/, $misAsm);
			$misAsm = "$arr_pos[0]\t$arr_pos[1]\t$pos_1";
		}
	}else{
		if($misAsm ne ""){
			print WF "$misAsm\n";
			$misAsm = "";
		}
	}
	$prev_chr = $chr;
}
if($misAsm ne ""){
	print WF "$misAsm\n";
}
close RF;
close WF;
