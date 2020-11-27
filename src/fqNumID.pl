#!/usr/bin/perl

use strict;
use warnings;

my $lib_num = shift;
my $lib_FR = shift;
my $lib_path = shift;
my $out_dir = shift;

my $read_num = 0;
open(MAP,">$out_dir/$lib_num.$lib_FR.map");
open(W,">$out_dir/$lib_num.$lib_FR.fq");
if($lib_path =~ /gz$/){
	open(F,"gunzip -c $lib_path|");
} else {
	open(F,$lib_path);
}
while(my $line1 = <F>){
	chomp($line1);
	$read_num++;
	print MAP "$line1\t";
#	my @t = split(/\s+/,$line1);
#	print MAP "$t[0]\t";
	if($lib_FR eq "F"){
		print W "\@$lib_num-$read_num/1\n";
		print MAP "\@$lib_num-$read_num/1\n";
	} else {
		print W "\@$lib_num-$read_num/2\n";
		print MAP "\@$lib_num-$read_num/2\n";
	}
	my $line2 = <F>;
	my $line3 = <F>;
	my $line4 = <F>;
	print W "$line2$line3$line4";
}
close(F);
close(W);
close(MAP);
