
#ifndef FQ_cutIndex_H_
#define FQ_cutIndex_H_ 

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <list>
#include <map>
#include <cstdlib>
#include <algorithm> 

#include "../include/gzstream/gzstream.h" 
#include "../ALL/comm.h"
#include "../ALL/DataClass.h"

using namespace std;

int  print_usage_B01 ()
{
	cout <<""
		"\n"
		"Usage:cutIndex  -InFq In.fq\n"
		"\n"
		"\t\t-InFq        <str>   File name of InFq Input\n"
		"\t\t-help                show this help\n"
		"\n";
	return 1;
}
//
int parse_cmd_B01(int argc, char **argv , ParaClass * para )
{
	if (argc <=2  ) {print_usage_B01();return 0;}

	int err_flag = 0;
	for(int i = 1; i < argc || err_flag; i++)
	{
		if(argv[i][0] != '-')
		{
			cerr << "command option error! please check." << endl;
			return 0;
		}
		string flag=argv[i] ;
		flag=replace_all(flag,"-","");

		if (flag  == "InFq" )
		{
			if(i + 1 == argc) { LogLackArg( flag ) ; return 0;}
			i++;
			para->InPut1=argv[i];
		}
		else
		{
			cerr << "UnKnow argument -"<<flag<<endl;
			return 0;
		}
	}

	if ( (para->InPut1).empty() )
	{
		cerr<< "-InFq lack argument for the must"<<endl;
		return 0;
	}
	para->InInt1--;
	return 1;
}

vector<string> split1(string& str, const char* c)
{
	char *cstr=0;
	char *p=0;
	vector<string> res;
	cstr = new char[str.size() + 1];
	strcpy(cstr, str.c_str());
	p = strtok(cstr, c);
	while (p != NULL)
	{
		res.push_back(p);
		p = strtok(NULL, c);
	}
	delete cstr;
	delete p;
	return res;
}

void split(string& s, string& delim, vector<string> &ret)
{
	size_t last = 0;
	size_t index = s.find_first_of(delim, last);
	while (index != string::npos)
	{
		ret.push_back(s.substr(last, index - last));
		last = index + 1;
		index = s.find_first_of(delim, last);
	}
	if (index - last>0)
	{
		ret.push_back(s.substr(last, index - last));
	}
}

string Int_to_String(int n)
{
	ostringstream stream;
	stream<<n; 
	return stream.str();
}

int main(int argc, char **argv)
{
	ParaClass * para = new ParaClass;
	para->InInt2=-1;
	para->InInt1=5;
	int Flag_para=parse_cmd_B01(argc, argv ,para ) ;
	if ( Flag_para ==0)
	{
		delete  para ; 
		return 1;
	}

	igzstream INFQ ((para->InPut1).c_str(),ifstream::in); // ifstream  + gz
	ifstream READS_BC ("reads_barcode.txt");
	ogzstream OUT_1 ("split_read.1.fq.gz");

	if(!INFQ.good())
	{
		cerr << "open IN File error: "<<para->InPut1<<endl;
		return 1;
	}
	if(!OUT_1.good())
	{
		cerr << "open OUT File error: "<<"barcode1.fasta"<<endl;
		return 1;
	} 
	if(!READS_BC.good())
	{
		cerr << "open READS_BC File error "<<endl;
		return 1;
	} 

	igzstream IN_1 ((para->InPut1).c_str(),ifstream::in); // ifstream  + gz 
	if(!IN_1.good())
	{
		cerr << "open IN File error: "<<para->InPut1<<endl;
		return 1;
	}

	string ID_1 ,seq_1,temp_1,Quly_1, new_seq_name ;
	int seq_len;
	string barcode1, barcode2, UMI, final_name, total_line;
	map<string, int> barcode_count;
	int count = 1;

	while(!IN_1.eof() && !READS_BC.eof())
	{
		getline(IN_1,ID_1);
		if (ID_1.empty())
		{
			continue ;
		}
		getline(IN_1,seq_1);
		getline(IN_1,temp_1);
		getline(IN_1,Quly_1);
		
		getline(READS_BC,total_line);
		string split_1 =  " ";
		string split_2 = "#";
		vector<string> tmp_1;
		vector<string> tmp_2;
		split(total_line, split_1, tmp_1);
		split(tmp_1[0], split_2, tmp_2);
		if(tmp_1.size()<2)
		{
			cout << tmp_1[0] << "tmp_1.size()<2" << endl;
			continue;
		}
		if(tmp_2.size()<2)
		{
			cout << tmp_2[0] << "tmp_2.size()<2" << endl;
			continue;
		}
		string barcode_name = tmp_1[1];
		string barcode_seq_name = tmp_2[0];
		string UMI = tmp_2[1];
		
		if (ID_1.substr(1, ID_1.length() - 3) != barcode_seq_name)
		{
			getline(IN_1,ID_1);
			getline(IN_1,seq_1);
			getline(IN_1,temp_1);
			getline(IN_1,Quly_1);
		}
		
		if (!barcode_count.count(barcode_name) > 0)
		{
			barcode_count[barcode_name] = count;
			count = count+1;
		}
		
		ID_1.insert(ID_1.length() - 2, "#"+barcode_name);
		OUT_1 << ID_1 + "\t" + "UMI:" + UMI + "\t" + Int_to_String(barcode_count[barcode_name]) + "\t1" << "\n" << seq_1 << "\n" << temp_1 << "\n" << Quly_1 << endl;
			
	}
	delete para ;
	INFQ.close();
	READS_BC.close();
	OUT_1.close();
	return 1 ;
}

#endif  // FQ_cutIndex_H_

