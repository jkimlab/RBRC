#!/usr/bin/perl

use strict;
use warnings;
use Sort::Key::Natural 'natsort';

my $cluster_f = shift;
my $read_len_cutoff = shift;

my %hs_read = ();
my %hs_base = ();
my $line = 0;
open(F,$cluster_f);
while(<F>){
	chomp;
	$line++;
#	print STDERR "\r$line";
#	$|++;
	my ($cluster,$read) = split(/\s+/);
	my ($read_id, $base) = split(/\//,$read);
	if(!exists($hs_read{$read_id}{$base})){
			$hs_read{$read_id}{$base} = $cluster;
	}
	else{
			if($cluster ne $hs_read{$read_id}{$base}){
					print STDERR "ERROR: $read: $cluster, $hs_read{$read_id}{$base}\n";
			}
			else{ print STDERR "Warning: $read was written twice or more -> fixed\n"; }
	}
#	$hs_base{$base}{$cluster_id} = 0;
}
close(F);
print STDERR "\nAll reads are saved\n";


my %hs_rehash = ();
my %hs_cluster_count = ();
print STDERR "tail check\n";
foreach my $read_id (natsort keys %hs_read){
		if(exists($hs_read{$read_id}{1}) && exists($hs_read{$read_id}{2})){
#				print STDERR "\r1";
				my $cluster1 = $hs_read{$read_id}{1};
				my $cluster2  = $hs_read{$read_id}{2};
				if($cluster1 ne $cluster2){ 
						print STDERR "each pair is in different cluster -> removed from cluster\n";
						delete($hs_read{$read_id}{1});
						delete($hs_read{$read_id}{2});
						next;
				} ##### Added at 20.08.05 
				if(!exists($hs_rehash{$cluster1})){ $hs_rehash{$cluster1} = "$read_id/1"; }
				else{ $hs_rehash{$cluster1} .= " $read_id/1"; }
				if(!exists($hs_rehash{$cluster2})){ $hs_rehash{$cluster2} = "$read_id/2"; }
				else{ $hs_rehash{$cluster2} .= " $read_id/2"; }
				delete($hs_read{$read_id}{1});
				delete($hs_read{$read_id}{2});
		}
		else{
				if(exists($hs_read{$read_id}{1})){
#						print STDERR "\r2";
						my $cluster = $hs_read{$read_id}{1};
						print STDERR "$read_id/1 is in $cluster and $read_id/2 is not clustered -> $read_id/2 is assigned to $cluster\n";
						if(!exists($hs_rehash{$cluster})){ $hs_rehash{$cluster} = "$read_id/1 $read_id/2"; }
						else{ $hs_rehash{$cluster} .= " $read_id/1 $read_id/2"; }
						delete($hs_read{$read_id}{1});
				}
				else{
#						print STDERR "\r3";
						my $cluster = $hs_read{$read_id}{2};
						print STDERR "$read_id/2 is in $cluster and $read_id/1 is not clustered -> $read_id/1 is assigned to $cluster\n";
						if(!exists($hs_rehash{$cluster})){ $hs_rehash{$cluster} = "$read_id/1 $read_id/2"; }
						else{ $hs_rehash{$cluster} .= " $read_id/1 $read_id/2"; }
						delete($hs_read{$read_id}{1});
				}
		}
#		$|++;
}
print STDERR "\nPrint merged.tailed.cluster\n";

my $i = 0;
foreach my $cluster (natsort keys %hs_rehash){
	my @read_arr = split(/\s+/,$hs_rehash{$cluster});
	if(scalar @read_arr < $read_len_cutoff){next;}
	$i++;
	foreach my $read (@read_arr){
		print "CLUSTER$i\t$read\n";
	}
}
