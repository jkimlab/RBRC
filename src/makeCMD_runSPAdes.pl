#!/usr/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
use Parallel::ForkManager;
use FindBin '$Bin';

my $in_read1 = abs_path("$ARGV[0]");
my $in_read2 = abs_path("$ARGV[1]");
my $in_cluster = $ARGV[2];
my $in_cpu = $ARGV[3];
my $in_assembler_path = "$Bin/../third_party/SPAdes-3.15.4-Linux/bin/spades.py";
my $out_dir = abs_path("$ARGV[-1]");

`mkdir -p $out_dir/logs`;

print STDERR "Storing clustered reads\n";
my %hs_clustered_read = ();
open(FCL, "$in_cluster");
while(<FCL>){
		chomp;
		my ($cluster, $readid) = split(/\t/,$_);
		$hs_clustered_read{$readid} = $cluster;
}
close(FCL);


print STDERR "Assembly with only clustered read files\n";
my @cmds = ();
my $cmd = "";
push(@cmds, $cmd);
print STDERR "Storing read sequences\n";
print STDERR " Read 1\t$in_read1\n";
my %hs_read_seq1 = ();
my $seq_id = "";
open(FREAD1OUT, ">$out_dir/read1.fq");
open(FNC1, ">$out_dir/non_clustered_read1.fq");
if($in_read1 =~ /.gz$/){ open(FR, "gunzip -c $in_read1 |"); }
else{ open(FR, "$in_read1"); }
while(<FR>){
		chomp;
		if($_ =~ /^\@.+\/1$/ || $_ =~ /^\@\wRR/){
				my $line1 = $_;
				$seq_id = substr($_,1);
				my $line2 = <FR>;
				my $line3 = <FR>;
				my $line4 = <FR>;
				if(exists($hs_clustered_read{$seq_id})){
						$hs_read_seq1{$seq_id} = "$line1\n$line2$line3$line4";
						print FREAD1OUT "$line1\n$line2$line3$line4";
				}
				else{
						print FNC1 "$line1\n$line2$line3$line4";
				}
		}
}
close(FR);
close(FREAD1OUT);
close(FNC1);
print STDERR " Read 2\t$in_read2\n";
my %hs_read_seq2 = ();
open(FREAD2OUT, ">$out_dir/read2.fq");
open(FNC2, ">$out_dir/non_clustered_read2.fq");
if($in_read2 =~ /.gz$/){ open(FR, "gunzip -c $in_read2 |"); }
else{ open(FR, "$in_read2"); }
while(<FR>){
		chomp;
		if($_ =~ /^\@.+\/2$/ || $_ =~ /^\@\wRR/){
				my $line1 = $_;
				$seq_id = substr($_,1);
				my $line2 = <FR>;
				my $line3 = <FR>;
				my $line4 = <FR>;
				if(exists($hs_clustered_read{$seq_id})){
						$hs_read_seq2{$seq_id} = "$line1\n$line2$line3$line4";
						print FREAD2OUT "$line1\n$line2$line3$line4";
				}
				else{
						print FNC2 "$line1\n$line2$line3$line4";
				}
		}
}
close(FR);
close(FREAD2OUT);
close(FNC2);
print STDERR "Assembly for every cluster\n";
my %hs_cluster = ();
my $pre_cluster = "";
`mkdir -p $out_dir/cluster.out`;
open(FC, "$in_cluster");
while(<FC>){
		chomp;
		my ($cluster, $read) = split(/\t/,$_);
		if($pre_cluster ne $cluster){
				print STDERR "-> $cluster\n";
				if($pre_cluster eq ""){
				}
				else{
						close(FRO);
						$cmd = "$in_assembler_path -1 $out_dir/cluster.out/$pre_cluster.1.fq -2 $out_dir/cluster.out/$pre_cluster.2.fq --careful -t $in_cpu -o $out_dir/cluster.out/$pre_cluster.out > $out_dir/logs/log.$pre_cluster.txt 2>&1";
						print "$cmd\n";
						push(@cmds,$cmd);
				}
				open(FRO1, ">$out_dir/cluster.out/$cluster.1.fq");
				open(FRO2, ">$out_dir/cluster.out/$cluster.2.fq");
				if(exists($hs_read_seq1{$read})){
						print FRO1 "$hs_read_seq1{$read}";
				}
				if(exists($hs_read_seq2{$read})){
						print FRO2 "$hs_read_seq2{$read}";
				}
				$pre_cluster = $cluster;
		}
		else{
				if(exists($hs_read_seq1{$read})){
						print FRO1 "$hs_read_seq1{$read}";
				}
				if(exists($hs_read_seq2{$read})){
						print FRO2 "$hs_read_seq2{$read}";
				}
		}
}
close(FC);
close(FRO);
$cmd = "$in_assembler_path -1 $out_dir/cluster.out/$pre_cluster.1.fq -2 $out_dir/cluster.out/$pre_cluster.2.fq --careful -t $in_cpu -o $out_dir/cluster.out/$pre_cluster.out 2> $out_dir/logs/log.$pre_cluster.txt";
print "$cmd\n";
print "$Bin/merging_SPAdes_incluster.pl $out_dir/cluster.out $out_dir\n";;
$cmd = "$in_assembler_path -1 $in_read1 -2 $in_read2 --nanopore $out_dir/contigs_incluster.fa --careful -t $in_cpu -o $out_dir/Final_assembly 2> $out_dir/logs/log.Final_assembly.txt";
print "$cmd\n";
print STDERR "Finished.\n";
