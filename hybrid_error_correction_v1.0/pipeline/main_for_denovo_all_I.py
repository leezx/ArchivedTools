#!/usr/bin/env python
# Author: LI ZHIXIN
""" 
Pacbio error correction By Bayesian Model use PB and Hiseq data
Usage: python <script> <in.Pacbio.bam> <in.Hiseq.gvcf.gz> <in.PacBio.gvcf.gz> <out.result>
"""

import sys
import re
import pysam
import math

if len(sys.argv) - 1 != 3:
    sys.exit(__doc__)

PB_bam_file, out_file, stat_file = sys.argv[1:]

# PB_bam_file = './chr22_sortByName.filter.bam'
hiseq_gvcf_file = "../../hiseq_gvcf/hiseq.g.vcf.gz"
PB_gvcf_file = "../../PB_gvcf/PB.g.vcf.gz"
PB_fasta_file = "../../PB_gvcf/mergefastq.fasta.gz" # split
bais_file = "correct_stat/bais_file_" + out_file.split('/')[1]
# stat_file = "./stat_result.txt"
# out_file = "./corrected.fastq"

def trans_Qual_to_Phred33(qual):
    if qual < 0:
        return "!"
    elif qual > 60:
        return "]"
    else:
        return chr(qual+33)
    # ASCII = str("!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI")
    # if qual < 0:
    #     return ASCII[0]
    # elif qual > 40:
    #     return ASCII[40]
    # else:
    #     return ASCII[qual]

def calcu_total_score(qual):
    # ASCII = str("!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI")
    total_score = 0
    for letter in qual:
        #temp_score = ASCII.index(letter)
        temp_score = ord(letter)
        total_score += temp_score
    return total_score

def seq_pos_reverse_compliment(seq, qstart, qend):
    """
    qend is fushu!!!
    """
    newseq = ''
    for base in seq:
        if base == 'A':
            newseq += 'T'
        elif base == 'T':
            newseq += 'A'
        elif base == 'G':
            newseq += 'C'
        elif base == 'C':
            newseq += 'G'
        else:
            newseq += 'C'
            #print('fuck '+ base)
    qstart, qend = (( - 1 - qend), ( - 1 - qstart))
    return newseq[::-1], qstart, qend

def formatSeqByCigar(seq, cigar):
    '''
    Input: query_alignment_sequence and cigar from sam file
    Output: formatSeq
    Purpose: make sure the pos is one to one correspondence(seq to ref)
    '''
    formatSeq = ''
    pointer = 0; qstart = 0; qend = -1; origin_seq_len = 0
    if cigar[0][0] == 4 or cigar[0][0] == 5:
        qstart = cigar[0][1]
    if cigar[-1][0] == 4 or cigar[-1][0] == 5:
        qend = - cigar[-1][1] - 1  # fushu count
    for pair in cigar:
        operation = pair[0]
        cigar_len = pair[1]
        if operation == 0: # 0==M
            formatSeq += seq[pointer:(pointer+cigar_len)]
            pointer += cigar_len
            origin_seq_len += cigar_len
        elif operation == 1: # 1==I
            pointer += cigar_len
            origin_seq_len += cigar_len
        elif operation == 2: # 2==D
            formatSeq += 'D'*cigar_len
        elif operation == 4 or operation == 5: # 5==H
            origin_seq_len += cigar_len
            continue
        else:
            print (cigar)
            raise TypeError("There are cigar besides S/M/D/I/H\n")
    return formatSeq, qstart, qend, origin_seq_len

def trans_gvcf_to_DS(rec, gvcf_type):
    ref_pos = rec.pos
    ref = rec.ref
    alts = rec.alts
    alleles = rec.alleles
    format_keys = rec.format.keys()
    sample = rec.samples.keys()[0] # the first sample
    my_filter = list(rec.filter)

    if not "PL" in format_keys: 
        g = [ref]
        PL = [0]
        return ref_pos, [g, PL], True

    if gvcf_type == "haplotype":
        #alleles.remove('<NON_REF>') # abuse of .remove
        alleles = alleles[:-1]
    
    g = list(alleles)  # !!!
    g_count = len(g)
    pl_count = g_count + g_count*(g_count-1)//2
    PL = rec.samples[sample]['PL']
    PL = PL[:pl_count]
    if gvcf_type == "unified": # prevent repeat!!!
        if "LowQual" in my_filter:
            return ref_pos, [g, PL], True
    return ref_pos, [g, PL], False

