version 1.0
workflow SingleBinning{
    input {
        String Sampleid
        File contig
        File Rmhost1
        File Rmhost2
    }
    call alignment_metabat2 {
        input:
            contig=contig,
            rmhost1=Rmhost1,
            rmhost2=Rmhost2,
            sampleid=Sampleid
        }
    call metabats2 {
        input:
            bam=alignment_metabat2.bam,
            bai=alignment_metabat2.bai,
            contig=contig,
            sampleid=Sampleid
        }
    call maxbin2 {
        input:
            contig=contig,
            sampleid=Sampleid,
            metabat2_coverage=metabats2.coverage
    }
    call concoct {
        input:
            bam=alignment_metabat2.bam,
            bai=alignment_metabat2.bai,
            contig=contig,
            sampleid=Sampleid
    }

    output {
        File metabat2_res = metabats2.bins
        File maxbin2_res = maxbin2.res
        File concoct_res = concoct.res
    }
}

task alignment_metabat2 {
    input {
        File contig
        File rmhost1
        File rmhost2
        String sampleid
    }
    Int mem = 80
    command {
        bwa index "${contig}" -p "${contig}" 2> "${sampleid}.megahit.index.log"
        bwa mem -t 8 "${contig}" "${rmhost1}" "${rmhost2}" > "${sampleid}.megahit.align.sam" 2> "${sampleid}.megahit.align.reads2scaftigs.log"
        samtools flagstat -@8 "${sampleid}.megahit.align.sam" > "${sampleid}.megahit.align2scaftigs.flagstat"
        samtools sort -m 8G -@8 -o "${sampleid}.megahit.align2scaftigs.sorted.bam" -O BAM "${sampleid}.megahit.align.sam"
        samtools index -@8 "${sampleid}.megahit.align2scaftigs.sorted.bam" "${sampleid}.megahit.align2scaftigs.sorted.bam.bai" 2>> "${sampleid}.megahit.align.reads2scaftigs.log"
        rm "${sampleid}.megahit.align.sam"
    }
    output {
        File flagstat = "${sampleid}.megahit.align2scaftigs.flagstat"
        File bam = "${sampleid}.megahit.align2scaftigs.sorted.bam"
        File bai = "${sampleid}.megahit.align2scaftigs.sorted.bam.bai"
  }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_56465bc053a8438281e79492306a708a_private:latest"
        req_cpu:8
        req_memory:"~{mem}Gi"
  }
}

task metabats2 {
    input {
        File bam
        File bai
        File contig
        String sampleid
    }
    command {
        mkdir "${sampleid}_metabat2"
        jgi_summarize_bam_contig_depths --outputDepth "${sampleid}.megahit.metabat2.coverage" --percentIdentity 97 --minMapQual 0 ${bam} 2> "${sampleid}.megahit.metabat2.coverage.log"
        metabat2 --inFile ${contig} --abdFile "${sampleid}.megahit.metabat2.coverage" --outFile "${sampleid}_metabat2/${sampleid}.megahit.metabat2.bin" --minContig 1500 --maxP 95 --minS 60 --maxEdges 200 --pTNF 0 --minCV 1 --minCVSum 1 --seed 2023 --numThreads 8 --verbose > "${sampleid}.megahit.metabat2.binning.log"
        tar -zcvf "${sampleid}_metabat2.tar.gz" "${sampleid}_metabat2"
    }
    output {
        File bins = "${sampleid}_metabat2.tar.gz"
        File coverage = "${sampleid}.megahit.metabat2.coverage"
  }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_970903f5a60a4b139efbe3cbfdfa96b3_private:latest"
        req_cpu:8
        req_memory:"8Gi"
  }
}



task maxbin2 {
    input {
        String sampleid
        File metabat2_coverage
        File contig
    }
    
    command <<<
        cut -f1,3 ~{metabat2_coverage} | tail -n +2 > maxbin2.coverage
        export PATH=/opt/conda/bin:$PATH
        mkdir ~{sampleid}_maxbin2
        run_MaxBin.pl \
                -thread 8 \
                -contig ~{contig} \
                -abund maxbin2.coverage \
                -min_contig_length 1500 \
                -max_iteration 50 \
                -prob_threshold 0.9 \
                -plotmarker \
                -markerset 107 \
                -out ~{sampleid}_maxbin2/~{sampleid}.maxbin2.bin \
                > ~{sampleid}_maxbin2.log 2>&1
        cd ~{sampleid}_maxbin2
        for file in *.fasta; do
            newfile=$(echo "$file" | sed 's/\.fasta$/.fa/')
            mv "$file" "$newfile"
        done
        cd ..
        tar -zcvf ~{sampleid}_maxbin2.tar.gz ~{sampleid}_maxbin2
    >>>
    output {
        File res = "~{sampleid}_maxbin2.tar.gz"
    }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_5fa00403f0f34c49a3e36a511da52e81_private:latest"
        req_cpu:8
        req_memory:"6Gi"
    }
}

task concoct {
    input {
        String sampleid
        File contig
        File bam
        File bai
    }
    
    command <<<
        export PATH=/opt/conda/bin:$PATH
        mkdir ~{sampleid}_concoct
        mv ~{contig} ~{sampleid}.fa
        cut_up_fasta.py \
            ~{sampleid}.fa \
            --chunk_size 10000 \
            --overlap_size 0 \
            --merge_last \
            --bedfile ~{sampleid}.scaftigs_bed \
            > ~{sampleid}.scaftigs_cut

        concoct_coverage_table.py \
            ~{sampleid}.scaftigs_bed \
            ~{bam} \
            > ~{sampleid}.concoct.coverage

        concoct \
                --threads 8 \
                --basename ~{sampleid}.concoct.bin \
                --coverage_file ~{sampleid}.concoct.coverage \
                --composition_file ~{sampleid}.scaftigs_cut \
                --clusters 400 \
                --kmer_length 4 \
                --length_threshold 1000 \
                --read_length 100 \
                --total_percentage_pca 90 \
                --seed 2020 \
                --iterations 500 \
                2> ~{sampleid}_concoct.log
        
        merge_cutup_clustering.py ~{sampleid}.concoct.bin_clustering_gt1000.csv > ~{sampleid}.concoct.bin_clustering_merged.csv

        extract_fasta_bins.py \
                ~{sampleid}.fa \
                ~{sampleid}.concoct.bin_clustering_merged.csv \
                --output_path ~{sampleid}_concoct
        cd ~{sampleid}_concoct
        for file in *.fa; do
            mv "$file" "~{sampleid}.concoct.$file"
        done
        cd ..
        tar -zcvf ~{sampleid}_concoct.tar.gz ~{sampleid}_concoct
    >>>
    output {
        File res = "~{sampleid}_concoct.tar.gz"
    }
    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_c1e5ac631237412d8714accbe613e278_private:latest"
        req_cpu:8
        req_memory:"6Gi"
    }
}