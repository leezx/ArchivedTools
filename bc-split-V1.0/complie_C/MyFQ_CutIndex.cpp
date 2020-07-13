
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
		// else if (flag  ==  "OutFq")
		// {
			// if(i + 1 == argc) { LogLackArg( flag ) ; return 0;}
			// i++;
			// para->OutPut1=argv[i];
		// }
		// else if (flag  ==  "StartCut")
		// {
			// if(i + 1 == argc) { LogLackArg( flag ) ; return 0;}
			// i++;
			// para->InInt1=atoi(argv[i]);
		// }
		// else if (flag  ==  "LengthCut")
		// {
			// if(i + 1 == argc) { LogLackArg( flag ) ; return 0;}
			// i++;
			// para->InInt2=atoi(argv[i]);
		// }
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
	// (para->OutPut1)=add_Asuffix(para->OutPut1);
	para->InInt1--;
	return 1;
}




///programme entry
///////// swimming in the sky and flying in the sea ////////////
int main(int argc, char **argv)
//int FQ_IndexCut_main(int argc, char **argv)
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
	// ogzstream OUT_1 ((para->OutPut1).c_str());
	ofstream OUT_1 ("barcode1.fasta");
	ofstream OUT_2 ("barcode2.fasta");
	// ofstream OUT_3 ("UMI.fasta");

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
	if(!OUT_2.good())
	{
		cerr << "open OUT File error: "<<"barcode2.fasta"<<endl;
		return 1;
	} 
	// if(!OUT_3.good())
	// {
		// cerr << "open OUT File error: "<<"UMI.fasta"<<endl;
		// return 1;
	// } 

	// int maxReadLeng=0 ;
	// int BB=0;
	// while( (!INFQ.eof()) && (BB< 16888 ))
	// {
		// string  line ;
		// getline(INFQ,line);
		// getline(INFQ,line);
		// int tmp=line.length();
		// if (tmp> maxReadLeng)
		// {
			// maxReadLeng=tmp;
		// }
		// getline(INFQ,line);
		// getline(INFQ,line);
		// BB++;
	// }
	// INFQ.close();

	// if ((para->InInt2)<1)
	// {
		// (para->InInt2)=maxReadLeng-(para->InInt1);
	// }
	// else if ((para->InInt2) > maxReadLeng )
	// {
		// cerr<<"warning: cut Length "<<(para->InInt2)<<"\tbiger than the Read length "<<maxReadLeng<<"\n";
	// }

	igzstream IN_1 ((para->InPut1).c_str(),ifstream::in); // ifstream  + gz 
	if(!IN_1.good())
	{
		cerr << "open IN File error: "<<para->InPut1<<endl;
		return 1;
	}

	string ID_1 ,seq_1,temp_1,Quly_1, new_seq_name ;
	int seq_len;
	string barcode1, barcode2, UMI, final_name;

	while(!IN_1.eof())
	{
		getline(IN_1,ID_1);
		if (ID_1.empty())
		{
			continue ;
		}
		getline(IN_1,seq_1);
		getline(IN_1,temp_1);
		getline(IN_1,Quly_1);
		new_seq_name = ">"+ID_1.substr(1);
		seq_len = new_seq_name.length();
		string barcode1 , barcode2, UMI ;
		// barcode1 = seq_1.substr(para->InInt1,(para->InInt2)); 
		barcode1 = seq_1.substr(0, 10); 
		barcode2 = seq_1.substr(28, 10); 
		UMI = seq_1.substr(43, 10); 
		final_name = new_seq_name.substr(0,seq_len-2)+"#"+UMI;
		// B = Quly_1.substr(para->InInt1,(para->InInt2));
		
		// OUT_1<<ID_1<<"\n"<<barcode1<<"\n"<<temp_1<<"\n"<<B<<endl;
		OUT_1<<final_name<<"\n"<<barcode1<<endl;
		OUT_2<<final_name<<"\n"<<barcode2<<endl;
		// OUT_3<<final_name<<"\n"<<UMI<<endl;
	}
	delete para ;
	return 1 ;
}

#endif  // FQ_cutIndex_H_


///////// swimming in the sky and flying in the sea ////////////