def singleSiteCorrection(obs, pos, hiseq_gvcf_info, PB_gvcf_info):
    '''
    Input: one observation in newseq and its position
    Output: the underline genotype of this site and its probability
    Purpose: with known: all genotypes, copy number n, R(Hiseq), S(PB), and obs
    use bayesian model to find out the underline g of this site.

    obs: the observed genotype of this site
    g: the underline genotype of this site
    b: in this project, b is the same as g
    M: all the possible genotypes of this sample
    Method: try all g to find out the MAX P.
    '''
    def trans_DS_to_corresponding_dict(DS, pos):
        '''note: {'T/A': 129, 'T/T': 0, 'A/A': 1096}'''
        g = DS[pos][0]
        pl = DS[pos][1]
        len_g = len(g)
        M = {}
        j = 0
        while j < len_g:
            # print ('j:', j)
            k = 0 # gaosiwole
            while k < len_g:
                # print('k:',k)
                F_j_k = k*(k+1)//2 + j
                if k < j:
                    k += 1
                    continue
                M_genotype = str(g[j])+'/'+ str(g[k])
                M[M_genotype] = pl[F_j_k]
                k += 1
                # print('k end\n')
            j += 1
        return M
    
    def calculate_All_Possible_M(g):
        '''note: M = ['A/A', 'A/C', 'C/C'] #from PL line'''
        All_Possible_M = []  
        g = list(g)
        len_g = len(g)
        j = 0
        while j < len_g:
            # print ('j:', j)
            k = 0 # gaosiwole
            while k < len_g:
                # print('k:',k)
                # F_j_k = k*(k+1)//2 + j
                if k < j:
                    k += 1
                    continue
                All_Possible_M.append(str(g[j])+'/'+ str(g[k]))
                k += 1
                # print('k end\n')
            j += 1
        return All_Possible_M
    
    def reverse_M(M):
        M_list = M.split('/')
        M_reversed = '/'.join(M_list[::-1])
        return M_reversed

    g = b = tuple(set((hiseq_gvcf_info[pos][0]) + (PB_gvcf_info[pos][0]))) #from ALT line
    if g == ('N',): # !!!
        return obs, 'I'*len(obs)  # if ref is N, return obs of this site, and a low quality
    len_g = len(g)
    p_b = 1/len_g # p_b = [1, 1/2, 1/3]

    All_Possible_M = calculate_All_Possible_M(g)
    M_Hiseq = trans_DS_to_corresponding_dict(hiseq_gvcf_info, pos)
    M_PB = trans_DS_to_corresponding_dict(PB_gvcf_info, pos)
    #print (g)
    # print('---------------------------')
    # print(g)
    # print(pos, All_Possible_M, M_Hiseq, M_PB)
    
    if len_g == 1:
        return g[0], 'I'*len(g[0])

    best_g_Max_P = {}

    for one_g in g:
        # try each g, and find the best one
        if one_g == obs:
            P_obs_g = 0.85 # edit at 2016-11-28
        elif len(one_g) < len(obs):
            P_obs_g = 0.09
        elif len(one_g) > len(obs):
            P_obs_g = 0.04
        else:
            P_obs_g = 0.02
        # if one_g == obs:
        #     P_obs_g = 0.99
        # else:
        #     P_obs_g = 0.01
        sum_M = 0 # sum of the right side of the formula
        # dic = []

        # eg. All_Possible_M = ['A/A', 'A/C', 'C/C']
        # eg. M_Hiseq = {'T/A': 129, 'T/T': 0, 'A/A': 1096}
        for M in All_Possible_M: # M = 'A/T', but hiseq maybe 'T/A', need to be reversed
            P_g_M = M.count(one_g)/2 # copy number = 2
            M_reversed = reverse_M(M)

            if M in M_Hiseq.keys():
                L_M_R = M_Hiseq[M]
            elif M_reversed in M_Hiseq.keys():
                L_M_R = M_Hiseq[M_reversed]
            else:
                L_M_R = 1000
            
            if M in M_PB.keys():
                L_M_S = M_PB[M]
            elif M_reversed in M_PB.keys():
                L_M_S = M_PB[M_reversed]
            else:
                L_M_S = 1000
            
            L_M_R = 10 ** (L_M_R/(-10))
            L_M_S = 10 ** (L_M_S/(-10))

            sum_b = 0 # sum of denominator of the formula
            P_obs_b = 0
            P_b_M = 0

            for b_one in b:
                if b_one == obs:
                    P_obs_b = 0.99
                else:
                    P_obs_b = 0.01 # P_obs_b = P_obs_g
                P_b_M = M.count(b_one)/2 # P_b_M = [0, 1/2, 2/2]
                sum_b += P_obs_b*P_b_M

            M_list = M.split('/')
            if M_list[0] == M_list[-1]:
                P_M = p_b*p_b
            elif M_list[0] != M_list[-1]:
                P_M = 2*p_b*p_b

            sum_M += P_g_M * L_M_R * L_M_S * P_M / sum_b #gaosile +=
            # print(one_g, sum_M)
        # print ('one_g = ', one_g, ';key = ', key, ';sum_M = ', sum_M)
        best_g_Max_P[one_g] = P_obs_g * sum_M
    #print(best_g_Max_P)
    dic = sorted(best_g_Max_P.items(), key=lambda item:item[1], reverse=True)
    # print(dic)
    if dic[0][1] == 0 or dic[1][1] == 0: # dic [('A', 1.111111111111111e-101), ('ATT', 0.0), ('AT', 0.0)]
        return dic[0][0], "I"*len(dic[0][0])
    Max_P = -10 * math.log10(dic[1][1]/dic[0][1]) # The probability of correct is (1/(1+2)), so the probability of error is (2/1)
    Max_P = int(Max_P)
    Phred = trans_Qual_to_Phred33(Max_P)
    return dic[0][0], "I"*len(dic[0][0])

