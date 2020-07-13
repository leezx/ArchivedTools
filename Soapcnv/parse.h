#ifndef _PARSE_H_
#define _PARSE_H_

#include <iostream>
#include <vector>
#include <string>
#include <map>
#include </ifs4/BC_RD/USER/lizhixin/Soapcnv/gzstream.h>


using namespace std;

typedef unsigned short record_t;
class soap_t
{
	private:
		string id;      			//index
		string seq;				//sequence string
		string qual;			//quality string
		size_t nhits;				//the times of success alignments
		char file;				//file query
		size_t read_len;			//length of the read
		char fr;				//forward or reward
		string chr;				//the chromosome NO.
		unsigned long pos;				//the start position in chromosome
		int insize;
		string mm_indel;		//number of mismatchs in seed
		size_t indel_pos;			//indel position
		vector<string> mminfo;  //mismatch detailed infomation
		string msid;			//matched length with gap torerance
		string minfo;			//detailed infomation of matching
		string indel_str;
		unsigned short trim_len;
		unsigned short front_trim_len;
		unsigned short indel_len;
	public:
		
		soap_t():nhits(0), read_len(0), pos(0), insize(0), indel_pos(0), trim_len(0), front_trim_len(0), indel_len(0) {}
		
		unsigned long get_pos() const {return pos;}

		size_t get_read_len()const {return read_len;}

		size_t get_indel_pos()const {return indel_pos;}

		string get_seq()const {return seq;}

		string get_chr()const {return chr;}

		string get_mm_indel()const {return mm_indel;}

		void set_insize(int size) {insize = size;}

		int hits_stat(map<string, vector<record_t> > &bpstat_map ) const;
        
        int parse_linegz(igzstream &ifs);
		int parse_line(ifstream &ifs);

		int calc_trim_len();

		void print_soap() const;
};

int base_count(const char *file_name, map<string, long> &chr_count);
int read_chrinfo(char *file_name, map<string,long> &chr_count);
int write_chrinfo(char *file_name, vector<int> &chr_count);

int alloc_rc(map<string, vector<record_t> > &bpstat_map, map<string, long> &chr_count);

class depth_t
{
    
};


#endif

