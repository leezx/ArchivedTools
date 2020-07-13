#ifndef _CALC_CNV_H_ 
#define _CALC_CNV_H_ 
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <list>
#include <map>
#include <exception>
#include <ctime>
#include <cstdlib>
#include <cmath>
#include "../../libgz/gzstream.h"
#include "../../ALL/comm.h"
#include "../soapInDel-v1.09/math_fun.h"
//#include <cstring>
#include <algorithm>
#include <iomanip>
//#include <boost/math/distributions/poisson.hpp>
#include <pthread.h>
#include <unistd.h>
#include <boost/thread/thread.hpp>
#include <boost/thread/mutex.hpp>
#include <boost/bind.hpp>

using namespace boost ;
using namespace std;

typedef unsigned long long ubit64_t;
typedef unsigned short record_t ;

struct bkp_t {
    size_t pos;
    size_t win;
    float depth;
    float var;
    float pval;
    float pgc;
    float fval;
    bool isN;

    bkp_t():pos(0), win(0), depth(0), var(0), pval(0), pgc(0), isN(false){}
};


struct rc_bkp_t {
    size_t pos;
    size_t len;
    int type;
};

struct bkp_comp { 
    bool operator() (bkp_t a,bkp_t b) { return a.pval < b.pval; } 
}; 


class ParaA_CNV {
    public:
        string Ref ;
        string OutPut ;
        string OutPutDepth ;
        string SoapList ;
        string InDepth ;
        size_t ncpu ;
        int min_cnv ; 
        size_t min_merge_win ;
        float p_cutoff  ;
        float max_cutoff ;
        bool bmerge_zero ;
        bool bglobal ;
        float mean_depth_specified ;
        float NERELY_ZERO ;
//        size_t cnv_found_cnt;
        ubit64_t genome_depth_sum ;
        ubit64_t genome_bp_sum ;
        //        bool g_isN_masked ;
        vector <string> chr_vec ;
        vector <float> mean_depth_vec ;
        ParaA_CNV()
        {
            Ref="";
            OutPut="./CnvResult.info";
            OutPutDepth="";
            SoapList="";
            InDepth="";
            ncpu = 1 ;
            min_cnv = 500; 
            min_merge_win = 2000;
            p_cutoff = 0.4;
            max_cutoff = 0.6;
            bmerge_zero = false;
            bglobal = false;
            mean_depth_specified = 0;
            NERELY_ZERO = 0.00001;
            //          g_isN_masked = false;
        }
};




int  print_CNV_usage()
{
    cout <<""
        "\n"
        "\tUsage: SoapCNV  -Ref <in.fa> -InDepth <InDepth.fa> \n"
        "\n"
        "\t\t-Ref        <str>   InPut Ref fa File \n"
        "\t\t-InDepth    <str>   Input File format in Fa\n"
        "\t\t-SoapList   <str>   Input File SoapFile List\n"
        "\t\t-OutPut     <str>   OutPut CNV file [./CnvResult.info]\n"
        "\n"
        "\t\t-IMinPoint  <float> Initial Minimum probability to merge the adjacent breakpoint[0.4]\n"
        "\t\t-FMinPoint  <float> Final Minimum probability to merge the adjacent breakpoint[0.6]\n"
        "\t\t-MinLength  <int>   Minimum CNV length\n"
        "\t\t-CPU        <int>   Number of CPUs to use[1]\n"
        "\t\t-SetMer             Set for merging 0-depth windows\n"
        "\t\t-AllDepth           Call CNV with the mean depth of the whole genome, default[the mean depth of chromosomes]\n"
        "\t\t-SpeDepth <float>   Specify the mean depth of the whole genome, working with '-AllDepth' option\n"
        "\t\t-OutDepth   <str>   Specify the output file for depth information,working with '-SoapList' option\n"
        "\n"
        "\t\t-help              show this help\n" 
        "\t\tAuthor:licai@genomics.cn\tCode Main licai&hewm@genomics.cn\n" 
        "\n";
    return 1;
}


