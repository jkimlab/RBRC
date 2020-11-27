#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;

my $in_cluster_dir = abs_path("$ARGV[0]");
my $out_dir = abs_path("$ARGV[-1]");
`mkdir -p $out_dir`;

open(FCOUT, ">$out_dir/contigs_incluster.fa");
my @dir = <$in_cluster_dir/*.out>;

for(my $i = 0; $i <= $#dir; $i++){
		my $cluster_name = basename($dir[$i],".out");
		print STDERR "$cluster_name\n";
		my $contig_file = "$dir[$i]/assembly.fasta";
		if(!-f $contig_file){ next; }
		my $seq_id = 0;
		open(FC, "$contig_file");
		while(<FC>){
				chomp;
				if($_ =~ /^>/){
						$seq_id++;
						my $cur_id = $cluster_name."_".$seq_id;
						print FCOUT ">$cur_id\n";
				}
				else{ print FCOUT "$_\n"; }
		}
		close(FC);
}