def merge_seq_in_dic(merge_seq_dic, pre_seq, outf, PB_fasta):
    """
    rec[0] = qstart
    rec[1][0] = qend
    rec[1][1] = seq
    rec[1][2] = qual
    """
    merge_seq_dic = sorted(merge_seq_dic.items(), key=lambda key:key[0])
    # print(merge_seq_dic)
    merged_fasta = PB_fasta.fetch(pre_seq)
    len_merged_fasta = len(merged_fasta)
    PB_reads = merged_fasta[:(len_merged_fasta//2)]
    PB_qual = merged_fasta[(len_merged_fasta//2):]
    if len(PB_reads) != len(PB_qual):
        raise TypeError("len(PB_reads) != len(PB_qual)!!!")
    increment = 0 # indel cause the increment, not one to one
    temp_end = 0
    overlap_len = 0
    pre_qual = 0; temp_qual = 0
    for rec in merge_seq_dic:
        seq_begin = rec[0] + increment
        seq_end = rec[1][0] + increment
        if seq_begin < temp_end:
            overlap_len = temp_end - seq_begin
            pre_qual = calcu_total_score(PB_qual[seq_begin:temp_end+1])
            temp_qual = calcu_total_score(rec[1][2][:overlap_len])
            if pre_qual > temp_qual:
                seq_begin = temp_end + 1
                rec[1][1] = rec[1][1][overlap_len:]
                rec[1][2] = rec[1][2][overlap_len:]
            # print(seqName)
            # print("\n\n!!!!!!!!!!!!rec[0] <= seq_end\n\n")
            # raise TypeError("rec[0] <= seq_end\n")
        PB_reads = PB_reads[0:seq_begin] + rec[1][1] + PB_reads[(seq_end + 1):]
        PB_qual = PB_qual[0:seq_begin] + rec[1][2] + PB_qual[(seq_end + 1):]
        increment = len(rec[1][1]) - (seq_end - seq_begin + 1)
        temp_end = seq_end
        # t_corrected_base_count += len(rec[1][1])
    seqtitle = "@" + pre_seq
    # t_corrected_PB_len += len(PB_reads)
    print(seqtitle, PB_reads, '+', PB_qual, file = outf, sep = '\n', end = '\n')
    if len(PB_reads) != len(PB_qual):
        raise TypeError("finally, len(PB_reads) != len(PB_qual)!!!")
    # return t_corrected_base_count, t_corrected_PB_len

def main():
    PB_bam = pysam.AlignmentFile(PB_bam_file, "rb")
    hiseq_gvcf = pysam.VariantFile(hiseq_gvcf_file)
    PB_gvcf = pysam.VariantFile(PB_gvcf_file)
    PB_reads_fasta = pysam.FastaFile(PB_fasta_file)
    statf = open(stat_file, "w")
    outf = open(out_file, "w")
    baisf = open(bais_file, "w")

    result_count = 0; merge_seq_dic = {}; 
    # for statstic
    diff_count = 0; diff_len = 0; total_len = 0

    for line in PB_bam:
        query_name = line.query_name
        # query_length = line.query_length # cannot be used at "H"
        # qstart = line.qstart # 0st
        # qend = line.qend - 1 # 1st, really strange!!!
        reference_name = line.reference_name
        reference_start = line.reference_start + 1 # abnormal pysam which is 0st, so this is just what we see in sam now!
        reference_end = line.reference_end # this is just the ending base
        cigar    = line.cigar
        query_alignment_sequence = line.query_alignment_sequence

        format_sequence, qstart, qend, origin_seq_len = formatSeqByCigar(query_alignment_sequence, cigar) # pysam can't handle 'H'
        # print(query_name, qstart, qend) # 84 -69
        # print(reference_name, reference_start, reference_end) # chr6 30875861 30880850
        # print(cigar, query_alignment_sequence) # (4, 84), (0, 8), (1, 1),
        # print(format_sequence) # TTTCGGGATTTGTAGTCAGACDCGCTTCADCCDGCTCT

        hiseq_gvcf_info = {}
        for rec in hiseq_gvcf.fetch(reference_name, reference_start-1, reference_end):
            # this format just show record from seqStart to seqEnd
            ref_pos, [g, pl], filter_flag = trans_gvcf_to_DS(rec, "haplotype")
            hiseq_gvcf_info[ref_pos] = [g, pl]

        PB_gvcf_info = {}
        for rec in PB_gvcf.fetch(reference_name, reference_start-1, reference_end):
            # this format just show record from seqStart to seqEnd
            ref_pos, [g, pl], filter_flag = trans_gvcf_to_DS(rec, "unified")
            if ref_pos in PB_gvcf_info.keys() and filter_flag: # prevent repeat!!!
                continue
            PB_gvcf_info[ref_pos] = [g, pl]

        # solve the condition: the ref of two gvcf is not the same, like (A, AC) and (AT, A)
        for pos in range(reference_start, reference_end+1):
            if not pos in PB_gvcf_info.keys():
                PB_gvcf_info[pos] = [['N'], [0]]
            if not pos in hiseq_gvcf_info.keys():
                hiseq_gvcf_info[pos] = [['N'], [0]]
            #---------------------------------------------
            hiseq_ref = hiseq_gvcf_info[pos][0][0]
            PB_ref = PB_gvcf_info[pos][0][0]
            if len(hiseq_ref) < len(PB_ref):
                ref_tail = PB_ref[len(hiseq_ref):]
                for index, each_g in enumerate(hiseq_gvcf_info[pos][0]):
                    hiseq_gvcf_info[pos][0][index] += ref_tail
            elif len(hiseq_ref) > len(PB_ref):
                ref_tail = hiseq_ref[len(PB_ref):]
                for index, each_g in enumerate(PB_gvcf_info[pos][0]):
                    PB_gvcf_info[pos][0][index] += ref_tail

        # print(hiseq_gvcf_info) # 30875861: [('T',), (0,)], 30875862: [('T',), (0,)] --- 30880849: [('T',), (0,)], 30880850: [('G',), (0,)]
        # print(PB_gvcf_info) # 30875861: [('T', 'A'), (0, 335, 2687)], 30875862: [('T', 'A'), (0, 368, 2621)] --- 30880849: [('T', 'A'), (0, 301, 2239)], 30880850: [('G', 'A'), (0, 293, 2578)]

        i = 0; j = 0; corrected_sequence = ''; Qual = ''
        total_len += len(format_sequence)

        # correct base by base...
        for base in format_sequence:
            if i > j: # for indel correction # is this right???
                j += 1
                continue

            pointer = reference_start + i
            ref = hiseq_gvcf_info[pointer][0][0] # !!! attention !!!
            len_ref = len(ref)
            if len(hiseq_gvcf_info[pointer][0][0]) != len(PB_gvcf_info[pointer][0][0]):
                raise TypeError("hiseq_gvcf_info[pointer][0][0]) != len(PB_gvcf_info[pointer][0][0]!!!")

            obs = format_sequence[i:(i+len_ref)] # is this rigth???
            # if not pointer in PB_gvcf_info.keys():
            #     PB_gvcf_info[pointer] = [['N'], [0]]
            # if not pointer in hiseq_gvcf_info.keys():
            #     hiseq_gvcf_info[pointer] = [['N'], [0]]

            real_g, qual = singleSiteCorrection(obs, pointer, hiseq_gvcf_info, PB_gvcf_info)
            # print(qual) # draw the phred distribution
            
            len_real_g = len(real_g)
            # if len_ref == len_real_g:
            # elif len_ref < len_real_g:
            # elif len_ref > len_real_g:
            if real_g != ref:
                diff_count += 1
                diff_len += abs(len(real_g)-len(ref)) + 1

            if obs != ref:
                print(pointer, obs, real_g, ref, file=baisf, sep='\t', end='\n')
            # generate the corrected_sequence and its quality
            corrected_sequence += real_g
            i += len_ref  # this will ignore some position in gvcf!!! this is a usable method, but not the best!!!
            Qual += str(qual) # !!!
            j += 1
        # print(corrected_sequence)
        # print(Qual)

        if len(corrected_sequence) != len(Qual):
            raise TypeError("len(corrected_sequence) != len(Qual)!!!")

        if line.is_reverse:
            reverse_compliment_corrected_sequence, seqStart, seqEnd = seq_pos_reverse_compliment(corrected_sequence, qstart, qend)
            corrected_sequence = reverse_compliment_corrected_sequence
            qstart, qend = seqStart, (seqEnd + origin_seq_len)
            Qual = Qual[::-1] 
        else:
            qend = origin_seq_len + qend

        if len(corrected_sequence) != len(Qual):
            raise TypeError("len(corrected_sequence) != len(Qual)!!! after reverse!!!")
        # print(corrected_sequence, qstart, qend, Qual, line.flag, line.cigarstring)

        # merge record with the same name
        if result_count == 0:
            merge_seq_dic[qstart] = [qend, corrected_sequence, Qual]
            pre_seq = query_name
            result_count += 1
            continue

        if query_name == pre_seq:
            merge_seq_dic[qstart] = [qend, corrected_sequence, Qual]
        else:
            merge_seq_in_dic(merge_seq_dic, pre_seq, outf, PB_reads_fasta)
            # print(merge_seq_dic)
            #------------------------------
            pre_seq = query_name
            merge_seq_dic = {}
            merge_seq_dic[qstart] = [qend, corrected_sequence, Qual]

        # print(corrected_sequence, qstart, qend)
        
        result_count += 1
        # if result_count == 100:
            # break

    merge_seq_in_dic(merge_seq_dic, pre_seq, outf, PB_reads_fasta)
    print("diff_count", "diff_len", "total_len", file = statf, sep = '\t', end = '\n')
    print(diff_count, diff_len, total_len, file = statf, sep = '\t', end = '\n')
    PB_bam.close()
    hiseq_gvcf.close()
    PB_gvcf.close()
    PB_reads_fasta.close()
    statf.close()
    outf.close()
    baisf.close()

if __name__ == "__main__":
    main()
