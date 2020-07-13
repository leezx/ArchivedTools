    2  cd /bioapp/
    4  apt-get update
    5  apt-get install make gcc zlib1g-dev -y
    6  rsync -avz rsync://perl5.git.perl.org/APC/perl-5.8.x .
    8  cd perl-5.8.x/
   10  sh Configure -de -Dprefix=/opt/ -Dusethreads
   11  make
   12  make install
   13  /opt/perl
   14  /opt/bin/perl -v
   15  perl -v
   16  which perl
   17  cd /usr/bin/
   18  mv perl perl-5.18
   19  ln -s /opt/bin/perl ./
   20  perl -v
   21  perl -MCPAN -e shell
   24  vi ~/.bashrc 
   25  source ~/.bashrc
   29  perl -MCPAN -e shell
   30  cpan
   31  perl BioPerl::test
   33  perl -e "print @INC"
   34  perldoc Bio::SeqIO
   35  cpan
   36  perl Bio::Perl
   37  cd /var/data/
   39  cd wgs/
   41  cd annotation_tmp/
   43  rm -r BioPerl-1.6.924
   44  rm -r 2016a Bio-SamTools-1.43 perl-5.8.x tabix-0.2.6 vcftools zlib-1.2.8
   46  tar zxvf BioPerl-1.6.924.tar.gz
   48  cd BioPerl-1.6.924
   50  perl Build.PL
   52  ./Build test
   53  perl -MCPAN -e shell
   54  cpan
   56  less Build.PL
   58  less README
   59  perl Build.PL
   60  ./Build install
   61  perl Bio::Perl
   62  perl Bio::perl
   63  perl Bio::SeqIO
   66  perldoc Bio::SeqIO
   67  apt-get install perl-doc
   68  perldoc Bio::SeqIO
   70  cd ..
   72  tar jxvf samtools-0.1.17.tar.bz2
   74  cd samtools-0.1.1
   76  cd samtools-0.1.17
   78  less INSTALL 
   79  apt-cache search ncurses
   80  apt-get install libncurses5-dev
   82  vim Makefile
CFLAGS= -g -Wall -Wno-unused -Wno-unused-result -O2 -fPIC #-m64 #-arch ppc
Then do "make clean; make" in the Samtools directory to recompile the library.
   83  make clean
   84  make
   86  ls sam.h libbam.a 
   87  ./samtools 
   89  cd ..
   91  tar xvf Bio-SamTools-1.43.tar.gz 
   92  cd Bio-SamTools-1.43
   94  less README 
   95  perl Build.PL 
   96  ./Build 
   97  less INSTALL.pl 
   98  less README 
   99  ./Build test
  100  ./Build install
  102  cd ..
  104  tar jvf tabix-0.2.6.tar.bz2 
  105  tar xvf tabix-0.2.6.tar.bz2 
  107  cd tabix-0.2.6
  109  less Makefile 
  110  bgzip
  111  less Makefile 
  112  make
  113  bgzip
  115  make install
  116  cd perl/
  120  perl -e "print @INC"
  121  find /opt/ -name Tabix.pm
  122  ll
  123  perl Makefile.PL --prefix /opt/lib/perl5/site_perl/5.8.9/
  125  make
  126  make install
  127  find  /opt/lib/perl5/site_perl/5.8.9/ -name "Tabix*"
  128  less /opt/lib/perl5/site_perl/5.8.9/x86_64-linux-thread-multi/Tabix.pm
  129  perl -e "use Tabix;"
  130  cd ..
  132  tar xvf vcftools-vcftools-v0.1.14-18-g4a4e953.tar.gz 
  133  cd vcftools-vcftools-
  134  cd vcftools-vcftools-4a4e953/
  136  cd src/
  138  cd perl/
  140  cd ..
  143  less Makefile.am 
  144  cd ..
  147  less README.md 
  148  ./autogen.sh 
  149  less README.md 
  151  less README.md 
  152  ./configure  --prefix /opt/lib/perl5/site_perl/5.8.9
  153  less README.md 
  154  make
  155  find / -name "libz*"
  156  vim configure
  157  cd ..
  159  tar xvf zlib-1.2.8.tar.gz 
  160  cd zlib-1.2.8
  162  less README 
  163  ./configure
  165  make install
  166  find / -name "libz*"
  167  cd ..
  169  cd vcftools-vcftools-
  170  cd vcftools-vcftools-4a4e953/
  173  less README.md 
  174  cd ..
  176  rm -rf vcftools-vcftools-4a4e953/
  177  tar xvf vcftools-vcftools-v0.1.14-18-g4a4e953.tar.gz 
  178  cd vcftools-vcftools-4a4e953/
  180  ./autogen.sh 
  181  ./configure  --prefix /opt/lib/perl5/site_perl/5.8.9
  182  perl -v
  184  vim configure
  185  ./configure  --prefix /opt/lib/perl5/site_perl/5.8.9
  186  vim configure
  187  ./configure  --prefix /opt/lib/perl5/site_perl/5.8.9
  188  less README.md 
  189  make install
  191  cd src/
  193  cd perl/
  195  ls *pm
  196  cp *pm /opt/lib/perl5/site_perl/5.8.9/x86_64-linux-thread-multi/
  198  perl -e "use Vcf;"
  199  cd ..
  201  cd tabix-0.2.6
  203  cd perl/
  205  vim Makefile.PL 
'-L.. -ltabix -lz'
  207  perl Makefile.PL 
  209  make 
  210  make install

Text install
export PATH 2
cpan install DBI
cp pm/* /opt/lib/perl5/site_perl/5.8.9
cp test.tar.gz ./
apt-get install default-jre

cp /bioapp/annodb/cnv_sv/sv2anno.pl cnv /bioapp/annodb/cnv_sv/
install zlib
/opt/lib/perl5/site_perl/5.8.9/x86_64-linux-thread-multi/auto/Tabix/Tabix.so
Can't open perl script "/bioapp/annodb/indel_stat.pl": No such file or directory
cd 2016a
cp indel_* /bioapp/annodb/
cd /var/data/indel
cp indel_length.R /bioapp/annodb/
vi indel.sh # rm #
vi /bioapp/annodb/indel_lenght_R.pl 30  /usr/bin/R

export PATH=/opt/bin/perl:$PATH
export PATH=/opt/lib/perl5/site_perl/5.8.9:$PATH