int parse_CNV_cmd(int argc, char **argv , ParaA_CNV * CNVpara )
{
    if (argc <=2 ) {print_CNV_usage();return 0;}
    int A=0;
    int B=0;
    for(int i = 1; i < argc ; i++)
    {
        if(argv[i][0] != '-')
        {
            cerr << "command option error! please check." << endl;
            return 0;
        }
        string flag=argv[i] ;
        flag=replace_all(flag,"-","");

        if (flag  == "Ref" )
        {
            if(i + 1 == argc) { LogLackArg( flag ) ; return 0;}
            i++;
            CNVpara->Ref=argv[i];
        }
        else if (flag  ==  "OutPut")
        {
            if(i + 1 == argc) {  LogLackArg( flag ) ; return 0;}
            i++;
            CNVpara->OutPut=argv[i];
        }
        else if (flag  ==  "InDepth")
        {
            if(i + 1 == argc) {   LogLackArg( flag ) ;return 0;}
            i++;
            A=1;
            CNVpara->InDepth=argv[i];
        }
        else if (flag  ==  "SoapList")
        {
            if(i + 1 == argc) {   LogLackArg( flag ) ;return 0;}
            i++;
            B=1;
            CNVpara->SoapList=argv[i];
        }
        else if (flag  ==  "OutDepth")
        {
            if(i + 1 == argc) { LogLackArg( flag ) ;return 0;}
            i++;
            CNVpara->OutPutDepth=argv[i];
        }
        else if (flag  ==  "CPU" )
        {
            if(i + 1 == argc) { LogLackArg( flag ) ;return 0;}
            i++;
            CNVpara->ncpu=atoi(argv[i]);
        }
        else if (flag  ==  "SpeDepth")
        {
            if(i + 1 == argc) { LogLackArg( flag ) ;return 0;}
            i++;
            CNVpara->mean_depth_specified=atof(argv[i]);
        }
        else if (flag  ==  "IMinPoint")
        {
            if(i + 1 == argc) {  LogLackArg( flag ) ;return 0;}
            i++;
            CNVpara->p_cutoff=atof(argv[i]);
        }
        else if (flag  ==  "FMinPoint")
        {
            if(i + 1 == argc) { LogLackArg( flag ) ; return 0;}
            i++;
            CNVpara->max_cutoff=atof(argv[i]);
        }
        else if (flag  == "AllDepth")
        {
            CNVpara->bglobal = true;
        }
        else if (flag  == "SetMer")
        {
            CNVpara->bmerge_zero = true;
        }

        else if (flag  == "help")
        {
            print_CNV_usage();return 0;
        }
        else
        {
            cerr << "UnKnow argument -"<<flag<<endl;
            return 0;
        }
    }
    if  ((CNVpara->Ref).empty() )
    {
        cerr<< "lack argument for the must"<<endl ;
        return 0;
    }
    if (A*B)
    {
        cerr<<"\t-InDepth  and  -SoapList can't used at the same time"<<endl;
    }
    (CNVpara->OutPut)= add_Asuffix(CNVpara->OutPut);
    return 1 ;
}


bool merge_check(list<bkp_t>::iterator iter1, list<bkp_t>::iterator iter_curr, float thr, size_t Ncnt, ParaA_CNV * CNVpara )
{

    if (iter1->isN) return true;

    if (!(CNVpara->bmerge_zero) && ((iter_curr->depth < (CNVpara->NERELY_ZERO) && iter1->depth >(CNVpara-> NERELY_ZERO)) || (iter_curr->depth > (CNVpara->NERELY_ZERO) && iter1->depth < (CNVpara->NERELY_ZERO)))) return false;


    float depth = 0;
    if (iter_curr->win - Ncnt > 0) depth = iter_curr->depth / (iter_curr->win - Ncnt);

    float lval = depth > iter1->depth ? depth : iter1->depth;
    float rval = depth > iter1->depth ? iter1->depth : depth;

    float pval = 0;
    for (int j = 0; j <= (int)(rval * 10 /lval + 0.5); j++ )pval += (float)p_poisson(10, j);
    pval = (pval > 0.5) ? 2 * (1-pval) : 2 * pval;
    if (pval > thr) return true;
    return false;
}



