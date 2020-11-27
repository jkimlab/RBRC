#!/usr/bin/perl
##########################


##########################
use strict;
use warnings;
use Sort::Key::Natural 'natsort';
use File::Basename;
use Getopt::Long qw(:config no_ignore_case);
use FindBin '$Bin';

my $conserved_segments_F;
my $out_dir = "./";
my $sort;
my $merge;
my $pe;
my $help;
GetOptions (
	"syn|s=s" => \$conserved_segments_F,
	"sort" => \$sort,
	"merge" => \$merge,
	"pe" => \$pe,
	"outdir|o=s" => \$out_dir,
	"help|h" => \$help,
);

if(!$conserved_segments_F || $help){
	print STDERR "
Usage: syn2bed.pl <parameter(optional)> -s [Conserved.Segments file]

[Parameters (optional)]
  --sort  sorting bedfiles
  --merge sorting&merging bedfiles

";
	exit(1);
}
`mkdir -p $out_dir`;
my %hs;
my $syn_num = 0;
my @spc_list = ();
open(F,"$conserved_segments_F");
while(<F>)
{
	chomp;
	if($_ eq ""){next;}
	if($_ =~ /^>(\S+)/){
		$syn_num = $1;
		next;
	}

	my @arr = split(/\s+|\:/);
        my @arr2 = split(/\-/,$arr[1]);
        my @arr3 = split(/\./,$arr[0]);
        my $chr_name = "";
        for(my $i=1;$i<=$#arr3;$i++){
                if($i == 1){
                        $chr_name = $arr3[$i];
                } else {
                        $chr_name .= ".$arr3[$i]";
                }
        }   
	if($syn_num == 1){
		push(@spc_list, $arr3[0]);
	}
	$hs{$arr3[0]}{$syn_num} = "$chr_name\t$arr2[0]\t$arr2[1]\tSF$syn_num\t0\t$arr[2]";
}
close(F);

if($pe){
	if($#spc_list > 1){
		print STDERR "--pe option is only available at pairwise synteny\n";
	}

	my $ref_spc = $spc_list[0];
	my $tar_spc = $spc_list[1];
	open(PE,">$out_dir/synteny.bed");
	foreach my $syn_num (natsort keys %{$hs{$ref_spc}}){
		my @arr_ref = split(/\t/,$hs{$ref_spc}{$syn_num});
		my @arr_tar = split(/\t/,$hs{$tar_spc}{$syn_num});
		print PE "$arr_ref[0]\t$arr_ref[1]\t$arr_ref[2]\t$arr_tar[0]\t$arr_tar[1]\t$arr_tar[2]\t$arr_ref[3]\t0\t$arr_ref[5]\t$arr_tar[5]\n";

	}
	close(PE);
}

foreach my $spc (keys %hs)
{
	open(W,">$out_dir/tmp.$spc.bed");
	foreach my $num (natsort keys %{$hs{$spc}})
	{
		print W "$hs{$spc}{$num}\n";
	}
	close(W);

	if($merge){
		`$Bin/../third_party/bedtools2/bin/bedtools sort -i $out_dir/tmp.$spc.bed > $out_dir/tmp.$spc.sorted.bed`;
		`$Bin/../third_party/bedtools2/bin/bedtools merge -i $out_dir/tmp.$spc.sorted.bed > $out_dir/$spc.bed`;
	} elsif($sort){
		`$Bin/../third_party/bedtools2/bin/bedtools sort -i $out_dir/tmp.$spc.bed > $out_dir/$spc.bed`;
	} else {
		`cp $out_dir/tmp.$spc.bed $out_dir/$spc.bed`;
	}
	`rm -f $out_dir/tmp.*`;
}
