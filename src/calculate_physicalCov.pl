#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use FindBin '$Bin';

my $bamFile = shift;
my $lib = shift;
my $sizeFile = shift;
my $workingDir = shift;

my $prefix = basename($bamFile, '.bam');

`$Bin/../third_party/samtools-1.9/samtools sort -n $bamFile  > $workingDir/$lib.sort.bam`;
`$Bin/../third_party/bedtools2/bin/bamToBed -i $workingDir/$lib.sort.bam -bedpe > $workingDir/$lib.bed`;
`cut -f 1,2,6 $workingDir/$lib.bed | sort -k 1,1 > $workingDir/$lib.physical.bed`;
`$Bin/../third_party/bedtools2/bin/bedtools genomecov -i $workingDir/$lib.physical.bed -g $sizeFile -d > $workingDir/$lib.physicalCov.txt`;