int merge_bkp(list<bkp_t>::iterator biter,list<bkp_t> &bkp_list, float p_cutoff, ParaA_CNV * CNVpara)
{
    list<bkp_t>::iterator iter1, iter2, iter_curr;

    iter_curr = biter;
    iter_curr->depth = iter_curr->depth * iter_curr->win;
    iter1 = iter_curr;
    iter2 = ++iter1;
    iter2++;
    size_t curr_Ncnt = 0;

    //cout << "in the merge" << endl;
    for (; iter1 != bkp_list.end() && iter2 != bkp_list.end(); ) {
        if (!merge_check(iter1, iter_curr, p_cutoff, curr_Ncnt,CNVpara)) {
            if (iter_curr->win - curr_Ncnt > 0) iter_curr->depth /= (iter_curr->win - curr_Ncnt);
            else iter_curr->depth = 0;

            if (iter_curr->win < curr_Ncnt) {cerr << iter_curr->win << '\t' << curr_Ncnt << endl; exit(1);}
            curr_Ncnt = 0;
            iter_curr = iter1;
            iter_curr->depth = iter_curr->depth * iter_curr->win;
            if (iter1->isN) curr_Ncnt += iter1->win;

            iter1++;
            iter2++;

            if (!merge_check(iter1, iter_curr, p_cutoff, curr_Ncnt, CNVpara ) && iter1->win > (CNVpara->min_merge_win) && iter1 != bkp_list.end() && iter2 != bkp_list.end()) {
                if (iter_curr->win - curr_Ncnt > 0) iter_curr->depth /= (iter_curr->win - curr_Ncnt);
                else iter_curr->depth = 0;
                curr_Ncnt = 0;
                iter_curr = iter1;
                iter_curr->depth = iter_curr->depth * iter_curr->win;
                if (iter1->isN) curr_Ncnt += iter1->win;

                iter1++;
                iter2++;
                while (!merge_check(iter1, iter_curr, p_cutoff, curr_Ncnt,CNVpara) && iter1->win >(CNVpara->min_merge_win) && iter1 != bkp_list.end() && iter2 != bkp_list.end()) {
                    iter_curr->depth /= iter_curr->win;
                    iter_curr = iter1;
                    curr_Ncnt = 0;
                    iter_curr->depth = iter_curr->depth * iter_curr->win;

                    iter1++;
                    iter2++;
                }
            }

            while (iter1->pval < p_cutoff  && iter1->win <(CNVpara->min_merge_win) && iter1 != bkp_list.end() && iter2 != bkp_list.end()
                    && !iter1->isN && !iter_curr->isN) {
                iter_curr->depth += iter1->depth * iter1->win;
                iter_curr->win += iter1->win;
                if (iter1->isN) curr_Ncnt += iter1->win;

                bkp_list.erase(iter1);	
                iter1 = iter2;
                iter2++;
            }

            continue ;
        }

        iter_curr->depth += iter1->depth * iter1->win;
        iter_curr->win += iter1->win;
        if (iter1->isN) curr_Ncnt += iter1->win;

        bkp_list.erase(iter1);
        iter1 = iter2;
        iter2++;
    }

    iter_curr->depth /= (iter_curr->win - curr_Ncnt);	

    return 0;
}


