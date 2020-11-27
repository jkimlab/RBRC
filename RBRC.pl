#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use Cwd;
use Cwd 'abs_path';
use FindBin '$Bin';
use Getopt::Long qw(:config no_ignore_case);
use Sort::Key::Natural 'natsort';
use Switch;
use Parallel::ForkManager;

my $param_f;
my $tmp;
my $out_dir = ".";

GetOptions (
		"param|p=s" => \$param_f,
		"tmp|t=i" => \$tmp,
		"out|o=s" => \$out_dir,
);

## Checking arguments
if(!$param_f){
	print STDERR "\$./RBRC.pl -p [parameter file] -o [output dir]\n";
	exit(1);
}
`mkdir -p $out_dir`;
$out_dir = abs_path("$out_dir");
####### Read paramters
my $threads = 1;
my %ref_names = ();
my %ref_fas = ();
my $resolution = 10000;
my %libs = ();
my %lib_cutoffs = ();
my $sitri_dist_cutoff = 1000;
my $sitri_min_read_cutoff = 1;
my $merge_min_read_cutoff = 5;
my $syn_min_len = 1000;
my $syn_cluster_min_size = 1;
my $weight_f;
my $map_q = 0;
my $chainNet_dir = "$out_dir/chainNet";
my $tree_f = "";

