version 1.0
workflow metaspades_pe {
    input {
        File Fq1
        File Fq2
        String Sampleid
    }

    call metaspades {
        input:
            sampleid=Sampleid,
            fastq1=Fq1,
            fastq2=Fq2
    }
    
    output {
        File sc=metaspades.scaffolds
    }
}

task metaspades {
    input {
        String sampleid
        File fastq1
        File fastq2
    }
    command {
        export TMPDIR=/short/tmpdir
        mkdir -p ~{sampleid}_metaspades
        metaspades.py -1 ~{rmhost_fastq1} -2 ~{rmhost_fastq2} -k 21,33,55,77 --memory 81 --threads 8 --checkpoints last -o ~{sampleid}_metaspades >metagenome.metaspades.log
    }
    output {
        File scaffolds = "~{sampleid}_metaspades/scaffolds.fasta"
    }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_ec5fbd9002ee402ca92bbd4436675cf1_private:latest"
        req_cpu:8
        req_memory:"85Gi"
  }
}


