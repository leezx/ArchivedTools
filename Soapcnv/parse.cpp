#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <exception>
#include <ctime>
#include <stdlib.h>
#include "parse.h"
#include </ifs4/BC_RD/USER/lizhixin/Soapcnv/gzstream.h>


using namespace std;

//extern int indel_offset;
extern int mismatch_offset;
long indel_reads_cnt = 0;
long indel_discard_cnt = 0;
const int KEY_MAX_LEN = 1024;
//read chromosome information from a file if provided
int read_chrinfo(char *file_name, map<string, long> &chr_count)
{
	cout << "in the read_chrinfo" << endl;

	ifstream ifs(file_name, ifstream::in);
	if(!ifs.good()) {
		cout << "open file " << file_name << " error" << endl;
		exit(1);
	}

	while(!ifs.eof()) {
		string nr;
		int count;
		ifs >> nr >> count;
		if (nr.length() == 0)continue;

		chr_count[nr] = count;
	}

	return 0;
}

int write_chrinfo(char *output_file, vector<int> &chr_count)
{
	ofstream ofs ( output_file, ifstream::out );

	if (!ofs.good()) {
		cout << "can not open the output file" << endl;
		exit(1);
	}

	for(size_t i = 0; i < chr_count.size(); i++) {
		ofs << i + 1 << '\t' << chr_count[i] << endl; 
	}

	ofs.close();

	return 0;
}

//resource allocation
int alloc_rc(map<string, vector<record_t> > &bpstat_map, map<string, long> &chr_count)
{
	for (map<string, long>::iterator  iter = chr_count.begin(); iter != chr_count.end(); iter++) {

		//	cout << iter->first << '\t' << iter->second << endl;
		bpstat_map.insert(pair<string, vector<record_t> >(iter->first, vector<record_t>()));
		bpstat_map[iter->first].resize(iter->second, 0);

	}

	return 0;
}
//count the bases of every chromosome from the reference file if the chromosome information is not given
int base_count(const char *file_name, map<string, long> &chr_count)
{
	ifstream ifs ( file_name, ifstream::in );
	if (!ifs.good()) {
		cout << "can not open the reference file" << endl;
		exit(1);
	}

	string tmpstr;
	getline(ifs, tmpstr);
	while (tmpstr.find(">") == tmpstr.npos && !ifs.eof()) getline(ifs, tmpstr);

	while (!ifs.eof()) {
		istringstream iss(tmpstr.substr(tmpstr.find(">") + 1), istringstream::in);
		string chr;
		iss >> chr;
		//cout << "handling chr : " << chr << endl; 

		long chr_bp_count = 0;
		while (!ifs.eof()) {
			getline(ifs, tmpstr);
			if (tmpstr.find(">") != tmpstr.npos) break;
			chr_bp_count += tmpstr.length();
		}
		if (chr.length() == 0) continue;

		chr_count.insert(pair<string, long>(chr, chr_bp_count));
	}

	ifs.close();

	return 0;

}
//parse every line of the soap result


int soap_t::parse_linegz( igzstream & ifs)
{
	string ss;

	getline(ifs, ss);
	if (ss.length() == 0) return 0;
	
	//int ntab = 0;
	//ntab = count(ss.begin(), ss.end(), '\t');
	istringstream iss (ss,istringstream::in);
	iss >> id >> seq >> qual >> nhits >> file
		>> read_len >> fr >> chr >> pos >> mm_indel;

	//if (pos == 12164278)  {cout << ss << endl;print_soap();}
	
	size_t found = mm_indel.find('M');
	if (found != mm_indel.npos) {
		msid = mm_indel;
		found = mm_indel.find('I');
		//while (found >= 0 && (mm_indel[found] == 'I' || isdigit(mm_indel[found])) ) found--;
		//found++;
		if (found != mm_indel.npos) {
			indel_len = mm_indel[found - 1] - '0';

			mm_indel = string("100");
			mm_indel[2] += indel_len;
		}

		found = mm_indel.find('D');
		if (found != mm_indel.npos) {
			indel_len = mm_indel[found - 1] - '0';

			mm_indel = string("200");
			mm_indel[2] += indel_len;
		}

		found = msid.find('S');
		if (found != msid.npos) {
			int tmp = atoi(msid.c_str());
			indel_pos = tmp + atoi(msid.substr(found + 1).c_str());
		}

		indel_pos = atoi(msid.c_str());

		iss >> minfo;
	}
	////////////////
	else { //added on 06.30
		if ( mm_indel.length() == 3 && isdigit(mm_indel[2])) {
			iss >> indel_pos;
			if (indel_pos >= read_len)return 0;
		}
		else {
			for (int i = 0; i < mm_indel[0] - '0'; i++) {
				string str1;
				iss >> str1;
				mminfo.push_back(str1);
			}
		}

		iss >> msid >> minfo;

	} //added on 06.30

	calc_trim_len();

	if (mm_indel.length() == 3) {
		indel_len = (mm_indel[1] - '0') * 10 + mm_indel[2] - '0';
		indel_pos -= front_trim_len; 

		if (mm_indel[0] == '1' )
		{	
			size_t d_pos = minfo.find("D");
			if (d_pos == minfo.npos)return 0;

			indel_str = minfo.substr(d_pos + 1 , indel_len);
		}
		else {
			if (indel_pos  >= seq.length())return 0;
			indel_str = seq.substr(indel_pos, indel_len);
		}
	}
	else indel_len = 0;

	return 0;
}


