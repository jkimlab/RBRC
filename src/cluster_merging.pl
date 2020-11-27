#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

my $out_dir = $ARGV[0];
my $read_cutoff = $ARGV[1];
my $multi_reads_f = $ARGV[2];

my $total_reads = 0;
my %multi_reads = ();

open LOG,">$out_dir/merged.cluster.log";
open M,"$multi_reads_f";
print LOG "#Infile (contain reads span two cluster): $multi_reads_f\n";
while(<M>){
	chomp;
	my @t = split(/\s+/);
	$multi_reads{$t[0]}{$t[1]} .= "$t[2],";
	$total_reads++;
}
close M;

my %syn = ();

for(my $i = 3; $i <= $#ARGV; $i++){
	my $flag = 0;
	my $bname = basename($ARGV[$i],".cluster");
	print LOG "#Infile (contain reads in each cluster): $ARGV[$i]\n";
	open F,"$ARGV[$i]";
	while(<F>){
		chomp;
		my @t = split(/[\s|\/]/);
		$syn{$t[1]}{$t[2]} = $t[0];
		$total_reads++;
	}
	close F;
}

my %link = ();
my %link_cnt = ();
my %nolink = ();
my %nolink_cnt = ();
my %clusters = ();

foreach my $r1(sort keys %syn){
	my $n1 = $syn{$r1}{1};
	my $n2 = $syn{$r1}{2};
	if(exists $syn{$r1}{1} && exists $syn{$r1}{2}){
		if($syn{$r1}{1} eq $syn{$r1}{2}){ # both reads within same synteny
			$nolink{$n1} .= "$r1/1,$r1/2,";
			$nolink_cnt{$n1}+=2;
		}else{
			$link{$n1}{$n2} .= "$r1/1,$r1/2,";
			$link_cnt{$n1}{$n2}++;
		}
	}elsif(!exists $syn{$r1}{1} && exists $syn{$r1}{2}){ # single pair
		$nolink{$n2} .= "$r1/2,";
		$nolink_cnt{$n2}++;
	}elsif(exists $syn{$r1}{1} && !exists $syn{$r1}{2}){ # single pair
		$nolink{$n1} .= "$r1/1,";
		$nolink_cnt{$n1}++;
	}
}

my %clu = ();
my $cluster_num = 0;

print LOG "\n#Total number of input reads: $total_reads\n";
print LOG "#Read cutoff criteria for merging clusters\n";

print LOG "\n#Cluster linkage Information \n";
print LOG "#IF a number of reads between clusters were greater than $read_cutoff, the clusters will be merged\n";
print LOG "##Type:BETWEEN(LINK), BETWEEN(NOLINK), WITHIN\n";
print LOG "###BETWEEN(LINK): cluster-cluster:number of linking reads\n";
print LOG "###BETWEEN(NOLINK): cluster-cluster:number of linking reads\n";
print LOG "###WITHIN: cluster:number of reads\n";

foreach my $k1(sort keys %link_cnt){
	foreach my $k2(sort keys %{$link_cnt{$k1}}){
		my $sum_link = 0;
		if(exists $link_cnt{$k2}{$k1}){
			$sum_link = $link_cnt{$k1}{$k2} + $link_cnt{$k2}{$k1};
		}else{
			$sum_link = $link_cnt{$k1}{$k2};
		}
		if($sum_link >= $read_cutoff){
			if($link_cnt{$k2}{$k1}){
				print LOG "BETWEEN(LINK)\t$k1-$k2:$link_cnt{$k1}{$k2}\t$k2-$k1:$link_cnt{$k2}{$k1}\n";
			}else{
				print LOG "BETWEEN(LINK)\t$k1-$k2:$link_cnt{$k1}{$k2}\n";
			}
			if(exists $clu{$k1}){
				$clu{$k2} = $clu{$k1};
			}elsif(exists $clu{$k2}){
				$clu{$k1} = $clu{$k2};
			}else{
				$cluster_num++;
				$clu{$k1} = $cluster_num;
				$clu{$k2} = $cluster_num;
			}
		}else{
			print LOG "BETWEEN(NOLINK)\t$k1-$k2:$link_cnt{$k1}{$k2}\n";
			my @reads = split(/,/,$link{$k1}{$k2});
			for(my $i = 0; $i < $#reads; $i+=2){
#				print OUT "$k1\t$reads[$i]\n";
#				print OUT "$k2\t$reads[$i+1]\n";
				$nolink{$k1} .= "$reads[$i],";
				$nolink{$k2} .= "$reads[$i+1],";
			}
		}
		if(exists $nolink_cnt{$k1}){
			print LOG "WITHIN\t$k1:$nolink_cnt{$k1}\n";
		}else{
			print LOG "WITHIN\t$k1:0\n";
		}
		if(exists $nolink_cnt{$k2}){
			print LOG "WITHIN\t$k2:$nolink_cnt{$k2}\n";
		}else{
			print LOG "WITHIN\t$k2:0\n";
		}
	}
}
my $cluster = 1;