void update_pval(list<bkp_t> &bkp_list)
{
    list<bkp_t>::iterator iter = bkp_list.begin();
    list<bkp_t>::iterator iter1, iter2; 

    while (iter != bkp_list.end()) {
        iter1 = iter;
        iter2 = ++iter;

        if (iter2->isN) {iter2->pval = 1; continue;}
        float lval = iter2->depth > iter1->depth ? iter2->depth : iter1->depth;
        float rval = iter2->depth > iter1->depth ? iter1->depth : iter2->depth;

        if (iter2 != bkp_list.end()) {
            float pval = 0;
            for (int j = 0; j <= (int)(rval * 10/ lval + 0.5); j++ ) pval += (float)p_poisson(10.0, j);
            //boost::math::poisson_distribution<> pdis(10);
            //pval = boost::math::cdf(pdis, (int)(rval * 10/ lval + 0.5));
            iter2->pval = (pval > 0.5) ? 2 * (1-pval) : 2 * pval;
        }
    }

    return;
}




int init_bkp(vector<record_t> &bpstat_vec, list<bkp_t> &bkp_list , ParaA_CNV * CNVpara ) 
{
    cout << "init bkp..." << endl;
    //cout << " bpstat_vec[0]" << (int)bpstat_vec[0] << endl; 

    size_t i = 1;
    size_t vec_sz = bpstat_vec.size();
    if (vec_sz ==0) return -1;

    bkp_t tmp_bkp;
    tmp_bkp.depth = bpstat_vec[0];
    tmp_bkp.win = 1;
    tmp_bkp.pos = i;

    size_t bkp_cnt = 0;
    list<bkp_t>::iterator iter_curr;
    int flag = 1;

    size_t n_mark = ((1U << (sizeof(record_t) << 3)) - 1);
    while ((++i) < vec_sz) {

        if (bpstat_vec[i] == n_mark || bpstat_vec[i - 1] == n_mark) {

            if (bpstat_vec[i -1] != n_mark) {
                bkp_list.push_back(tmp_bkp);
                bkp_cnt++;
                tmp_bkp.pos = i;
                //tmp_bkp.depth = 0;
                //tmp_bkp.isN = false;
            }

            tmp_bkp.isN = true;
            tmp_bkp.depth = 0;
            tmp_bkp.win = 1;
            if (bpstat_vec[i -1] == n_mark) tmp_bkp.win++;
            //if (i > 1) tmp_bkp.pos = i;
            ++i;
            while (i < vec_sz) { if (bpstat_vec[i] != n_mark) break; tmp_bkp.win++; i++;}
            tmp_bkp.depth = 0;
            bkp_list.push_back(tmp_bkp);
            bkp_cnt++;
            if (i == vec_sz) return 0;

            tmp_bkp.pos = i;
            tmp_bkp.win = 1;
            tmp_bkp.isN = false;
            tmp_bkp.depth = bpstat_vec[i];

            continue;
        }

        float curr_depth = bpstat_vec[i];
        if (curr_depth - tmp_bkp.depth < 0.01 && curr_depth - tmp_bkp.depth > -0.01) { tmp_bkp.win++;  continue;}
        else {
            bkp_list.push_back(tmp_bkp);
            bkp_cnt++;
            if (bkp_cnt >= 10 * 1024 * 1024) {
                flag = 0;
                //cout << "merging : " << bkp_list.size() << endl; 
                if (bkp_list.size() <= 10 * 1024 * 1024 + (bkp_cnt - 10 * 1024 * 1024)) iter_curr = bkp_list.begin();
                merge_bkp(iter_curr, bkp_list, CNVpara->p_cutoff, CNVpara);
                bkp_cnt = 0;
                iter_curr = bkp_list.end();
                iter_curr--;
                cout << "iter_curr\t" << iter_curr->depth << '\t' << iter_curr->win << endl;
            }

            tmp_bkp.pos = i;
            tmp_bkp.win = 1;
            tmp_bkp.isN = false;
            tmp_bkp.depth = curr_depth;
            tmp_bkp.pgc = 0;
            ///////////////
            float lval = curr_depth > tmp_bkp.depth ? curr_depth : tmp_bkp.depth;
            float rval = curr_depth > tmp_bkp.depth ? tmp_bkp.depth : curr_depth;
            double pval = 0;
            for (int j = 0; j <= (int)(rval * 10 / lval + 0.5); j++ )pval += (float)p_poisson(10.0, j);
            pval = (pval > 0.5) ? 2 * (1-pval) : 2 * pval;
            tmp_bkp.pval = pval;
        }
    }
    bkp_list.push_back(tmp_bkp);

    if (flag) iter_curr = bkp_list.begin();
    merge_bkp(iter_curr, bkp_list,CNVpara->p_cutoff,CNVpara);
    update_pval(bkp_list);

    return 0;
}




