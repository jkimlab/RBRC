RBRC
-----------------

* Reference genome sequence-based read clustering


System requirements (tested versions)
-----------------

* Programs

        - perl (v5.22.1)
        - python (2.7.12)
        - java (1.8.0)
        - git (2.7.4)
        - gcc, g++ (5.4.0)
        - make (GNU Make 4.1)
        - zip (3.0)
        - Sort::Key::Natural (perl library)
        - Bio::TreeIO (perl library)
        - Parallel::ForkManager (perl library)
        - Switch (perl library)
        

Download and installation
-----------------

* Downloading RBRC

        git clone https://github.com/jkimlab/RBRC.git
        cd RBRC
        
     Installing by docker (https://www.docker.com/)
    
        [Build docker image]
        docker build -t rbrc .
        
        [Run a container]
        docker run -it rbrc /bin/bash
        cd RBRC
        
        (Then third-party tools and and example dataset are set.)


Running RBRC
-----------------

* Running RBRC with example datasets and parameters 
        
        bash example_cmd.sh
   
        * Before running this command, you have to set the examples of RBRC
        
* Options of running RBRC
        
        ./RBRC.pl -p [parameter file]
        
* To run RBRC, you need to prepare a parameter file

        ###############################
        # RBRC clustering parameters #
        ###############################

        #### Running paramters
        THREADS	<number of threads>
        OUTDIR	<output directory>

        #### Reference genomes
        ### FASTA
        REF	1	<Reference name 1> <Reference genome sequence 1>
        REF	2	<Reference name 2> <Reference genome sequence 2>

        #### NGS reads
        ### FASTQ
        >LIB1
        <F read fastq file>
        <R read fastq file>

        #### Pairwise alignment & synteny block construction params
        RESOLUTION	<Resolution to construct synteny: default = 300000>

        #### Physical coverage paramters
        PHY_CUTOFF	LIB1	<minimum cutoff value for physical coverage-based syntenic region break: default = 5>

        #### Synteny-based clustering parameters
        SYN_MIN_LEN <minimum cutoff value of synteny size: default = 1000>
        SYN_CLUSTER_MIN_SIZE    <minimum cutoff value of cluster size from synteny clustering: default = 1000>

        #### Distance-based clustering paramters
        TREE	<phylugenetic tree of reference genomes in newick format>
        READ_DIST_CUTOFF	<maximum cutoff value of read distance for matrix calculation: default = 1000>
        MIN_READS	<minimum cutoff value of amount of reads in a distance-based cluster: default = 500>

        #### Cluster merging parameter
        MERGE_MIN_READS	<minimum cutoff value of links to merge clusters: default = 5>


RBRC output
-----------------

* Clustering output

        (1) output_directory/final.idRecover.cluster : list of cluster and clustered reads
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
                
        (2) output_directory/post_processing/clusters.fa
                : Clustered read sequences in FASTA format
        (3) output_directory/post_processing/non-clusters.fa
                : Unclustered read sequences in FASTA format


Additional information
--------

        
   How to intall and uninstall third-party tools  
        
        [ Install RBRC package ]
        ./setup.pl --install
        
        [ Uninstall RBRC package ]
        ./setup.pl --uninstall
        
   How to make an example dataset 
         
         ./setup.pl --example

