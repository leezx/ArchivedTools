CC = /usr/bin/g++
CFLAGS = -Wall -g -c -I/usr/include/boost/  -static 
LFLAGS = -lpthread -L /ifs4/BC_PUB/biosoft/pipeline/newblc/01.Usr/lib/ -lgzstream -L /ifs5/BC_COM_P3/AD-hewmBin/01.Soft/Tools/iTools_Code/src/include/zlib/ -L /ifs5/BC_COM_P3/AD-hewmBin/01.Soft/Tools/iTools_Code/src/include/gzstream -lz  -static  
SOAPcnv: parse.o calc_cnv.o math_fun.o 
	$(CC) $^ -o $@ $(LFLAGS)
SOAPcnvT: parse.o calc_cnv.o math_fun.o 
	$(CC) $^ -o $@ $(LFLAGS)
parse.o: parse.cpp parse.h	
	$(CC) $(CFLAGS) $<
math_fun.o: math_fun.cpp math_fun.h
	$(CC) $(CFLAGS) $<
calc_cnv.o: calc_cnv.cpp calc_cnv.h threadmgr.h
	$(CC) $(CFLAGS) $<
clean: 
	rm parse.o  math_fun.o calc_cnv.o 