void merge_loop(vector<record_t> &bpstat_vec, list<bkp_t> &bkp_list , ParaA_CNV * CNVpara )
{
    init_bkp(bpstat_vec, bkp_list,  CNVpara );

    if (bkp_list.size() < 2) return;

    cout << "the size before merging: " << bkp_list.size() << endl;


    size_t ncycle = 15;
    float p_cutoff1 = CNVpara->p_cutoff;

    for (size_t j = 0; j < ncycle ; j++) {
        size_t above_cnt = 0;
        for (list<bkp_t>::iterator iter1 = bkp_list.begin(); iter1 != bkp_list.end(); ++iter1) {
            //if (i > 10)cout << "merging "<< i + 1 << ": "<< iter1->pos << '\t' << iter1->win << '\t' << iter1->depth << '\t' << iter1->pgc << '\t' << iter1->pval << endl;	
            if (iter1->pval > p_cutoff1) above_cnt++;

        }

        float above_rate = above_cnt / (float) bkp_list.size();
        //p_cutoff1 += 0.08 * above_rate;
        p_cutoff1 = (CNVpara->p_cutoff) + ((CNVpara->max_cutoff) - (CNVpara->p_cutoff)) * exp( 0 - above_rate);
        cout << "above rate : " << above_cnt / (float) bkp_list.size() << '\t' << above_cnt << '\t' << p_cutoff1 << endl;
        merge_bkp(bkp_list.begin(), bkp_list, p_cutoff1,CNVpara);
        cout << "the size after merging: " << bkp_list.size() << endl;
        update_pval(bkp_list);
    }
}


void  write_cnv(vector<list<bkp_t> > &bkp_list_vec ,   ParaA_CNV * CNVpara )
{
    ogzstream cnv_ofs(CNVpara->OutPut.c_str(), ofstream::out);
    if (!cnv_ofs.good()) {
        cerr << "can not open file " << CNVpara->OutPut << endl;
        return  ;
    }
    float global_mean_depth = (CNVpara->genome_depth_sum) / float(CNVpara->genome_bp_sum);
    if ((CNVpara->mean_depth_specified) > (CNVpara->NERELY_ZERO))
    {
        global_mean_depth = (CNVpara->mean_depth_specified);
    }
    cnv_ofs << "##genome leval  mean depth : " << global_mean_depth << endl;

    for (size_t i = 0; i < bkp_list_vec.size(); i++) {
        float mean_depth = (CNVpara->bglobal) ? global_mean_depth : (CNVpara->mean_depth_vec[i]);
        if (mean_depth <(CNVpara->NERELY_ZERO)) continue;

        //cnv_ofs << ">" << chr_vec[i] << endl;
        cnv_ofs << "#mean depth: " << (CNVpara->chr_vec)[i] << '\t' << setprecision(4) <<  (CNVpara->mean_depth_vec[i]) << endl;

        for (list<bkp_t>::iterator iter = bkp_list_vec[i].begin(); iter != bkp_list_vec[i].end(); iter++) {
            cnv_ofs << (CNVpara->chr_vec)[i] << '\t' << iter->pos << '\t'<< fixed << setprecision(2) << iter->win << '\t' << iter->depth << '\t' << (mean_depth ? (iter->depth / mean_depth) : 0) << '\t' << scientific  << setprecision(4) << iter->fval << '\t' << iter->isN << endl;
            cnv_ofs.unsetf(ios_base::scientific);
        }
    }
//    cnv_ofs << "cnv bases found : " << CNVpara->cnv_found_cnt << endl;
    cnv_ofs.close();
    return;
}


