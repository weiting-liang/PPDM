version 1.0
task prepare {
    input {
        File fq_lists
        String sampleid
        String mul20
    }
    command <<<
        target_contig=$(grep ~{sampleid} ~{fq_lists} | awk '{print $4}')
        bowtie2-build -f $target_contig --threads 4 pre_name
        # len=$(echo ~{mul20} | awk -F',' '{print NF}')
        for index in $(seq 1 20)
        do
            fq1=$(echo ~{mul20} | awk -F',' -v i=$index '{print $i}' | xargs -I id_name grep id_name ~{fq_lists} | awk '{print $2}')
            fq2=$(echo ~{mul20} | awk -F',' -v i=$index '{print $i}' | xargs -I id_name grep id_name ~{fq_lists} | awk '{print $3}')
            bowtie2 -x ./pre_name -1 $fq1 -2 $fq2 -p 4 -S S"$index".sam
            samtools view -@ 4 -b S"$index".sam -o S"$index".bam
            rm -rf S"$index".sam
            samtools sort -@ 4 -l 9 -o S"$index".sorted.bam S"$index".bam
            rm -rf S"$index".bam
        done
    >>>
    output {
        Array[File] outs = glob('./*.sorted.bam')
  }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_56465bc053a8438281e79492306a708a_private:latest"
        req_cpu:4
        req_memory:"20Gi"
  }
}

task multi_metabats2 {
    input {
        Array[File] bams
        File contig_file
        String sampleid
    }
    command {
        mkdir "${sampleid}_mul_metabat2"
        jgi_summarize_bam_contig_depths --outputGC test.outputGC --outputDepth contig.depth.txt ${sep=" " bams}
        metabat2 -t 4 -i ~{contig_file} -a contig.depth.txt -o "${sampleid}_mul_metabat2/${sampleid}_mul_metabat2.bin" -v && tar -zcvf "${sampleid}_mul_metabat2.tar.gz" "${sampleid}_mul_metabat2"
    }
    output {
        File bins = "${sampleid}_mul_metabat2.tar.gz"
  }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_970903f5a60a4b139efbe3cbfdfa96b3_private:latest"
        req_cpu:4
        req_memory:"20Gi"
  }
}

workflow Multiple_Metabat2_pe{
    input {
        File Fq_lists
        String Mul20
        String Sampleid
        File Contig_file
    }
    call prepare {
        input:
                sampleid=Sampleid,
                fq_lists=Fq_lists,
                mul20=Mul20
    }
    call multi_metabats2 {
        input:
            bams=prepare.outs,
            sampleid=Sampleid,
            contig_file=Contig_file
    }
    output {
        File out=multi_metabats2.bins
    }
}