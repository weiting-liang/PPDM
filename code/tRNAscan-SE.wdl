version 1.0

workflow batch_analysis {
    input {
        String Batch_id
        String input_dir  # 保持input_dir为String类型
        String docker_image = "stereonote_hpc_external/liangweiting_3f25d44e851f4c6e8edb6cad1d6ce377_private:latest"
        String suffix = "fna"
    }

    call Unzip {
        input:
            input_dir = input_dir
    }

    call tRNAscan {
        input:
            Batch_id = Batch_id,
            input_dir = Unzip.unzipped_dir,
            docker_image = docker_image,
            suffix = suffix
    }

    output {
        File trna_result = tRNAscan.trna_result
    }
}

task Unzip {
    input {
        String input_dir  # 保持input_dir为String类型
    }

    command {
        mkdir -p unzipped_dir
        mkdir -p temp_unzip_dir
        tar -xzvf ${input_dir} -C temp_unzip_dir
        mv temp_unzip_dir/*/* unzipped_dir
    }

    output {
        File unzipped_dir = "unzipped_dir"
    }

    runtime {
        docker_url: "stereonote_hpc_external/chenjunhong_c5a0b8b1b8514512a59605522102b530_private:latest"
        req_cpu: 1
        req_memory: "2Gi"
    }
}

task tRNAscan {
    input {
        String Batch_id
        File input_dir
        String docker_image
        String suffix
    }
    
    command <<<
        export PATH=/opt/conda/envs/ProAssessment/bin:$PATH
        for i in $(ls ~{input_dir}/*.~{suffix}); do
            id=$(basename $i .~{suffix})
            timeout 1200 tRNAscan-SE --forceow -B -o $id.tRNA_result.txt $i -l $id.log
            if [ $? -eq 0 ]; then
                tRNA_type_count=$(awk 'NR>2 {print $5}' $id.tRNA_result.txt | sort | uniq | wc -l)
                echo -e "$id\t$tRNA_type_count" > $id.tRNA.count.tsv
            else
                echo "tRNAscan-SE for $id exceeded time limit and was skipped."
            fi
        done
        cat *.tRNA.count.tsv > ~{Batch_id}.tRNA_count2.tsv
>>>

    output {
        File trna_result = "${Batch_id}.tRNA_count2.tsv"
    }

    runtime {
        docker_url: docker_image
        req_cpu: 2
        req_memory: "15Gi"
    }
}