void calc_fval(vector<record_t> &bpstat_vec, list<bkp_t> &bkp_list, size_t &notN_cnt, ParaA_CNV * CNVpara )
{
    size_t count_sz = (1U << (sizeof(record_t) << 3)) - 1;
    vector<float> count_vec(count_sz, 0);

    for (size_t j = 0; j < bpstat_vec.size(); j++) {
        if (bpstat_vec[j] < count_sz) count_vec[bpstat_vec[j]]++;
        else count_vec[count_sz - 1]++;
    }
    //count_vec[0] =  count_vec[0] - (bpstat_vec.size() - notN_cnt);
    for (size_t j = 0; j < count_vec.size(); j++) {
        count_vec[j] /= (float)notN_cnt;
        if (j > 0) count_vec[j] += count_vec[j - 1];
        //cout << j << '\t' << count_vec[j] << endl;
    }

    for (list<bkp_t>::iterator iter = bkp_list.begin(); iter != bkp_list.end(); iter++) {
        //iter->fval = count_vec[size_t(iter->depth + 0.5)];
        if (iter->depth < (1U << (sizeof(record_t) << 3)) - 2) iter->fval = count_vec[size_t(iter->depth)] + (count_vec[size_t(iter->depth) + 1] - count_vec[size_t(iter->depth)]) * (iter->depth - size_t(iter->depth));
        else {
            iter->fval = count_vec[size_t(iter->depth)];
        }
        if (iter->fval > 0.5) iter->fval = 1 - iter->fval;
        iter->fval *= 2;
    }
}


void StatSoapDepth( vector <string> Files , map <string,vector <record_t> > & SiteDepth )
{
    int B=Files.size();
    for (int kk=0 ; kk<B ;  kk++ )
    {
        string soapfile=Files[kk];
        if(soapfile.length()>0)
        {
            cout<<"SoapFile\t"<<soapfile<<endl;
            igzstream  soap (soapfile.c_str(),ifstream::in);
            string id,seq,qua,ab,zw,chr;
            int hit ,length,start;
            if(!soap.good())
            {
                cerr<<"open soap error: "<<soapfile<<endl;
                return  ;
            }
            while(!soap.eof())
            {
                string  line ;
                getline(soap,line);
                int position ;
                if(line.length() > 0 )
                {
                    istringstream isone (line,istringstream::in);
                    isone>>id>>seq>>qua>>hit>>ab>>length>>zw>>chr>>start ;
                    map <string,vector <record_t> > :: iterator chr_it=SiteDepth.find(chr);
                    start-- ; // form 0 start count ;
                    for (int ii=0 ; ii<length ; ii++)
                    {
                        position = start+ii ;
                        (chr_it->second)[position]++;
                    }
                }
            }
            soap.close();
            soap.clear();
        }
    }
}

//int Var_SoapCNV_main(int argc, char *argv[])

