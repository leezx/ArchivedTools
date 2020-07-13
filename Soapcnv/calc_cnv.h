#ifndef _CALC_CNV_H_ 
#define _CALC_CNV_H_ 

#include <string>
#include <vector>
#include <list>
#include <map>
#include "threadmgr.h"

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

class stat_thread_t: public thread_base
{
    private:
        size_t index;               ///< the field is used for distinguish between threads 

    public:

        map<string, vector<record_t> > &bpstat_map;     ///< store the statistics information of indels of every base-pair
        vector<string> &file_list;                           ///< list of files to get statistics information

        stat_thread_t(map<string, vector<record_t> > &bpstat_vec1, vector<string> &file_list1): bpstat_map(bpstat_vec1), file_list(file_list1) {}

        void set_index(size_t i) {index = i;}

        int soap_file_stat(const char *file_name, map<string, vector<record_t> > &bpstat_map);      

        int depthbin_file_stat(const char *file_name, map<string, vector<record_t> > &bpstat_map);      

        //int alloc_rc();

        virtual void* task();                      

        virtual ~stat_thread_t(){}

};


class stat_t
{
    private:
        //map<string, vector<record_t> > bpstat_map;         ///< store the statistics information of indels of every base-pair
        map<string, long> chr_count;            //store the information about length of chromosomes 
        vector<string> file_list; 

        //int base_count(const char *file_name, map<string, long> &chr_count);  //get the length of chromosomes from the reference 

        //int read_file_list(vector<string> &file_list, char *file_list_file)
        int read_file_list(vector<string> &file_list, const char *file_list_file); //get the list of soap result files

        //int read_chrinfo(const char *file_name, map<string, long> &chr_count);                ///< get length of chromosomes from a given file

        //int alloc_rc(map<string, vector<record_t> > &bpstat_map, map<string, long> &chr_count);                                         ///< allocate memory resource


    public:
        int run_stat();                                         ///< statistics module entry
};

class calc_cnv_thread_t: public thread_base
{
    //list<bkp_t> bkp_list;
    float p_init_cutoff;
    float p_final_cutoff;
    //map<string, vector<record_t> > &bpstat_map;
    //vector<string> &chr_vec;
    //vector<string> &seq_vec;
    size_t index;


    int merge_bkp(list<bkp_t>::iterator biter,list<bkp_t> &bkp_list, float p_cutoff);
    void update_pval(list<bkp_t> &bkp_list);

    void update_pval(list<bkp_t> &bkp_list, vector<record_t> &bpstat_vec, string &seq);

    int init_bkp(vector<record_t> &bpstat_vec, list<bkp_t> &bkp_list); 


    public:
    void merge_loop(vector<record_t> &bpstat_vec, list<bkp_t> &bkp_list);

    bool merge_check(list<bkp_t>::iterator iter1, list<bkp_t>::iterator iter_curr, float thr, size_t Ncnt);

    void calc_fval(vector<record_t> &bpstat_vec, list<bkp_t> &bkp_list, size_t &notN_cnt);

    virtual void* task();

    public:
    //calc_cnv_thread_t(map<string, vector<record_t> > &bpstat_vec1, vector<string> &chr_vec1,
    //      vector<string> &seq_vec1):bpstat_map(bpstat_vec1),chr_vec1(chr_vec), seq_vec1(seq_vec){}
    calc_cnv_thread_t() {}

    void set_index(size_t i) {index = i;}
    virtual ~calc_cnv_thread_t(){}

};

float get_mean_depth(const vector<record_t> &bpstat_vec);

float get_mean_depth(vector<record_t> &bpstat_vec, string &seq, size_t &bp_count);

class calc_cnv_t
{
    private:
        //vector<string> chr_vec;
        //vector<string> seq_vec;
        //map<string, vector<record_t> > &bpstat_map;

        //int read_chr(ifstream &ifs, map<string, vector<record_t> > &bpstat_map, string &chr, string &seq)

        int read_chr(const char *ref_file, map<string, string> &chr_map);
        int read_chr(char *ref_file,  vector<string> &chr_vec, vector<string> &seq_vec);
        //int read_chr(char *ref_file, vector<string> &chr_vec, vector<string> &seq_vec);
        int depthsingle_process(const char*, const char*);
        int depthbin_process(const char *file_name, const char *ref_file);
        int soap_process();

        void write_cnv(vector<list<bkp_t> > &bkp_list);

    public:
        calc_cnv_t(){}
        int run_calc_cnv();
        void write_depth_distr();
};

class eval_t
{
    private:
        vector<rc_bkp_t> &rc_bkp_vec;
        list<bkp_t> bkp_list;

        int read_rc(char *file, vector<rc_bkp_t> &rc_bkp_vec);

        int algo_eval(vector<rc_bkp_t> &rc_bkp_vec, list<bkp_t> &bkp_list, float mean_depth);

    public:

        void run_eval();
};


int write_bkp_list(char *list_file, list<bkp_t> &bkp_list, float mean_depth);

int read_bkp_list(char *list_file, list<bkp_t> &bkp_list, float &mean_depth);

#endif


