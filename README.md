# OVERVIEW

RBRC is a tool for NGS paired-end read clustering and de novo assembly based on Reference genome sequence-based read clustering

## REQUIREMENTS

### System requirements

- gcc, g++ (7.5.0)
- make (GNU Make 4.1)
- java (1.8.0)
- wget (1.17.1)
- zip (3.0)
- git (2.7.4)

### Perl libraries

- Sort::Key::Natural (perl library)
- Bio::TreeIO (perl library)
- Parallel::ForkManager (perl library)
- Switch (perl library)

## INSTALLATION

### Manual installation

- Download and install using RBRC package from this github page. You can install all third party tools automatically for running RBRC using 'setup.pl'. 

        git clone https://github.com/jkimlab/RBRC.git
        cd RBRC
        ./setup.pl --install
        
### Docker installation

- If you use Docker, you can download and use RBRC with all dependencies through pulling docker image.

        docker pull jkimlab/rbrc

- If you want to see manual for running RBRC docker image, see :point_right: [RBRC Docker hub](https://hub.docker.com/r/jkimlab/rbrc)


## RUNNING RBRC

### Example data

        ./setup.pl --example
        bash example_cmd.sh
   
        * Before running this command, you have to set the examples of RBRC
        
* Options of running RBRC
        
        ./RBRC.pl -p [parameter file] -o [output directory]
        
* To run RBRC, you need to prepare a parameter file as follows

        #---------------------------------------------------------------------------------------#
        ## Mendatory !
        # Reference genomes
        REF	1	<Reference name 1> <Reference genome sequence 1>
        REF	2	<Reference name 2> <Reference genome sequence 2>

        # NGS reads
        # FASTQ
        >LIB1
        <F read fastq file>
        <R read fastq file>

        #---------------------------------------------------------------------------------------#
        ## Optional
        # Running paramters
        THREADS        <number of threads: default = 1>
        REF_SIMILARITY_CUTOFF <minimum cutoff value of properly mapped reads: default = 80>
        MAPQ <read mapping quality threshold: default = 0>

        # Pairwise alignment & synteny block construction params
        RESOLUTION	<Resolution to construct synteny: default = 10000

        # Physical coverage paramters
        PHY_CUTOFF	LIB1	<minimum cutoff value for physical coverage-based syntenic region break: default = 5>

        # Distance based clustering paramters
        DBC_READ_DIST_CUTOFF	<maximum cutoff value of read distance for matrix calculation: default = 1000>

        # Cluster merging parameter
        MERGE_MIN_READS	<minimum cutoff value of links to merge clusters: default = 5>
        #---------------------------------------------------------------------------------------#
       

## RBRC output


* Clustering output

        output_directory/RBRC.cluster : list of cluster and clustered reads
         - Column 1: name of cluster
         - Column 2: Read ID
         
        [example]
                CLUSTER1	chr8-278460/1
                CLUSTER1	chr8-278460/2
                CLUSTER1	chr8-278414/1
                CLUSTER1	chr8-278414/2
                CLUSTER1	chr8-278396/1
                CLUSTER1	chr8-278396/2
                CLUSTER1	chr8-278392/1
                CLUSTER1	chr8-278392/2
                CLUSTER1	chr8-278382/1
                CLUSTER1	chr8-278382/2
                

* Assembly output 

        output_directory/SPAdes/Final_assembly/assembly.fasta
