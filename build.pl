#!/usr/bin/env perl

use strict;
use warnings;
use FindBin '$Bin';
use File::Basename;

my $mode = shift;

if(! $mode){
	my $src = basename($0);
	print STDERR "\$./$src install\n";
	print STDERR "\$./$src uninstall\n";

	exit;
}

my $src_path = "$Bin/sources";
my $thirdparty_path = "$Bin/third_party";
my $log_dir = "$Bin/third_party/logs";
`mkdir -p $log_dir`;

if($mode eq "install"){
	# Unzip Kent utilities
	print STDERR ">> Unzip kent utilities...";
	`tar xf $src_path/kent.tar.gz -C $thirdparty_path`;
	print STDERR "Done\n";

	# Unzip bowtie2
	print STDERR ">> Unzip bowtie2...";
	`wget https://github.com/BenLangmead/bowtie2/releases/download/v2.4.2/bowtie2-2.4.2-linux-x86_64.zip -P $src_path/`;
	`unzip $src_path/bowtie2-2.4.2-linux-x86_64.zip -d $thirdparty_path`;
	`cp $thirdparty_path/bowtie2-2.4.2-linux-x86_64/bowtie2 $Bin/bin/`;
	`rm -f $src_path/bowtie2-2.4.2-linux-x86_64.zip`;
	print STDERR "Done\n";

	# Preparing bedtools2
	print STDERR ">> Preparing bedtools2...";
	`tar xf $src_path/bedtools_2.17.0.orig.tar.gz -C $thirdparty_path`;
	`mv $thirdparty_path/bedtools-2.17.0 $thirdparty_path/bedtools2`;
	`make -C $thirdparty_path/bedtools2 2> $log_dir/bedtools2.log`;
	if(-f "$thirdparty_path/bedtools2/bin/bedtools"){
		print STDERR "Done\n";
	}else{
		print STDERR "Error\n";
		exit(1);
	}

	# Preparing bwa
	print STDERR ">> Preparing bwa...";
	`tar xf $src_path/bwa.tar.gz -C $thirdparty_path`;
	`make -C $thirdparty_path/bwa 2> $log_dir/bwa.log`;
	if(-f "$thirdparty_path/bwa/bwa"){
		print STDERR "Done\n";
	}else{
		print STDERR "Error\n";
		exit(1);
	}

	# Preparing lastz
	print STDERR ">> Preparing lastz...";
	`tar xf $src_path/lastz-distrib-1.04.00.tar.gz -C $thirdparty_path`;
	`make -C $thirdparty_path/lastz-distrib-1.04.00 2> $log_dir/lastz.log`;
	if(-f "$thirdparty_path/lastz-distrib-1.04.00/src/lastz"){
		print STDERR "Done\n";
	} else {
		print STDERR "Error\n";
		exit(1);
	}

	# Preparing makeBlocks
	print STDERR ">> Preparing makeBlocks...";
	`tar xf $src_path/makeBlocks.tar.gz -C $thirdparty_path`;
	`make -C $thirdparty_path/makeBlocks 2> $log_dir/makeBlocks.log`;
	print STDERR "Done\n";

	# Preparing samtools
	print STDERR ">> Preparing samtools...";
	`tar xf $src_path/samtools-1.9.tar.gz -C $thirdparty_path`;
	chdir("$thirdparty_path/samtools-1.9");
	`configure 2> ../logs/samtools.config.log`;
	`make 2> ../logs/samtools.log`;
	chdir($Bin);
	if(-f "$thirdparty_path/samtools-1.9/samtools"){
			`cp $thirdparty_path/samtools-1.9/samtools $Bin/bin/`;
		print STDERR "Done\n";
	} else {
		print STDERR "Error\n";
		exit(1);
	}

	# SPAdes
	print STDERR ">> Preparing SPAdes assembler...";
	`tar xf $src_path/SPAdes-3.15.4-Linux.tar.gz -C $thirdparty_path`;
	if(-f "$thirdparty_path/SPAdes-3.15.4-Linux/bin/spades.py"){
		`cp $thirdparty_path/SPAdes-3.15.4-Linux/bin/spades.py $Bin/bin/`;
		print STDERR "Done\n";
	}else{
		print STDERR "Error\n";
		exit(1);
	}

}else{
	chdir($thirdparty_path);
	`rm -rf *`;
	chdir($Bin);
}
