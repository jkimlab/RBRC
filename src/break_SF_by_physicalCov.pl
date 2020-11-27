#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Parallel::ForkManager;
use Cwd 'abs_path';
use FindBin '$Bin';

my $outdir = shift;
my $params_F = shift;
my $core = shift;

my $phyCov_D = "$outdir/physical_cov";
my $module_D = $Bin;
my $type = "";
my $chr_size = "";
my $SF_pos = ""; 
my %libraries = ();
my $library = "";

### ForkManager ###
my $pm = new Parallel::ForkManager($core);

print STDERR "1.Read parameter file...\n";
open(RF, $params_F);
while(<RF>){
	chomp;
	if($_ =~ /^#/){
		$type = substr($_,1);
	}elsif($_ eq ""){
		next;
	}else{
		my @cols = split(/\s+/);
		if($type eq "Assembly"){
			if(!-f $cols[1]){print STDERR "No file: $cols[1]\n"; die;}
			$chr_size = $cols[1];
		}elsif($type eq "Synteny"){
			if(!-f $cols[1]){print STDERR "No file: $cols[1]\n"; die;}
			$SF_pos = $cols[1];
		}else{
			if($_ =~ /^>/){
				$library = substr($_,1);
			}else{
				if($cols[0] eq "bamfile"){
					if(!-f $cols[1]){print STDERR "No file: $cols[1]\n"; die;}
					$libraries{$library}{'bam_F'} = abs_path($cols[1]);
				}elsif($cols[0] eq "cutoff"){
					$libraries{$library}{'cutoff'} = $cols[1];
				}else{
					print STDERR "Unknown parameter: $_\n";
					die;
				}
			}
		}
	}
}
close RF;
### Calculate physical coverages ###
print STDERR "2.Calculate physical coverages...\n";
my $working_D = "$phyCov_D/calc_phyCov";
`mkdir -p $working_D`;
my @calc_phyCov_cmds = ();
foreach my $lib(sort {$a cmp $b} keys %libraries){
	my $bam_F = $libraries{$lib}{'bam_F'};

	my $cmd = "perl $module_D/calculate_physicalCov.pl $bam_F $lib $chr_size $working_D";
	push(@calc_phyCov_cmds, $cmd);
}

$pm->run_on_start( sub {
	my @cols = split(/\s+/, $_[1]);
	print STDERR " -$cols[2]\n";
});

foreach my $i(0..$#calc_phyCov_cmds){
	my $pid = $pm->start($calc_phyCov_cmds[$i]) and next;
	system("$calc_phyCov_cmds[$i]");
	$pm->finish($i);
}
$pm->wait_all_children;

my %synteny = ();
my %base_inSF = ();
print STDERR "3.Get the position of syntenies...\n";
open(RF, $SF_pos);
open(WF, ">$phyCov_D/assembly_containSF.txt");
my %chr = ();
while(<RF>){
	chomp;
	my @cols = split(/\s+/);
	my $start = $cols[1]+1;
	my $end = $cols[2];

	$synteny{$cols[0]}{$cols[3]} = "$start\t$end";
	
	if(! exists $chr{$cols[0]}){
		print WF "$cols[0]\n";
		$chr{$cols[0]} = 1;
	}
}
close RF;
close WF;

my @misAsm = ();
my @coverage_Fs = <$working_D/*.physicalCov.txt>;
print STDERR "4.Find the putative misassemblies...\n";
my @find_misAsm_cmds = ();
foreach my $coverage_F(sort @coverage_Fs){
	my $lib = basename($coverage_F, ".physicalCov.txt");
	$coverage_F = abs_path($coverage_F);
	my $cmd = "perl $module_D/find_misAssembly.pl $coverage_F $phyCov_D/assembly_containSF.txt $libraries{$lib}{'cutoff'} $phyCov_D";
	push(@find_misAsm_cmds, $cmd);
}

$pm->run_on_start( sub {
	my @cols = split(/\s+/, $_[1]);
	print STDERR " -$cols[2]\n";
});

foreach my $i(0..$#find_misAsm_cmds){
	my $pid = $pm->start($find_misAsm_cmds[$i]) and next;
	system("$find_misAsm_cmds[$i]");
	$pm->finish($i);
}
$pm->wait_all_children;
print STDERR "5.Find the misassemblies...\n";
my @putMisassembly_F = <$phyCov_D/putMisassemblyRegions*.txt>;
my $find_misAsm_cmd = join(" ",@putMisassembly_F);
my $misasm = join(',', 1..(scalar(@putMisassembly_F)+1));
print STDERR "$Bin/../third_party/bedtools2/bin/multiIntersectBed -i $SF_pos $find_misAsm_cmd | awk '\$5 == \"$misasm\"' | cut -f 1,2,3 > $phyCov_D/misassemblyRegions.txt";
$find_misAsm_cmd = "$Bin/../third_party/bedtools2/bin/multiIntersectBed -i $SF_pos $find_misAsm_cmd | awk '\$5 == \"$misasm\"' | cut -f 1,2,3 > $phyCov_D/misassemblyRegions.txt";
system ($find_misAsm_cmd);

print STDERR "6.Split the syntenies...\n";
print STDERR "$Bin/../third_party/bedtools2/bin/bedtools subtract -a $SF_pos -b $phyCov_D/misassemblyRegions.txt | cut -f 1,2,3,4 > $phyCov_D/split_SF.bed";
my $split_sf_cmd = "$Bin/../third_party/bedtools2/bin/bedtools subtract -a $SF_pos -b $phyCov_D/misassemblyRegions.txt | cut -f 1,2,3,4 > $phyCov_D/split_SF.bed";
system ($split_sf_cmd);
open(RF, "$phyCov_D/split_SF.bed");
my $id = 1;
my $prevSF = "";
while(<RF>){
	chomp;
	my @cols = split(/\s+/);
	if($cols[-1] ne $prevSF){	
		$id = 1;
		$prevSF = $cols[-1];
	}
	print "$_\_$id\n";
	++$id;
}
close RF;
