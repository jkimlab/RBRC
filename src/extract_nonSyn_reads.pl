#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Cwd 'abs_path';

my $cluster1_sort_f = shift;
my $multiple_reads = shift;
my $out_dir = shift;

$out_dir = abs_path($out_dir);

my %syntenic_reads = ();
open(F,$cluster1_sort_f);
while(<F>){
	chomp;
	my @arr = split(/\s+/);
	$syntenic_reads{$arr[1]} = 0;
}
close(F);

open(FM, "$multiple_reads");
while(<FM>){
		my @t = split(/\t/,$_);
		$syntenic_reads{$t[-1]} = 0;
}
close(FM);

#open(W,">$out_dir/nonSyn_reads.fq");
open(W2,">$out_dir/nonSyn_reads.idmap");
my $read_num = 0;
foreach my $read (@ARGV){
	if($read =~ /gz$/){
		open(F,"gunzip -c $read |");
	} else {
		open(F,$read);
	}
	while(my $line1 = <F>){
		my $line2 = <F>;
		my $line3 = <F>;
		my $line4 = <F>;
		chomp($line1);
		chomp($line2);
		chomp($line3);
		chomp($line4);
	
		if($line1 =~ /@(\S+\/\d)/){
			if(exists $syntenic_reads{$1}){
				next;
			}
		}
		$read_num++;
		print W2 "$read_num\t$1\n";
		$line1 =~ s/$1/$read_num/;
#		print W "$line1\n$line2\n$line3\n$line4\n";
	}
	close(F);
}
close(W2);
#close(W);

#`gzip $out_dir/nonSyn_reads.fq`;
