#!/usr/bin/perl

use strict;
use warnings;
use Cwd 'abs_path';
use FindBin '$Bin';
use File::Basename;

my $bam_f = shift;
my $syntenic_bed_f = shift;
my $out_dir = shift;

my $base = basename($bam_f,".bam");

`$Bin/../third_party/bedtools2/bin/bedtools intersect -abam $bam_f -b $syntenic_bed_f -wa -wb -bed > $out_dir/$base.cluster1.bed`;
