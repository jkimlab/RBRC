#!/usr/bin/perl
use strict;
use warnings;

my $work_dir = $ARGV[-1];
my %hs_pair = ();
for(my $i = 0; $i < $#ARGV; $i++){
		my $cur_matrix = $ARGV[$i];
		open(FM, "$cur_matrix");
		while(<FM>){
				chomp;
				my ($f, $s, $d) = split(/\t/,$_);
				my @bs = sort {$a<=>$b} ($f, $s);
				if(exists($hs_pair{$bs[0]}{$bs[1]})){
						$hs_pair{$bs[0]}{$bs[1]} += 1;
				}
				else{ $hs_pair{$bs[0]}{$bs[1]} = 1; }
#				if(exists($hs_pair{$f}{$s})){
#						$hs_pair{$f}{$s} += 1;
#				}
#				elsif(exists($hs_pair{$s}{$f})){
#						$hs_pair{$s}{$f} += 1;
#				}
#				else{ $hs_pair{$f}{$s} = 1; }
		}
		close(FM);
}
my %hs_filtering_output = ();
open(FSM, "$work_dir/DBC.matrix");
while(<FSM>){
		chomp;
		if($_ =~ /^#/){ next; }
		my ($f, $s, $d) = split(/\t/,$_);
		my @bs = sort {$a<=>$b} ($f, $s);
		if(exists($hs_pair{$bs[0]}{$bs[1]}) && $hs_pair{$bs[0]}{$bs[1]} == $#ARGV){
				if(exists($hs_filtering_output{$bs[0]}{$bs[1]})){
						$hs_filtering_output{$bs[0]}{$bs[1]} += $d
				}
				else{ $hs_filtering_output{$bs[0]}{$bs[1]} = $d; }
		}
#		if(exists($hs_pair{$f}{$s}) && $hs_pair{$f}{$s} == $#ARGV){
#				$hs_filtering_output{$f}{$d}{$s} = $d;
#		}
#		elsif(exists($hs_pair{$s}{$f}) && $hs_pair{$s}{$f} == $#ARGV){
#				$hs_filtering_output{$f}{$d}{$s} = $d;
#		}
}
close(FSM);
open(FOUT, ">$work_dir/filt.DBC.matrix");
foreach my $k1 (sort {$a<=>$b} (keys(%hs_filtering_output))){
		foreach my $k2 (sort {$a<=>$b} (keys(%{$hs_filtering_output{$k1}}))){
				print FOUT "$k1\t$k2\t$hs_filtering_output{$k1}{$k2}\n";
		}
}
close(FOUT);