int soap_t::parse_line(ifstream &ifs)
{
	string ss;

	getline(ifs, ss);
	if (ss.length() == 0) return 0;
	
	//int ntab = 0;
	//ntab = count(ss.begin(), ss.end(), '\t');
	istringstream iss (ss,istringstream::in);
	iss >> id >> seq >> qual >> nhits >> file
		>> read_len >> fr >> chr >> pos >> mm_indel;

	//if (pos == 12164278)  {cout << ss << endl;print_soap();}
	
	size_t found = mm_indel.find('M');
	if (found != mm_indel.npos) {
		msid = mm_indel;
		found = mm_indel.find('I');
		//while (found >= 0 && (mm_indel[found] == 'I' || isdigit(mm_indel[found])) ) found--;
		//found++;
		if (found != mm_indel.npos) {
			indel_len = mm_indel[found - 1] - '0';

			mm_indel = string("100");
			mm_indel[2] += indel_len;
		}

		found = mm_indel.find('D');
		if (found != mm_indel.npos) {
			indel_len = mm_indel[found - 1] - '0';

			mm_indel = string("200");
			mm_indel[2] += indel_len;
		}

		found = msid.find('S');
		if (found != msid.npos) {
			int tmp = atoi(msid.c_str());
			indel_pos = tmp + atoi(msid.substr(found + 1).c_str());
		}

		indel_pos = atoi(msid.c_str());

		iss >> minfo;
	}
	////////////////
	else { //added on 06.30
		if ( mm_indel.length() == 3 && isdigit(mm_indel[2])) {
			iss >> indel_pos;
			if (indel_pos >= read_len)return 0;
		}
		else {
			for (int i = 0; i < mm_indel[0] - '0'; i++) {
				string str1;
				iss >> str1;
				mminfo.push_back(str1);
			}
		}

		iss >> msid >> minfo;

	} //added on 06.30

	calc_trim_len();

	if (mm_indel.length() == 3) {
		indel_len = (mm_indel[1] - '0') * 10 + mm_indel[2] - '0';
		indel_pos -= front_trim_len; 

		if (mm_indel[0] == '1' )
		{	
			size_t d_pos = minfo.find("D");
			if (d_pos == minfo.npos)return 0;

			indel_str = minfo.substr(d_pos + 1 , indel_len);
		}
		else {
			if (indel_pos  >= seq.length())return 0;
			indel_str = seq.substr(indel_pos, indel_len);
		}
	}
	else indel_len = 0;

	return 0;
}
void soap_t::print_soap()const
{
	cout << "print the read info" << endl;
	cout  << id << '\t' << seq << '\t' << qual << '\t' << nhits <<'\t' << file << '\t' << read_len << '\t' << fr << '\t' << chr << '\t' << pos << '\t' << mm_indel << endl;

	if ( mm_indel.length() > 1)cout << indel_pos << endl;
	else
		for (int i = 0; i < mm_indel[0] - '0'; i++)
			cout << mminfo[i] << '\t';

	cout << msid << '\t' << minfo << endl;

	return;
}
//if read has been trimmed, must get the trimmed length 
int soap_t::calc_trim_len()
{
	string ss = msid;
	const char  *cstr = ss.c_str();  
	size_t s_pos = ss.find("S");
	const char *p ;
	trim_len = front_trim_len = 0;

	p = cstr + s_pos;
	if (s_pos != ss.npos) {
		while (isdigit(*(--p))){}

		trim_len =  atoi(++p);
		if (p == cstr) front_trim_len = trim_len;
	}
	else return 0;

	p = cstr + s_pos + 1; 
	s_pos = ss.substr(s_pos + 1).find("S");

	p += s_pos;
	if (s_pos != ss.npos)
		if (s_pos != ss.npos) {
			while (isdigit(*(--p))){}

			trim_len += atoi(++p);
		}

	return 0;
}
//statistics of hits(or depth) of every base-pair
int soap_t::hits_stat(map<string, vector<record_t> > &bpstat_map )const
{	
	if (chr.length() == 0) return 1;

	vector<record_t> &bp_vec = bpstat_map[chr];

	size_t read_len1 = read_len;
	//if (indel_len > 0 && mm_indel[0] == '2')read_len1 = read_len - indel_len;
	
	if (pos + read_len1 > bp_vec.size()) {cout << "wrong size! " << chr << '\t' << pos << '\t' << read_len1 << '\t' <<  bp_vec.size() << endl; return -1;}

	for (size_t i = 0; i  < read_len1; i++) {

		if (bp_vec[pos + i - 1] < ((1U << (sizeof(record_t) << 3)) - 2)) bp_vec[pos + i - 1]++;
		else {
			//cout << "count of some base is larger than 255!!" << endl;
		}

	}

	return 0;
}


//check if the flanking bases have mismatchs
int ismismatch(const char *minfo, int indel_pos, int offset)
{
	const char *p = minfo;
	const char *p1;

	int cnt = 0;
	while (*p) {
		p1 = p;
		while (*p && (!isalpha(*p) ))p++;

		if (*p ) {
			cnt += atoi(p1) + 1;
			if (*p == 'D'){p++;cnt--; continue;}

			p++;
			if (cnt - indel_pos <= offset && cnt - indel_pos >= -offset) return 1;
		}
		if(*p == 'D') {p++;continue;}
	}

	return 0;
}