my %clu2 = ();
foreach my $sf(sort {$a cmp $b} keys %clu){
	$clu2{$clu{$sf}} .= "$sf:";
}

print LOG "\n#CLUSTER Information\n";
open(OUT,">$out_dir/merged.cluster");
foreach my $c(sort {$a<=>$b} keys %clu2){
	my @sfs = split(/:/,$clu2{$c});
	my $num_sfs = scalar @sfs;
	print LOG ">CLUSTER$cluster(contain $num_sfs clusters): @sfs\n";
	for(my $i = 0; $i <= $#sfs; $i++){
		for(my $j = 0; $j <= $#sfs; $j++){
			if($i != $j){	
				my $sum_link = 0;
				print LOG "";
				if(exists $link_cnt{$sfs[$i]}{$sfs[$j]} && exists $link_cnt{$sfs[$j]}{$sfs[$i]}){
#					print LOG "CHECK1\t$sfs[$i]-$sfs[$j]:$link_cnt{$sfs[$i]}{$sfs[$j]}\n";
#					print LOG "CHECK2\t$sfs[$j]-$sfs[$i]:$link_cnt{$sfs[$j]}{$sfs[$i]}\n";
					$sum_link = $link_cnt{$sfs[$i]}{$sfs[$j]} + $link_cnt{$sfs[$j]}{$sfs[$i]};
					print LOG "$sfs[$i]-$sfs[$j]\t$link_cnt{$sfs[$i]}{$sfs[$j]}\n";
					if($sum_link >= $read_cutoff){
						my @reads = split(/,/,$link{$sfs[$i]}{$sfs[$j]});
						for(my $k = 0; $k < $#reads; $k+=2){
							print OUT "CLUSTER$cluster\t$reads[$k]\n";
							print OUT "CLUSTER$cluster\t$reads[$k+1]\n";
						}
						if(exists $nolink{$sfs[$i]}){
							my @remain_reads1 = split(/,/,$nolink{$sfs[$i]});
							for(my $k = 0; $k <= $#remain_reads1; $k++){
								print OUT "CLUSTER$cluster\t$remain_reads1[$k]\n";
							}
							delete $nolink{$sfs[$i]};
						}
						if(exists $nolink{$sfs[$j]}){
							my @remain_reads2 = split(/,/,$nolink{$sfs[$j]});
							for(my $k = 0; $k <= $#remain_reads2; $k++){
								print OUT "CLUSTER$cluster\t$remain_reads2[$k]\n";
							}
							delete $nolink{$sfs[$j]};
						}
						if(exists $multi_reads{$sfs[$i]}{$sfs[$j]}){
							my @mreads1 = split(/,/,$multi_reads{$sfs[$i]}{$sfs[$j]});
							for(my $m = 0; $m <= $#mreads1; $m++){
								print OUT "CLUSTER$cluster\t$mreads1[$m]\n";
							}
							delete $multi_reads{$sfs[$i]}{$sfs[$j]};
						}
						if(exists $multi_reads{$sfs[$j]}{$sfs[$i]}){
							my @mreads2 = split(/,/,$multi_reads{$sfs[$j]}{$sfs[$i]});
							for(my $m = 0; $m <= $#mreads2; $m++){
								print OUT "CLUSTER$cluster\t$mreads2[$m]\n";
							}
							delete $multi_reads{$sfs[$j]}{$sfs[$i]};
						}
					}
				}elsif(exists $link_cnt{$sfs[$i]}{$sfs[$j]} && !exists $link_cnt{$sfs[$j]}{$sfs[$i]}){
#					print LOG "CHECK3\t$sfs[$i]-$sfs[$j]:$link_cnt{$sfs[$i]}{$sfs[$j]}\n";
					$sum_link = $link_cnt{$sfs[$i]}{$sfs[$j]};
					print LOG "$sfs[$i]-$sfs[$j]\t$link_cnt{$sfs[$i]}{$sfs[$j]}\n";
					if($sum_link >= $read_cutoff){
						my @reads = split(/,/,$link{$sfs[$i]}{$sfs[$j]});
						for(my $k = 0; $k < $#reads; $k+=2){
							print OUT "CLUSTER$cluster\t$reads[$k]\n";
							print OUT "CLUSTER$cluster\t$reads[$k+1]\n";
						}
						if(exists $nolink{$sfs[$i]}){
							my @remain_reads1 = split(/,/,$nolink{$sfs[$i]});
							for(my $k = 0; $k <= $#remain_reads1; $k++){
								print OUT "CLUSTER$cluster\t$remain_reads1[$k]\n";
							}
							delete $nolink{$sfs[$i]};
						}
						if(exists $nolink{$sfs[$j]}){
							my @remain_reads2 = split(/,/,$nolink{$sfs[$j]});
							for(my $k = 0; $k <= $#remain_reads2; $k++){
								print OUT "CLUSTER$cluster\t$remain_reads2[$k]\n";
							}
							delete $nolink{$sfs[$j]};
						}
						if(exists $multi_reads{$sfs[$i]}{$sfs[$j]}){
							my @mreads1 = split(/,/,$multi_reads{$sfs[$i]}{$sfs[$j]});
							for(my $m = 0; $m <= $#mreads1; $m++){
								print OUT "CLUSTER$cluster\t$mreads1[$m]\n";
							}
							delete $multi_reads{$sfs[$i]}{$sfs[$j]};
						}
						delete $link_cnt{$sfs[$i]}{$sfs[$j]};
					}
				}elsif(!exists $link_cnt{$sfs[$i]}{$sfs[$j]} && exists $link_cnt{$sfs[$j]}{$sfs[$i]}){
#					print LOG "CHECK4\t$sfs[$j]-$sfs[$i]:$link_cnt{$sfs[$j]}{$sfs[$i]}\n";
					$sum_link = $link_cnt{$sfs[$j]}{$sfs[$i]};
					print LOG "$sfs[$j]-$sfs[$i]\t$link_cnt{$sfs[$j]}{$sfs[$i]}\n";
					if($sum_link >= $read_cutoff){
						my @reads = split(/,/,$link{$sfs[$j]}{$sfs[$i]});
						for(my $k = 0; $k < $#reads; $k+=2){
							print OUT "CLUSTER$cluster\t$reads[$k]\n";
							print OUT "CLUSTER$cluster\t$reads[$k+1]\n";
						}
						if(exists $nolink{$sfs[$i]}){
							my @remain_reads1 = split(/,/,$nolink{$sfs[$i]});
							for(my $k = 0; $k <= $#remain_reads1; $k++){
								print OUT "CLUSTER$cluster\t$remain_reads1[$k]\n";
							}
							delete $nolink{$sfs[$i]};
						}
						if(exists $nolink{$sfs[$j]}){
							my @remain_reads2 = split(/,/,$nolink{$sfs[$j]});
							for(my $k = 0; $k <= $#remain_reads2; $k++){
								print OUT "CLUSTER$cluster\t$remain_reads2[$k]\n";
							}
							delete $nolink{$sfs[$j]};
						}
						if(exists $multi_reads{$sfs[$j]}{$sfs[$i]}){
							my @mreads2 = split(/,/,$multi_reads{$sfs[$j]}{$sfs[$i]});
							for(my $m = 0; $m <= $#mreads2; $m++){
								print OUT "CLUSTER$cluster\t$mreads2[$m]\n";
							}
							delete $multi_reads{$sfs[$j]}{$sfs[$i]};
						}
						delete $link_cnt{$sfs[$j]}{$sfs[$i]};
					}
				}
			}
		}
	}
	$cluster++;
}

foreach my $single_sf(sort keys %nolink){
	print LOG ">CLUSTER$cluster(contain 1 cluster): $single_sf\n";
	my @reads = split(/,/,$nolink{$single_sf});
	for(my $i = 0; $i <= $#reads; $i++){
		print OUT "CLUSTER$cluster\t$reads[$i]\n";
	}
	$cluster++;
}
close OUT;
close LOG;