$param_f = abs_path("$param_f");
print STDERR " PARAMS check\n";
open(PARAM,$param_f);
while(<PARAM>){
	chomp;
	if($_ =~ /^#/){next;}
	if($_ =~ /^>(LIB\d+)/){
		my $f = <PARAM>;
		my $r = <PARAM>;
		chomp($f);
		chomp($r);
		$libs{$1}{"F"} = $f;
		$libs{$1}{"R"} = $r;
	}

	my @p = split(/\s+/);
	switch ($p[0]){
		case("THREADS") {$threads = $p[1];}
		case("REF") {
			$ref_names{$p[1]} = $p[2];
			$ref_fas{$p[1]} = $p[3];
		}
		case("RESOLUTION"){$resolution = $p[1];}
		case("MAPQ"){$map_q = $p[1];}
		case("PHY_CUTOFF"){$lib_cutoffs{$p[1]} = $p[2];}
		case("DBC_READ_DIST_CUTOFF"){$sitri_min_read_cutoff = $p[1];}
		case("MERGE_MIN_READS"){$merge_min_read_cutoff = $p[1];}
	}
}
close(PARAM);

my $pm = new Parallel::ForkManager($threads);

####### Making OUT DIR
`mkdir -p $out_dir/logs`;
open(FLOG, ">$out_dir/log.PROGRESS.txt");
print FLOG "[Basic parameters]\n";
print FLOG " - output dir: $out_dir\n";
print FLOG " - param file: $param_f\n";
print FLOG " - threads: $threads\n";
print FLOG " - resolution: $resolution\n";
print FLOG " - mapping quality: $map_q\n";

#### Read id converting
my $read_dir = "$out_dir/Reads";
`mkdir -p $read_dir`;
print STDERR " Read id converting | working at $read_dir\n";
print FLOG " Read id converting | working at $read_dir\n";
foreach my $lib (natsort keys %libs){
	my $l = $lib;
	$l =~ s/LIB//;
	`java -jar $Bin/sources/trimmomatic-0.39.jar PE $libs{$lib}{"F"} $libs{$lib}{"R"} $read_dir/PE.$l.F.fq $read_dir/PE_unpaired.$l.F.fq $read_dir/PE.$l.R.fq $read_dir/PE_unpaired.$l.R.fq ILLUMINACLIP:TruSeq3-PE.fa:2:30:10:2:keepBothReads AVGQUAL:25 >& $out_dir/logs/log.trimmomatic.txt`;
	`$Bin/src/fqNumID.pl $l F $read_dir/PE.$l.F.fq $read_dir`;
	`$Bin/src/fqNumID.pl $l R $read_dir/PE.$l.R.fq $read_dir`;
	$libs{$lib}{"F"} = "$read_dir/$l.F.fq";
	$libs{$lib}{"R"} = "$read_dir/$l.R.fq";
}
print STDERR " - done\n\n";
print FLOG " - done\n\n";

#### FASTA id converting
`mkdir -p $out_dir/pre-processing`;
print STDERR " Reference ID converting & weight calculation | working at $out_dir/pre-processing\n";
print FLOG " Reference ID converting & weight calculation | working at $out_dir/pre-processing\n";
my $total_w = 0;
my $max_w = 0;
my %hs_weight = ();
print STDERR "  Read mapping\n";
print FLOG "  Read mapping\n";
foreach my $num (natsort keys %ref_fas){
	`$Bin/src/fasta_id_convert.pl $ref_fas{$num} $out_dir/pre-processing/$ref_names{$num}.fa`;
	print STDERR "  > $ref_names{$num}\n";
	print FLOG "  > $ref_names{$num}\n";
	my $mapping_ref = "$out_dir/pre-processing/$ref_names{$num}.fa";
	if(!-f "$mapping_ref.ann" || !-f "$mapping_ref.bwt" || !-f "$mapping_ref.pac" || !-f "$mapping_ref.sa"){`$Bin/third_party/bwa/bwa index $mapping_ref`;}
	my ($total_qc_read, $proper_pe_read) = 0;
	foreach my $lib (natsort keys %libs){
		print STDERR "    $lib...\n";
		print FLOG "    $lib...";
		my $f_read = $libs{$lib}{"F"};
		my $r_read = $libs{$lib}{"R"};
		`$Bin/third_party/bwa/bwa mem -t $threads $mapping_ref $f_read $r_read | $Bin/third_party/samtools-1.9/samtools view --threads $threads -h -q $map_q -F 0xF00 -Sb - > $out_dir/pre-processing/$ref_names{$num}.$lib.bam`;
		`$Bin/third_party/samtools-1.9/samtools flagstat -@ 20 $out_dir/pre-processing/$ref_names{$num}.$lib.bam > $out_dir/pre-processing/$ref_names{$num}.$lib.stat`;
		my $cur_reads = `head -1 $out_dir/pre-processing/$ref_names{$num}.$lib.stat | cut -f1 -d ' '`;
		my $cur_proper = `grep properly $out_dir/pre-processing/$ref_names{$num}.$lib.stat | cut -f1 -d ' '`;
		chomp($cur_reads,$cur_proper);
		$total_qc_read += $cur_reads;
		$proper_pe_read += $cur_proper;
		print STDERR "done\n";
		print FLOG "done\n";
	}
	my $perc_proper = ($proper_pe_read/$total_qc_read)*100;
	$hs_weight{$ref_names{$num}} = $perc_proper;
	if($max_w < $perc_proper){ $max_w = $perc_proper; }
	$total_w += $perc_proper;
}

my $i = 1;
my @arr_names = values(%ref_names);
for(my $n = 0; $n <= $#arr_names; $n++){
		if($hs_weight{$arr_names[$n]} == $max_w){ 
				$ref_names{1} = $arr_names[$n];
				foreach my $lib (natsort keys %libs){
					`$Bin/third_party/samtools-1.9/samtools view --threads $threads -h -f 0x03 -b $out_dir/pre-processing/$ref_names{1}.$lib.bam -o $out_dir/pre-processing/$lib.properPE.bam`;
				}
		}
		else{
				$i++;
				$ref_names{$i} = $arr_names[$n];
		}
		$hs_weight{$arr_names[$n]}=sprintf("%.2f", $hs_weight{$arr_names[$n]});
}
print STDERR " - done\n\n";
print FLOG " - done\n\n";
### TEST
print FLOG " # Reference set:\n";
foreach my $num (natsort keys(%ref_names)){
		if($num == 1){ print FLOG " [Leading]\t$ref_names{$num}\t$hs_weight{$ref_names{$num}}\n"; }
		else{ print FLOG " [Supplementary]\t$ref_names{$num}\t$hs_weight{$ref_names{$num}}\n"; }
}
########

#######	Pairwise alignments
print STDERR " Whole genome alignment\n";
print FLOG " Whole genome alignment\n";
foreach my $num (natsort keys %ref_names){
	if($num == 1){ next;}
	print STDERR "  > $ref_names{1} - $ref_names{$num} ...\n";
	print FLOG "  > $ref_names{1} - $ref_names{$num} ...";
	`$Bin/src/whole_genome_alignment.pl -p $threads -m $resolution -r $out_dir/pre-processing/$ref_names{1}.fa -t $out_dir/pre-processing/$ref_names{$num}.fa -o $chainNet_dir`;
	print STDERR " done\n";
	print FLOG " done\n";
}
print STDERR " - done\n\n";
print FLOG " - done\n\n";

####### Building synteny blocks
print STDERR " Building synteny blocks | working at $out_dir/SynBased_clustering/synteny_blocks\n";
print FLOG " Building synteny blocks | working at $out_dir/SynBased_clustering/synteny_blocks\n";
`mkdir -p $out_dir/SynBased_clustering/synteny_blocks`;
`sed -e 's:<willbechanged>:$Bin/third_party/makeBlocks:' $Bin/third_party/makeBlocks/Makefile.SFs > $out_dir/SynBased_clustering/synteny_blocks/Makefile`;
open(CONFIG,">$out_dir/SynBased_clustering/synteny_blocks/config.file");
print CONFIG ">netdir\n$chainNet_dir\n";
print CONFIG ">chaindir\n$chainNet_dir\n\n";
print CONFIG ">species\n";
my %hs_lseq = ();
foreach my $ref_num (natsort keys %ref_names){
	if($ref_num == 1){
		print CONFIG "$ref_names{1}\t0\t0\n";
		open(FLS, "$out_dir/pre-processing/$ref_names{1}.fa");
		while(<FLS>){
				chomp;
				if($_ =~ /^>(.+)/){ $hs_lseq{$1} = 1; }
		}
		close(FLS);
	} else {
		print CONFIG "$ref_names{$ref_num}\t1\t0\n";
		foreach my $seq_id (keys(%hs_lseq)){
				if(!-f "$chainNet_dir/$ref_names{1}/$ref_names{$ref_num}/chain/$seq_id.chain"){
						`touch $chainNet_dir/$ref_names{1}/$ref_names{$ref_num}/chain/$seq_id.chain`;
				}
				if(!-f "$chainNet_dir/$ref_names{1}/$ref_names{$ref_num}/net/$seq_id.net"){
						`touch $chainNet_dir/$ref_names{1}/$ref_names{$ref_num}/net/$seq_id.net`;
				}
		}
	}
}
print CONFIG "\n>resolution\n$resolution\n";
close(CONFIG);
`make -C $out_dir/SynBased_clustering/synteny_blocks 2> $out_dir/SynBased_clustering/synteny_blocks/log`;
`make tidy -C $out_dir/SynBased_clustering/synteny_blocks`;
if(!-f "$out_dir/SynBased_clustering/synteny_blocks/Conserved.Segments"){
		print STDERR "Alignment between references was failed.\nPlease check the alignment files in $chainNet_dir and change the set of references.\n";
		print FLOG "Alignment between references was failed.\nPlease check the alignment files in $chainNet_dir and change the set of references.\n";
		exit();
}
`$Bin/src/syn2bed.pl -s $out_dir/SynBased_clustering/synteny_blocks/Conserved.Segments -o $out_dir/SynBased_clustering/synteny_blocks`;

####### Breaking synteny blocks by physical coverage
print STDERR " Breaking synteny blocks by physical coverage\n";
print FLOG " Breaking synteny blocks by physical coverage\n";
`mkdir -p $out_dir/SynBased_clustering/physical_cov`;

# Making reference size file
`$Bin/third_party/kent/faSize -detailed $out_dir/pre-processing/$ref_names{1}.fa > $out_dir/SynBased_clustering/physical_cov/$ref_names{1}.sizes`;

# Making parameter file
open(W,">$out_dir/SynBased_clustering/physical_cov/physical_cov.params");
print W "#Assembly\nsizefile\t$out_dir/SynBased_clustering/physical_cov/$ref_names{1}.sizes\n\n";
print W "#Synteny\nbedfile\t$out_dir/SynBased_clustering/synteny_blocks/$ref_names{1}.bed\n\n";
print W "#Libraries\n";
foreach my $lib (natsort keys %libs){
	print W ">$lib\n";
	if(!exists($lib_cutoffs{$lib})){ $lib_cutoffs{$lib} = 5; }
	print W "bamfile\t$out_dir/pre-processing/$lib.properPE.bam\ncutoff\t$lib_cutoffs{$lib}\n";
}
close(W);

`$Bin/src/break_SF_by_physicalCov.pl $out_dir/SynBased_clustering $out_dir/SynBased_clustering/physical_cov/physical_cov.params $threads > $out_dir/SynBased_clustering/physical_cov/physical_split_SF.bed`;
print STDERR " - done\n\n";
print FLOG " - done\n\n";


####### Clustering synteny regions
print STDERR " Clustering syteny regions | working at $out_dir/SynBased_clustering\n";
print FLOG " Clustering syteny regions | working at $out_dir/SynBased_clustering\n";
my $cluster1_list = "";
my @lib_arr = natsort(keys %libs);
my $lib_num = scalar(@lib_arr);
for(my $i = 0;$i < $lib_num;$i++){
	my $lib = $lib_arr[$i];
	$cluster1_list .= " $out_dir/SynBased_clustering/$lib.properPE.cluster1.bed";
	$pm -> start and next;
	`$Bin/src/clustering_synteny.pl $out_dir/pre-processing/$lib.properPE.bam $out_dir/SynBased_clustering/physical_cov/physical_split_SF.bed $out_dir/SynBased_clustering`;
	$pm -> finish;
}
$pm -> wait_all_children;
`$Bin/src/bed2cluster.pl $out_dir/SynBased_clustering $cluster1_list`;
`$Bin/src/cluster_filter.pl $resolution 1 $out_dir/SynBased_clustering/physical_cov/physical_split_SF.bed $out_dir/SynBased_clustering/syntenic.cluster > $out_dir/SynBased_clustering/syntenic.filt.cluster`;
print STDERR " - done\n\n";
print FLOG " - done\n\n";


##### Clustering nonsyntenic regions
print STDERR " Extracting unclustered reads | working at $out_dir/DistBased_clustering\n";
print FLOG " Extracting unclustered reads | working at $out_dir/DistBased_clustering\n";
`mkdir -p $out_dir/DistBased_clustering`;
## Extracting Non-syntenic reads
my $read_list = "";
foreach my $lib (natsort keys %libs){
	my $f_read = $libs{$lib}{"F"};
	my $r_read = $libs{$lib}{"R"};

	$read_list .= " $f_read $r_read";
}
`$Bin/src/extract_nonSyn_reads.pl $out_dir/SynBased_clustering/syntenic.filt.cluster $out_dir/SynBased_clustering/multiple_syntenic.reads $out_dir/DistBased_clustering $read_list`;

print STDERR " Extracting mapping information\n";
print FLOG " Extracting mapping information\n";
`mkdir -p $out_dir/DistBased_clustering/temp`;
open(FSP, ">$out_dir/DistBased_clustering/DBC.param");
my $ref_beds = "";
my $filt_beds = "";
for(my $n = 0; $n <= $#arr_names; $n++){
	my $w = sprintf("%.4f",($hs_weight{$arr_names[$n]}/$total_w));
	if(-f "$out_dir/DistBased_clustering/sort.NewID.$arr_names[$n].bed"){ `rm -f $out_dir/DistBased_clustering/sort.NewID.$arr_names[$n].bed`; }
	print FSP "$arr_names[$n]\t$w\t$out_dir/DistBased_clustering/sort.NewID.$arr_names[$n].filt.bed\n";
	foreach my $lib (natsort keys %libs){
		`$Bin/src/extract_nonSyn_map.pl $out_dir/DistBased_clustering/nonSyn_reads.idmap $out_dir/pre-processing/$arr_names[$n].$lib.bam $out_dir/DistBased_clustering/temp`;
		`cat $out_dir/DistBased_clustering/temp/sort.NewID.$arr_names[$n].$lib.bed >> $out_dir/DistBased_clustering/sort.NewID.$arr_names[$n].bed`;
	}
	$ref_beds .= " $out_dir/DistBased_clustering/sort.NewID.$arr_names[$n].bed";
}
`$Bin/src/filtering_bedfile.pl $ref_beds $out_dir/DistBased_clustering`;
print STDERR " - done\n\n";
print FLOG " - done\n\n";
close(FSP);

## SITRI
print STDERR " Distance-based clustering | working at $out_dir/DistBased_clustering\n";
print FLOG " Distance-based clustering | working at $out_dir/DistBased_clustering\n";
my $cur_dir = getcwd;
chdir("$out_dir/DistBased_clustering");
print FLOG "\t> make matrix params\n";
print FLOG "\t> make disMatrix\n";
`$Bin/bin/make_distMatrix $sitri_dist_cutoff $out_dir/DistBased_clustering/DBC.param > $out_dir/DistBased_clustering/DBC.matrix`;
print FLOG "\t> filtering matrix\n";
`$Bin/src/filtering_DBC_matrix.pl $out_dir/DistBased_clustering/*.matrix.txt $out_dir/DistBased_clustering`;
print FLOG "\t> clustering\n";
`$Bin/bin/clustering $sitri_dist_cutoff $merge_min_read_cutoff $out_dir/DistBased_clustering/filt.DBC.matrix`;
print FLOG "\t> Id converting\n";
`$Bin/src/idRecoverSITRI.pl $out_dir/DistBased_clustering/nonSyn_reads.idmap $out_dir/DistBased_clustering/DBC.cluster > $out_dir/DistBased_clustering/DBC.idRecover.cluster`;
chdir($cur_dir);
print STDERR " - done\n\n";
print FLOG " - done\n\n";

####### Merging & revising clusters
print STDERR " Merging & revising clusters | working at $out_dir/post_processing\n";
print FLOG " Merging & revising clusters | working at $out_dir/post_processing\n";
`mkdir -p $out_dir/post_processing`;
`$Bin/src/cluster_merging.pl $out_dir/post_processing $merge_min_read_cutoff $out_dir/SynBased_clustering/multiple_syntenic.reads $out_dir/DistBased_clustering/DBC.idRecover.cluster $out_dir/SynBased_clustering/syntenic.filt.cluster`;
`$Bin/src/adding_pairs.pl $out_dir/post_processing/merged.cluster 1 > $out_dir/post_processing/merged.tailed.cluster`;

my $fq_list = "";
foreach my $lib (natsort keys %libs){
	my $f_read = $libs{$lib}{"F"};
	my $r_read = $libs{$lib}{"R"};
	$fq_list .= " $f_read $r_read";
}
print STDERR " Print final cluster\n";
print FLOG " Print final cluster\n";
`$Bin/src/idRecoverFinalCluster.pl $out_dir/post_processing/merged.tailed.cluster $read_dir/*.map > $out_dir/RBRC.cluster`;
print STDERR " - done\n\n";
print FLOG " - done\n\n";
print STDERR "RBRC clustering is finished.\n\tFinal clustering result: $out_dir/RBRC.cluster\n\n";
print FLOG "RBRC clustering is finished.\n\tFinal clustering result: $out_dir/RBRC.cluster\n\n";

print STDERR "RBRC assembly (with Unicycler)\n";
print FLOG "RBRC assembly (with Unicycler)\n";
`mkdir -p $out_dir/Unicycler/logs`;
#original: `$Bin/src/makeCMD_runUnicycler.pl $out_dir/Reads/PE.1.F.fq $out_dir/Reads/PE.1.R.fq $out_dir/RBRC.cluster $threads $out_dir/Unicycler > $out_dir/Unicycler/cmd_assembly.sh 2> $out_dir/Unicycler/logs/log.makeCMD_runUnicycler.txt`;
`$Bin/src/makeCMD_runUnicycler.pl $out_dir/Reads/1.F.fq $out_dir/Reads/1.R.fq $out_dir/post_processing/merged.tailed.cluster $threads $out_dir/Unicycler > $out_dir/Unicycler/cmd_assembly.sh 2> $out_dir/Unicycler/logs/log.makeCMD_runUnicycler.txt`;
`bash $out_dir/Unicycler/cmd_assembly.sh`;
print STDERR "RBRC assembly is finished.\n\tFinal assembly result: $out_dir/Unicycler/Final_assembly/assembly.fasta\n\n";
print FLOG "RBRC assembly is finished.\n\tFinal assembly result: $out_dir/Unicycler/Final_assembly/assembly.fasta\n\n";

