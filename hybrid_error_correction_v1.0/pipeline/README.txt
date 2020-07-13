# Program: Hybrid_error_correction (via bayesian model)
# Version: 0.1
# Contact: Zhixin Li <lizhixin@genomics.cn>

1.set PATH in run_hybrid_error_correction_v1.0.sh, t will be used at `bwa mem -t` and `GATK -nt`, it depends on your ref and PB data, if your ref > 50M, you'd better set t to 16 or 32, or call GVCF step will be very slow; if your PB data > 5G, you must set java_mem to 20~30g, or call GVCF step will collapse.

2.Locally run the script `sh run_hybrid_error_correction_v1.0.sh`, it will generate some DIR and FILE, then cd in the DIR, and qub the cmd 'run_hiseq_call_gvcf.sh' and 'run_PB_call_gvcf.sh'

3.After the GVCF is finished, qsub `split_bam.sh`

4.Finally, run the 