int main(int argc, char *argv[])
{
    ParaA_CNV * CNVpara = new ParaA_CNV;
    if( parse_CNV_cmd(argc, argv, CNVpara )==0 )
    {
        delete  CNVpara ;
        return 0;
    }
    map <string,ubit64_t>  ChrLeng ;
    map <string,string>  Seq ;
    ReadFaSeq (CNVpara->Ref  , ChrLeng , Seq );
    map <string,vector<record_t> >  SiteDepth ;

    map<string,ubit64_t> ::iterator it ;
    for (it=ChrLeng.begin() ; it!=ChrLeng.end(); it++)
    {
        string chr_name=it->first;
        ubit64_t curr_chr_len=(it->second);
        vector<record_t> bpstat_vec(curr_chr_len, 0);
        SiteDepth.insert(map <string, vector<record_t> > :: value_type(chr_name, bpstat_vec));
    }

    map <string,ubit64_t> Chr_Sum_Depth ;

    if (!(CNVpara->InDepth).empty())
    {
        igzstream FileIN ((CNVpara->InDepth).c_str(),ifstream::in);
        if (FileIN.bad())
        {
            cerr<<"Bad InPut File"<<(CNVpara->InDepth)<<endl;
        }
        string chr ;
        ubit64_t Position=0,chr_SumDDD=0;
        record_t tmp_DD;
        while (!FileIN.eof())
        {
            string line ;
            getline(FileIN, line);
            if (line.length()<=0 )  { continue ; }
            istringstream isone (line,istringstream::in);
            if (line.find(">") != line.npos)
            {
                if(!chr.empty())
                {
                    Chr_Sum_Depth[chr]=chr_SumDDD ;
                }
                isone>>chr ;
                chr=replace_all(chr,">","");
                Position=0;
            }
            else
            {
                while(isone>>tmp_DD)
                {
                    chr_SumDDD+=tmp_DD ;
                    (SiteDepth[chr])[Position]=tmp_DD ;
                    Position++;
                }
            }
        }
        Chr_Sum_Depth[chr]=chr_SumDDD ;
        FileIN.close();
    }
    else if (!(CNVpara->SoapList).empty())
    {
        thread_group TRead ;
        vector <string> SoapFiles  ;
        int SumFile=ReadList (CNVpara->SoapList , SoapFiles);
        int Sub_File=(SumFile/(CNVpara->ncpu));
        int headtmp=(CNVpara->ncpu)+1;
        for (int jj=0 ; jj<headtmp; jj++)
        {
            vector <string> Now ;
            int Start= jj*Sub_File ;
            int  End =Start+Sub_File ;
            cout <<Start<<"\t"<<End<<endl ;
            for ( int key=Start ; (key<End && key<SumFile) ; key++ )
            {
                cout<<SoapFiles[key]<<endl;
                Now.push_back(SoapFiles[key]);
            }
            if (!Now.empty())
            {
                TRead.create_thread(bind(StatSoapDepth , Now ,boost::ref(SiteDepth) ));
            }
        }
        TRead.join_all();

        if  ((CNVpara->OutPutDepth).empty())
        {
            map <string,vector<record_t> > :: iterator X ;
            for (X=SiteDepth.begin(); X!=SiteDepth.end(); X++)
            {
                string chr_name=X->first ;
                ubit64_t chr_sum_length=ChrLeng[chr_name];
                for (long ii=0 ; ii<chr_sum_length ; ii++)
                {
                    Chr_Sum_Depth[chr_name]+=((X->second)[ii]);
                }
            }
        }
        else
        {
            (CNVpara->OutPutDepth)=add_Asuffix(CNVpara->OutPutDepth);
            ogzstream OUTFileDepth ((CNVpara->OutPutDepth).c_str());
            if (OUTFileDepth.bad())
            {
                cerr<<"Bad Open File"<<(CNVpara->OutPutDepth)<<endl;
            }
            map <string,vector<record_t> > :: iterator X ;
            for (X=SiteDepth.begin(); X!=SiteDepth.end(); X++)
            {
                string chr_name=X->first ;
                OUTFileDepth<<">"<<chr_name<<endl;
                ubit64_t chr_sum_length=ChrLeng[chr_name];
                long bin_count=long(chr_sum_length/500000);
                for (long ii=0 ; ii<bin_count ; ii++)
                {
                    ubit64_t  Start=ii*500000  ;
                    ubit64_t  End=Start+500000 ;
                    OUTFileDepth<<(X->second)[Start];
                    Chr_Sum_Depth[chr_name]+=((X->second)[Start]);
                    for (ubit64_t jj=Start+1 ; jj<End ; jj++)
                    {
                        record_t  DepthAtThisSite=(X->second)[jj];
                        OUTFileDepth<<" "<<DepthAtThisSite;
                        Chr_Sum_Depth[chr_name]+=DepthAtThisSite;
                    }
                    OUTFileDepth<<endl;
                }
                ubit64_t  Start=bin_count*500000;
                if (Start<chr_sum_length)
                {
                    OUTFileDepth<<(X->second)[Start];
                    Chr_Sum_Depth[chr_name]+=((X->second)[Start]);
                    for (ubit64_t jj=Start+1 ; jj<chr_sum_length ; jj++)
                    {
                        record_t  DepthAtThisSite=(X->second)[jj] ;
                        OUTFileDepth<<" "<<DepthAtThisSite;
                        Chr_Sum_Depth[chr_name]+=DepthAtThisSite;
                    }
                    OUTFileDepth<<endl;
                }
            }
            OUTFileDepth.close();
        }
    }

    map<string,ubit64_t> chr_N_Length ;
    map<string,string > ::iterator itStr ;
    int chr_cnt=0;
    for (itStr=Seq.begin() ; itStr!=Seq.end(); itStr++ )
    {
        string chr_name=itStr->first;
        string &Ref=(itStr->second);
        size_t N_tail_position = 0 ;
        size_t N_head_position=Ref.find_first_of( "Nn", 0 );
        ubit64_t N_chr_length= 0;
        while( N_head_position != string::npos)
        {
            N_tail_position=Ref.find_first_of("AaTtCcGg",N_head_position+1);
            if (N_tail_position!= string::npos )
            {
                for (size_t ii=N_head_position+1 ; ii<=N_tail_position ; ii++)
                {
                    (SiteDepth[chr_name])[ii] = ((1U << (sizeof(record_t) << 3)) - 1) ;
                }
                N_chr_length+=(N_tail_position-N_head_position);
            }
            else
            {
                ubit64_t chr_legnth=Ref.length();
                for (size_t ii=N_head_position+1 ; ii<=chr_legnth ;ii++ )
                {
                    (SiteDepth[chr_name])[ii] = ((1U << (sizeof(record_t) << 3)) - 1) ;
                }
                N_chr_length+=chr_legnth-N_head_position;
                break ;
            }
            N_head_position=Ref.find_first_of("Nn",N_tail_position);
        }
        chr_N_Length[chr_name]=N_chr_length;
        chr_cnt++;
    }

    ubit64_t ALLSumDepth=0, ALLSumSite=0;
    (CNVpara->mean_depth_vec).resize(chr_cnt,0.0);
    vector <ubit64_t> EffLeng (chr_cnt ,0);
    int i=0 ;
    for (it=ChrLeng.begin() ; it!=ChrLeng.end(); it++)
    {
        string chr_name=it->first;
        ubit64_t curr_chr_len=(it->second) ;
        ubit64_t curr_chr_N_len=chr_N_Length[chr_name];
        ubit64_t bp_count=curr_chr_len-curr_chr_N_len;
        ubit64_t Depth_SSS= Chr_Sum_Depth[chr_name];
        (CNVpara->mean_depth_vec)[i]= bp_count ? (Depth_SSS / (float)bp_count) : 0;
        CNVpara->genome_depth_sum+=Depth_SSS;
        CNVpara->genome_bp_sum+=bp_count;
        EffLeng[i]=bp_count;
        i++;
    }
    vector<list<bkp_t> > bkp_list_vec;
    bkp_list_vec.resize(chr_cnt, list<bkp_t>());
    (CNVpara->chr_vec).resize(chr_cnt,string());
    i=0;
    for (it=ChrLeng.begin() ; it!=ChrLeng.end(); it++ )
    {        
        string chr_name=it->first;
        list<bkp_t> bkp_list;
        vector<record_t> &bpstat_vec = (SiteDepth[chr_name]) ;
        merge_loop(bpstat_vec, bkp_list , CNVpara ) ;
        size_t  notN_cnt=size_t (EffLeng[i]) ;
        calc_fval(bpstat_vec, bkp_list,notN_cnt  , CNVpara ); 
        bkp_list_vec[i].assign(bkp_list.begin(), bkp_list.end());
        (CNVpara->chr_vec)[i] = chr_name;
        i++ ;
    }

    write_cnv(bkp_list_vec , CNVpara ) ;
    delete CNVpara ;
    return 0;
}

#endif 
//////// swimming in the sky and flying in the sea ////////////
