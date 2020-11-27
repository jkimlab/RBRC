#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;
use Cwd 'abs_path';
use lib "$Bin";
use Check::Modules;

my ($check, $tool_install, $uninstall, $db_set, $example_down);
GetOptions(
	"--check" => \$check,
	"--install" => \$tool_install,
	"--uninstall" => \$uninstall,
	"--example" => \$example_down,
);
if(!defined($check) && !defined($tool_install) && !defined($uninstall) && !defined($example_down)){
	print STDERR "Please check the input option\n";
	HELP();
}
if(defined($check)){
	print STDERR "** Check the requirements..\n";
	if(!check_modules()){}
}
elsif(defined($tool_install)){
	print STDERR "** Install all tools of RBRC package..\n";
	`mkdir -p $Bin/bin`;
	`cp $Bin/sources/pilon-1.23.jar $Bin/bin/`;
	`g++ $Bin/src/clustering.cpp -o $Bin/bin/clustering`;
	`g++ $Bin/src/make_distMatrix.cpp -o $Bin/bin/make_distMatrix`;
	`$Bin/build.pl install`;
}
elsif(defined($uninstall)){
	print STDERR "** Uninstall all tools of RBRC package..\n";
	`rm -rf $Bin/bin $Bin/sources/bowtie2* $Bin/sources/ncbi*`;
	`$Bin/build.pl uninstall`;
}
elsif(defined($example_down)){
	print STDERR "** Prepare the example datasets..\n";
	`gunzip -c $Bin/examples/test_dataset/read1.* > $Bin/examples/test_dataset/S288C_simulated1.fq`;
	`gzip $Bin/examples/test_dataset/S288C_simulated1.fq`;
	`gunzip -c $Bin/examples/test_dataset/read2.* > $Bin/examples/test_dataset/S288C_simulated2.fq`;
	`gzip $Bin/examples/test_dataset/S288C_simulated2.fq`;
}


sub HELP{
	my $src = basename($0);
	print STDERR "Usage: ./$src [option]\n";
	print STDERR "--check\n\tCheck the requirements\n";
	print STDERR "--install\n\tInstall the third-party tools\n";
	print STDERR "--uninstall\n\tUninstall the third-party tools\n";
	print STDERR "--example\n\tPrepare the example dataset\n";
	exit();
}
