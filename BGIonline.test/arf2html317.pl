#!/usr/bin/perl
#This program is aimed to create the report
# arf-> html
#
#\@author:		dengshengyuan@genomics.cn
#version:		v1.0
#Date:			16/03/2015
#update         2016/11/30
#add Echarts and Html5
use Encode;
#use strict;
#use warnings;
use Cwd;
use CGI qw(:standard);
use Getopt::Long;
use File::Basename qw(dirname basename);
use File::Path qw(mkpath);
use FindBin qw($Bin);
use Cwd 'abs_path';
use JSON;
use Data::Dumper;
# the input value
my ($arf_folder, $data_path, $outdir, $template, $logo, $menu_order, $help, $demo , $hash_num_subtitle, $title_number, $title_lan);
GetOptions(
	"i=s" => \$arf_folder,
	"d=s" => \$data_path,
	"o=s" => \$outdir,
	"t=s" => \$template,
	"logo=s" => \$logo,
	"menu=s" => \$menu_order,
	"demo=s" => \$demo,
	"help|?" => \$help
);

# if null print the help message
&usage() if(!$arf_folder || !$data_path || !$template || $help);


#####################
# deploy location####
my $AREA = "SZ";
my $email_user_name = "P_RD\@genomics.cn";
my $email_password = "2016KFyanfa";
#####################

#set the software path
my $dm_ftp="webdb";
my $dm_ftp_pass="#B/aTi\$y\"Hla";
my $enca_path = "";
my $gs_path = "";
my $convert_path = "";
my $ftp_path = "";
my $host = "";
my $url_link = "";
my $url_path = "";
my $program_dir = "";

#set the software path
$enca_path = "/opt/bin/enca-1.13/bin/enca";
$gs_path = "/usr/bin/gs";
$convert_path = "/usr/bin/convert";
$ftp_path = "/l3bioinfo/results/report";
$host = "cdts.genomics.org.cn";
$url_link = "/opt/bin/index.html";
$url_path = "/l3bioinfo/results/report";
$program_dir = "/l3bioinfo/results/report";

#Global var
#mark the arf file name
my @arf_filename;
#The report website menu
my @report_menu_order;
# the language version
my $lan_version = "";
my $arf_lan = "EN";
#global variable
my $format = "";
my $line = 0;
my $error_line = 0;
my $exlabel = "";
my $lastlabel = "";
my $nowlabel = "";
#mark the %, such as %result, %method ...
my $type_label = "";
my $title_label = "";
#mark the title
my $now_title = "";

#save the title
#save line, %, title_name
my @each_title;

#FROM paragraph content
#save the line,title, table_number
my @number_table_paragraph;
#save the line, title, figure_number
my @number_figure_paragraph;
#save the line, title, reference_number
my @number_reference_paragraph;

#each title, the number of table, figure, reference
my @number_title;
my @number_table;
my @number_figure;
my @number_reference;
my @sum_reference;
my @left_menu;
#the number
my %hash_num_title = ();
my %hash_num_subtitle=();
my %hash_num_table = ();
my %hash_num_figure = ();
my %hash_num_reference = ();
my $num_ref = 0;
#array
my @old_menu = ("\%result", "\%method", "\%help", "\%glossary", "\%FAQ");
my @menu = ("\%Results", "\%Methods", "\%Help", "\%Glossaries", "\%FAQs");
#the content of arf file
my @content;
#the glossary
my @glossary_content;
#the content of website
my @website_content;
#save the part of website
my $word_line = "";
#mark the paragraph number
my $num_text_content = 0;
#add the anlysis label each title
my $flag_analysis = 0;
# the pdf content 
my @pdf_content;
#set the default values
$outdir ||= "./";
$data_path ||= "./";
$demo ||= "0";
#$menu_order ||= "Results,Methods,Tables,Figures,References,Glossaries,FAQs,Help";
$menu_order ||= "Results,Methods,Tables,Figures,Files,References,Help,FAQs,Glossaries";
my %usermessage;
my @usermsg;
#set the menu language
my $buttonContent = "Contents";
my $buttonHide = "Hide";
my $buttonFigure = "Figure";
my $buttonFigureSearch = "Confirm";
my $buttonFigureShow = "Show All";
my $buttonTable = "Table";
my $buttonScrollup = "Scroll Up";
my $buttonScrolldown = "Scroll Down";
my $buttonDownload = "Download";
my $buttonSeeall = "See all";
#default menu value
my %hashMenu = ('Results'=>'Results','Methods'=>'Methods','Tables'=>'Tables','Figures'=>'Figures','Files'=>'Files','References'=>'References','Help'=>'Help','FAQs'=>'FAQs','Glossaries'=>'Glossaries');
# the arf list
my @listarf_cn;
my @listarf_en;
my $page_lan; #EN , CN , ALL_EN, ALL_CN


##############################################
##############################################
##########	main start 	##############


#-----------------delete the old data ---------------------#

#if the report exist, delete
if(-d "$outdir/report"){
	system("rm -rf '$outdir/report'");
}

#read the user message into %usermessage
#eg. cdtsUser = cdts_user_name
#    cdtsPwd = cdts_password
#
#result:
#$usermessage{$content[0]} = $content[1];
#
if(-e "$data_path/report.txt"){
	open IN,"$data_path/report.txt" or die $!;
	while(my $line=<IN>){
		chomp $line;
		$line =~ s/\/\//\//g;
		if ( $line =~ /\s=\s/ ) {
			$line =~ s/\s=\s/=/g;
			my @content = (split /=/, $line);
			$usermessage{$content[0]} = $content[1];
		} else {
			$line =~ s/\s+$//g;
			push @usermsg, $line;
		}
	}
	close IN;
	#other people can not read the file
	system("chmod 700 '$data_path/report.txt'");
}else{
	print "$data_path/report.txt does not exits.\n";
	exit;

}

#set the user message into %usermessage
#eg. 
#cdts_user_name
#cdts_password
#
#result:
#$usermessage{cdtsUser} = $usermsg[0];
#$usermessage{cdtsUser} = $usermsg[0];
if ( @usermsg > 6 ) {
	$usermessage{cdtsUser} = $usermsg[0];
	$usermessage{cdtsPwd} = $usermsg[1];
	$usermessage{ftpPath} = $usermsg[2];
	$usermessage{dataPath} = $usermsg[3];
	$usermessage{reportName} = $usermsg[4];
	$usermessage{email} = $usermsg[5];
	$usermessage{randomNum} = $usermsg[6];
}

#set the report name, if the reportname is Englist reportname or Chinese reprot name. then $usermessage{reportNameCN} and $usermessage{reportNameEN} are the same.
#eg. reportname = AAAAA   => $usermessage{reportNameCN} = AAAAA; $usermessage{reportNameEN} => AAAAA
#eg. reportname = AAAAA && BBBBB   => $usermessage{reportNameCN} = AAAAA; $usermessage{reportNameEN} => BBBBB
if ( !(defined $usermessage{reportNameCN})) {
	if ( $usermessage{reportName} =~ /^(.*?)\&\&(.*?)$/ ){
		$usermessage{reportName} = $1;
		$usermessage{reportNameCN} = $2;
	} else {
		$usermessage{reportNameCN} = $usermessage{reportName};
	}
}

# modify the file permisson
if ( -e "$outdir/reportTar.txt" ) {
	#other people can not read the file
	system("chmod 700 '$outdir/reportTar.txt'");

}


#if the cdts account is not OKay, send the email.
###if ( !( -e "$ftp_path/$usermessage{cdtsUser}" ) ) {
###        if ( $usermessage{email} =~ /\@genomics.cn/ || $usermessage{email} =~ /\@bgitechsolutions.com/ ) {
###                system("java -jar SendMail.jar '$email_user_name' '$email_password' '$usermessage{email}' 'Warning: The cdts account is not OK. You can not open the Files---> Download the files. </br>You can apply a cdts account on ITSM.'");
###        } else {
###                system("java -jar SendMail.jar '$email_user_name' '$email_password' '$usermessage{email}\@genomics.cn' 'Warning: The cdts account is not OK. You can not open the Files---> Download the files. </br>You can apply a cdts account on ITSM.'");
###        }
###}

#process the menu order, set the default value 
my @temp_menu_content = (split /,/, $menu_order);
for(my $i = 0; $i < @temp_menu_content; $i++){
	if(!(grep{$_ eq $temp_menu_content[$i]} @report_menu_order)){
		push @report_menu_order, $temp_menu_content[$i];
		$hash_num_title{$temp_menu_content[$i]} = 0;
		$hash_num_table{$temp_menu_content[$i]} = 0;
		$hash_num_figure{$temp_menu_content[$i]} = 0;
		$hash_num_reference{$temp_menu_content[$i]} = 0;
        $hash_num_subtitle=0;
	}
}

#----- copy the css, js, img and index.html to the output report---------#
#create the report folder
if(!(-d "$outdir/report")){
	system("mkdir -p '$outdir/report'");
}
#
if(!(-d "$outdir/report/src/page")){
	system("mkdir -p '$outdir/report/src/page'");
}
#change the dos file format to unix file format
if(!(-d "$outdir/report/temp")){
	system("mkdir '$outdir/report/temp'");
}
if(!(-d "$outdir/report/temp/cn")){
        system("mkdir -p '$outdir/report/temp/cn'");
}
if(!(-d "$outdir/report/temp/en")){
	system("mkdir -p '$outdir/report/temp/en'");
}

#copy the report template to the output direct.
system("cp -rf '$template/css' $outdir/report/src");
system("cp -rf '$template/js' $outdir/report/src");
system("cp -rf '$template/img' $outdir/report/src");
system("cp -rf '$template/index.html' $outdir/report");

#-------------	process the arf folder	-------------------#
#mark the arf file name from arf folder
opendir(TEMPDIR, $arf_folder) or die "can't open it:$!";
my @temp_arf_name = readdir TEMPDIR; 
close TEMPDIR;

# put the arf file name into @arf_filename
foreach(@temp_arf_name){
	if($_ =~ /^(.*?)\.arf$/){
		push @arf_filename, $_;
	}
}


#if the arf folser have Chinese arf n Englist arf, classify
foreach(@arf_filename){
	my $arfName = $_;
	
	system("cp -rf '$arf_folder/$arfName' $outdir/report/temp");
 	#winodws fle to linux file
	system("dos2unix '$outdir/report/temp/$arfName'");
	#get the absolutely path
	my $abs_outdir = abs_path($outdir);
	my $abs_arf = "$abs_outdir/report/temp/$arfName";
	
	if(-e $abs_arf){
		my $cp_flag = 0;
		my $flag_language = 0;
		open IN, "$abs_arf" or die $!;
		while (<IN>){
			chomp;
			if($_ =~ /^(language)\s?=\s?(.*?)$/){
				$flag_language = 1;
				$cp_flag = 1;
				if($2 =~ /cn/ || $2 =~ /CN/){
					# the arf language is cn.
					system("cp -rf '$arf_folder/$arfName' '$outdir/report/temp/cn'");
					push @listarf_cn, "$abs_outdir/report/temp/cn/$arfName";
					last;
				}else{
					# the arf language is en.
					system("cp -rf '$arf_folder/$arfName' '$outdir/report/temp/en'");
					push @listarf_en, "$abs_outdir/report/temp/en/$arfName";
					last;
				}
			}
		}
		if(!$flag_language){
			# the arf language is en.
                        system("cp -rf '$arf_folder/$arfName' '$outdir/report/temp/en'");
                        push @listarf_en, "$abs_outdir/report/temp/en/$arfName";
			next;
		}
					
		close IN;			
	}		
	
}


#read the arf file
if(@listarf_en > 0){
	if(@listarf_cn > 0){
		$page_lan = "ALL_EN";
	}else{
		$page_lan = "EN";
	}
	
	#check the arf format
	my $arfCheckFedback = "###### warning #####</br> The arf format is not OK. You can check the arf format with arf_check.pl.</br></br> SZ path: /ifs4/BC_PUB/biosoft/bin/arf_check.pl</br> WH path: /ifswh1/BC_PUB/biosoft/bin/arf_check.pl </br> HK path: /ifshk4/BC_PUB/biosoft/bin/arf_check.pl </br>##################</br></br>##### arf check #####</br>";
	$arfCheckFedback .= `perl /opt/bin/arfPreCheck.pl -i $arf_folder -d $data_path`;

	$arfCheckFedback =~ s/\/data\/newcdts\/project_data//g;

	if ( $arfCheckFedback =~ /File Error/ ) {
		print "The arf format is not OK. Path: $data_path\n";
		if ( $usermessage{email} =~ /\@genomics.cn/ || $usermessage{email} =~ /\@bgitechsolutions.com/ ) {
                	system("java -jar SendMail.jar '$email_user_name' '$email_password' '$usermessage{email}' '$arfCheckFedback'");
        	} else {
                	system("java -jar SendMail.jar '$email_user_name' '$email_password' '$usermessage{email}\@genomics.cn' '$arfCheckFedback'");
        	}
		#delete the report
		if ( -e "$outdir/report" ) {
			system ("rm -rf $outdir/report");
		}
		exit;
	}
	#reset the value
	&reset_value();	
	#read the arf content
	&readArfList(@listarf_en);
	#output the html website
	&createHtml();
}

if(@listarf_cn > 0){
	if(@listarf_en > 0){
		$page_lan = "ALL_CN";
	}else{
		$page_lan = "CN";
	}
	#check the arf format 
	my $arfCheckFedback = `perl /opt/bin/arfPreCheck.pl -i $arf_folder -d $data_path`;

        $arfCheckFedback =~ s/\/data\/newcdts\/project_data//g;

        if ( $arfCheckFedback =~ /File Error/ ) {
		print "The arf format is not OK. Path: $data_path\n";
                if ( $usermessage{email} =~ /\@genomics.cn/ || $usermessage{email} =~ /\@bgitechsolutions.com/ ) {
                        system("java -jar SendMail.jar '$email_user_name' '$email_password' '$usermessage{email}' '$arfCheckFedback'");
                } else {
                        system("java -jar SendMail.jar '$email_user_name' '$email_password' '$usermessage{email}\@genomics.cn' '$arfCheckFedback'");
                }
		#delete the report
		if ( -e "$outdir/report" ) {
			system ("rm -rf $outdir/report");
		}
		exit;
        }
	#reset the value
	&reset_value();	
	#read the arf content
	&readArfList(@listarf_cn);
        #output the html website
	&createHtml();
}

#-----------    create the temp link    ------------#
#create the temp link
if(!(-d "$url_path/$usermessage{randomNum}")){
        system("mkdir -p '$url_path/$usermessage{randomNum}'");

}
if(!(-d "$usermessage{dataPath}")){
#	system("mkdir -p 'ffolder/$usermessage{dataPath}'");
#	print "create floder $usermessage{dataPath} to ftp ";
#    system("perl upload_data.pl $dm_ftp '$dm_ftp_pass' SZ 'ffolder/$usermessage{dataPath}' ''");
}

#cp the index.html to  $url_path/$usermessage{randomNum}
system("cp -rf $url_link '$url_path/$usermessage{randomNum}'");
system("chmod -R 755 '$url_path/$usermessage{randomNum}'");
#create the temp link

#read the template(index.html)
open URL, "$url_link" or die $!;
open URL_LINK, ">$url_path/$usermessage{randomNum}/index.html" or die $!;
while (my $line = <URL>){
        chomp $line;
        if($line =~ /tempLink/){
                $line =~ s/tempLink/..\/..\/$usermessage{dataPath}\/report\/index.html/;

        }
        print URL_LINK $line;
}
close URL;
close URL_LINK;
	
#modifi the File.html
#output tree.xml
&outPutTreexml("$data_path", "$outdir/report/src/page/tree.xml");
if(-e "$outdir/report/src/page/Files.html"){
	system("mv $outdir/report/src/page/Files.html $outdir/report/src//page/Files_temp.html");
	#modifi the file page, insert the dtree code.
	&modifiFilePage("$outdir/report/src/page/Files_temp.html", "$outdir/report/src/page/Files.html");
	#delete the temporary files
	system("rm -rf $outdir/report/src/page/Files_temp.html");
}
if(-e "$outdir/report/src/page/Files_cn.html"){
	system("mv $outdir/report/src/page/Files_cn.html $outdir/report/src/page/Files_cn_temp.html");
	#modifi the file page, insert the dtree code.
	&modifiFilePage("$outdir/report/src/page/Files_cn_temp.html", "$outdir/report/src/page/Files_cn.html");
	#delete the temporary files
	system("rm -rf $outdir/report/src/page/Files_cn_temp.html");
}

#-------------- delete the temp data    ----------------#
if ( -e "$outdir/report/temp" ) {
	system("rm -rf '$outdir/report/temp'");
}


#----------------- copy the data to the cdts server -------------------------#
# create the folder
# chmod foldre 775
if ( ( -d "$ftp_path/$usermessage{cdtsUser}" ) ) {
	system("chmod 775 $ftp_path/$usermessage{cdtsUser}/*");

}

# if the FTP data exist, delete
if ( (-e "$ftp_path/$usermessage{ftpPath}") && !$demo ) {
	system("rm -rf '$ftp_path/$usermessage{ftpPath}'");
}

#create the folder on the cdts server
if ( !(-d "$ftp_path/$usermessage{ftpPath}") && !$demo ) {
        system("mkdir -p '$ftp_path/$usermessage{ftpPath}'");
        system("chmod 775 '$ftp_path/$usermessage{ftpPath}'");
}


#----------------- copy the website page to the CDTS ------------------------#
# copy css, js, page, index.html,: report_cn.html or report_en.html to CDTS
if (( -e "$outdir/report" ) && !$demo ){
	#system("mkdir -p '$data_path/BGI_report'");
        chdir "$outdir";
       # system("cp -rf report/* '$data_path/BGI_report'");
        system("zip -q -r report.zip report");
        chdir "$program_dir";
       # chdir "$data_path";
       # system("cp -R $data_path*  $outdir");
        #system("cp -rf '$outdir/report.zip' '$ftp_path/$usermessage{ftpPath}'");
       # system("sh upload_data.pl $dm_ftp $dm_ftp_pass DM '$outdir/report.zip' '$usermessage{dataPath}'");
      #  system("chmod 755 $ftp_path/$usermessage{ftpPath}");
        #system("chmod 755 $ftp_path/$usermessage{ftpPath}/report.zip");
        if ( -e "$outdir/report.zip") {
                system("rm -rf '$outdir/report.zip'");
        #        print "delete report.zip completed!!\n";
        }
}

#FTP data(Files)
if ( -e "$outdir/reportTar.txt" ) {
	# if upload tar file, copy the tar fils to the cdts server
	# delete arf, resource
	if ( -e "$data_path/report.txt" ) {
		system("rm -rf '$data_path/report.txt'");

	} elsif ( -e "$data_path/reportTar.txt" ) {
		system("rm -rf '$data_path/reportTar.txt'");

	} elsif ( -e "$data_path/arf" ) {
		system("rm -rf '$data_path/arf'");

	} elsif ( -e "$data_path/resource" ) {
		system("rm -rf '$data_path/arf'");

	} elsif ( -e "$data_path/BGI_temp_data" ) {
		system("rm -rf '$data_path/BGI_temp_data'");

	} elsif ( -e "$data_path/finish_report.txt") {
		system("rm -rf '$data_path/finish_report.txt'");

	}

	# change the path, cd $data_path	
	chdir "$data_path";
    #    system("zip -q -r BGI_data.zip ./*");
        chdir "$program_dir";
    #    system("cp -rf '$data_path/BGI_data.zip' '$ftp_path/$usermessage{ftpPath}'") if ( -e "$ftp_path/$usermessage{ftpPath}");
    #    system("perl upload_data.pl $dm_ftp $dm_ftp_pass SZ '$data_path/BGI_data.zip' '$usermessage{dataPath}'");
	system("rm -rf '$data_path/BGI_data.zip'") if ( -e "$data_path/BGI_data.zip" );

} elsif ( -e "$outdir/report.txt" ) {
        system("mkdir -p '$url_path/BGI_temp_data'");
	chdir "$outdir";
        system("cp -rf ./*  '$url_path/BGI_temp_data'");
        if ( -e "$url_path/BGI_temp_data/report.txt" ) {
	     system("rm -rf '$url_path/BGI_temp_data/report.txt'");

        } elsif ( -e "$url_path/BGI_temp_data/reportTar.txt" ) {
            system("rm -rf '$url_path/BGI_temp_data/reportTar.txt'");

        } elsif ( -e "$url_path/BGI_temp_data/arf" ) {
            system("rm -rf '$url_path/BGI_temp_data/arf'");
	    print "delete arf folder\n";

        } elsif ( -e "$url_path/BGI_temp_data/resource" ) {
            system("rm -rf '$url_path/BGI_temp_data/arf'");

        } elsif ( -e "$url_path/BGI_temp_data/BGI_temp_data" ) {
            system("rm -rf '$url_path/BGI_temp_data/BGI_temp_data'");

        } elsif ( -e "$url_path/BGI_temp_data/finish_report.txt") {
            system("rm -rf '$url_path/BGI_temp_data/finish_report.txt'");

        }
	    
	print "its has report txt\n";
        chdir "$url_path/BGI_temp_data";
	system("rm -rf '$url_path/BGI_temp_data/arf'");
	system("rm -rf '$url_path/BGI_temp_data/report.txt'");
	system("rm -rf '$url_path/BGI_temp_data/report'");
     #   system("zip -q -r BGI_data.zip ./*");
        chdir "$program_dir";
      #  system("cp -rf '$url_path/BGI_temp_data/BGI_data.zip' '$ftp_path/$usermessage{ftpPath}'") if ( -e "$ftp_path/$usermessage{ftpPath}");
	chdir "$data_path";
#	system("rm -rf BGI_data.zip");       
 #system("perl upload_data.pl $dm_ftp '$dm_ftp_pass' SZ '$outdir/BGI_data.zip' '$usermessage{dataPath}'");
      #  system("rm -rf '$url_path/BGI_temp_data'") if ( -e "$url_path/BGI_temp_data/BGI_data.zip" );
        
 #       opendir(BGIRESULT, $data_path) or die "can't open it:$!";
  #      my @bgi_result = readdir BGIRESULT;
   #     close BGIRESULT;
    #    my @bgi_result_folder;
         
    #    foreach(@bgi_result){
     #           if(!($_ eq "arf" || $_ eq "report" || $_ eq "." || $_ eq ".." || $_ eq "resource" || $_ eq "BGI_temp_data" || $_ eq "report.txt" || $_ eq "reportTar.txt" || $_ eq "finish_report.txt")){
      #                  push @bgi_result_folder, $_;
       #         }
       # }

        #copy the result data to the FTP(Files)
       # foreach ( @bgi_result_folder ) {
        #        if ( ( -e "$data_path/$_" ) && !$demo ) {
                        #copy the data to the cdts server
         #               system("cp -rf '$data_path/$_' '$ftp_path/$usermessage{ftpPath}'");
          #              system("perl upload_data.pl $dm_ftp $dm_ftp_pass DM '$data_path/BGI_data.zip' '$usermessage{dataPath}'");
                        #modify the file permission
           #             system("chmod -R 755 '$ftp_path/$usermessage{ftpPath}'");
            #    }
       # }
        
}

#########	   END		#############
#############################################
	



#############################################
##########      subroutine      #############

#	sub output_report_website(){}	#output the website 
#	sub create_pdf(){}		#create the pdf
#	sub referenceIntoWebsite(){}	#translate \reference{1} into [1]
#	sub referenceIntoWebsite()	#process the reference number
#	sub arf_num2website_num(){}	#translate the \table{number} into website number
#	sub input_arf(){}		#process the arf file
#	sub main_process(){}		#select the label 
#	sub format_process(){}		#process the format label
#	sub lan_process(){}		#process the language label
#	sub menu_process(){}		#process the %result label
#	sub title_process(){}		#process the title label
#	sub paragraph_process(){}	#process the paragraph label
#	sub table_process(){}		#process the table label
#	sub figure_process(){}		#process the figure label
#	sub reference_process(){}	#process the reference label
#	sub glossary_process(){}	#process the glossary label
#	sub FAQ_process(){}		#process the FAQ label
#	sub wrong_label_processs(){}	#process the wrong label
#	sub rich_text(){}		#process the rich text, such as: \textif{}
#	sub digitize(){}		#process the int, such as: 123456789 => 123,456,789
#	sub decimal(){}			#process the table:float n the scientific
#	sub usage(){}			#print the program the message
#	sub index_cn(){}		#the Chinese version
#	sub index_en(){}		#the English version
#	sub index_all(){}		#the Chinese version n the English version
#	sub add_logo(){}		#add an logo
#	sub reset_value(){} 		#reset the value
#	sub readArfList(){}		#input the arf file
#	sub createHtml(){}		#create the website
#	sub modifiFilePage(){} 		#modifi the File.html, insert the dTree
#	sub outPutTreexml(){} 		#output the tree.xml   File => tree.xml

#############################################
#####	output the report website	#####
sub output_report_website(){
	# input (head_menu, left_menu, content)
        # head_menu: such as Results, Methods, Tables, Figure, References, help, FAQs
        # left_menu: at the top of the page, content: Hide or show
        # eg. left_menu[result, 1, title]
        # content: the page content
	# eg. report_page_content[ "0", Results, title, content ]; 
	my ($head_menu_bar2, $report_left_menu, $report_page_content) = @_;
	
	# head_menu:Results, Methods, Tables, Figure, References, help, FAQs
	my $length_menu = scalar(@$head_menu_bar2);
	for(my $i = 0; $i < $length_menu; $i++){
		my @temp_left_menu = ();
		my $page_content = "";
		#get the length of array
		my $length_left_menu = scalar(@$report_left_menu);
		for(my $j = 0; $j < $length_left_menu; $j++){
			
			if("$$head_menu_bar2[$i]" eq $$report_left_menu[$j][0]){
				#push number, title into @temp_left_menu
				push @temp_left_menu, [$$report_left_menu[$j][1], $$report_left_menu[$j][2]];
		
			}
		}
		# process the page content
		my $length_page_content = scalar(@$report_page_content);
		for ( my $j = 0; $j < $length_page_content; $j++ ) {
			if ( "$$head_menu_bar2[$i]" eq $$report_page_content[$j][1] ) {
				#report_page_content[ "0", Results, title, content ]; 
				my $temp = $$report_page_content[$j][3];
				# process the rich text
				my $temp_content = &rich_text($temp);
				# process the arf number, translate the arf number to website number
				# eg. \figure{number}, \table{number}
				$page_content .= &arf_num2website_num($$report_page_content[$j][0], $$report_page_content[$j][1], $$report_page_content[$j][2], $temp_content);
			}
		}
		
		# the pdf content [Results, content]
		push @pdf_content,[$$head_menu_bar2[$i],$page_content];
		
		# create the folder
		if(!(-d "$outdir/report/src/page")){
			system("mkdir '$outdir/report/src/page'");
		}		
		
		# read Template.html, and output Results.html, Methods.html and so on.
		open IN, "$template/page/Template.html" or die $!;
		if($arf_lan eq "cn" || $arf_lan eq "CN"){
			# Chinese website
			open OUT, ">$outdir/report/src/page/$$head_menu_bar2[$i]_cn.html" or die $!;

		}else{
			# English website
			open OUT, ">$outdir/report/src/page/$$head_menu_bar2[$i].html" or die $!;

		}
		
		#replace the content
		while(my $line = <IN>){
			chomp $line;
			if($line =~ /\$head_title\$/){
				$line =~ s/\$head_title\$/<title>$$head_menu_bar2[$i]<\/title>/;
		
			}elsif($line =~ /\$logo\$/){
				my $temp_add_logo = &add_logo;
#				$line =~ s/\$logo\$/$temp_add_logo/g;

			}elsif($line =~ /\$link\$/){
				$line =~ s/\$link\$/$lan_version/g;
			
			}elsif($line =~ /\$head_menu_bar\$/){
				my $temp_head_menu_bar = &head_menu_bar("$$head_menu_bar2[$i]", @$head_menu_bar2);
				$line =~ s/\$head_menu_bar\$/$temp_head_menu_bar/g;
		
			}elsif($line =~ /\$left_menu_bar\$/){
				my $temp_left_menu_bar = "";
				print OUT "\t\t\t<div class = \"content\">\n";
				$temp_left_menu_bar = &left_menu_bar("$$head_menu_bar2[$i]", @temp_left_menu);				
				$line =~ s/\$left_menu_bar\$/$temp_left_menu_bar/g;
				
			}elsif($line =~ /\$content\$/){
#				print OUT "<h1>$$head_menu_bar2[$i]</h1>\n";
				$line =~ s/\$content\$/$page_content/g;
				$line .= "\t<br/><br/>\n";
				$line .= "\t\t\t</div>\n";
			}elsif($line =~ /\[Show\]/){
				if($arf_lan eq "cn" || $arf_lan eq "CN"){
					$line =~ s/\[Show\]/[展示]/;
				}

			}elsif($line =~ /\[Hide\]/){
				if($arf_lan eq "cn" || $arf_lan eq "CN"){
					$line =~ s/\[Hide\]/[隐藏]/;
				}
			}
		
			print OUT "$line\n";
		}
		
		close IN;
		close OUT;
	}
	
}	
	
	
sub create_pdf(){
	#create the pdf.html
	#input @pdf_content  [Results, page_content]
	#output pdf.html
	my @pdf = @_;
	my $pdf_html = "";
	# the PDF contain 4 parts
	#my @pdf_order = ("Results","Methods","Help","References");
	my @pdf_order = ("Results","Methods","Help","FAQs","References");
	my $length = scalar(@pdf);
	for(my $i = 0; $i < @pdf_order; $i++){
		for(my $j = 0; $j < $length; $j++){
			if($pdf_order[$i] eq $pdf[$j][0]){
				my $pdf_title = "";
				if ( "$pdf_order[$i]" eq "Results" ) {
					if ( $arf_lan eq "cn" || $arf_lan eq "CN" ) {
						$pdf_title = "分析结果";
					} else {
						$pdf_title = "Results";
					}
				} elsif ( "$pdf_order[$i]" eq "Methods" ) {
					if ( $arf_lan eq "cn" || $arf_lan eq "CN" ) {
                                                $pdf_title = "分析方法";
                                        } else {
                                                $pdf_title = "Methods";
                                        }
				} elsif ( "$pdf_order[$i]" eq "Help" ) {
					if ( $arf_lan eq "cn" || $arf_lan eq "CN" ) {
                                                $pdf_title = "帮助";
                                        } else {
                                                $pdf_title = "Help";
                                        }
				} elsif ( "$pdf_order[$i]" eq "References" ) {
					if ( $arf_lan eq "cn" || $arf_lan eq "CN" ) {
                                                $pdf_title = "参考文献";
                                        } else {
                                                $pdf_title = "References";
                                        }
				} elsif ( "$pdf_order[$i]" eq "FAQs" ) {
					if ( $arf_lan eq "cn" || $arf_lan eq "CN" ) {
                                                $pdf_title = "常见问题";
                                        } else {
                                                $pdf_title = "FAQs";
                                        }
				} else {
					$pdf_title = $pdf_order[$i];
				}
				
				$pdf_html .= "<h1 style=\"color:#0072bc\"><div style=\"width:22px;height:22px; border-radius: 11px;background-color: #0072bc;float:left;margin-top:8px;\"></div> &nbsp;$pdf_title</h1>\n";
				$pdf_html .= $pdf[$j][1];
				$pdf_html .= "\t<br/><br/>\n";
			}
		}		
	}	
	
	$pdf_html =~ s/albumSlider lane/albumSlider lane toPage/g;
	
	#set the pdf figure center
#	$pdf_html =~ s/albumSlider lane/albumSlider lane toPage mg0auto/g;
#	$pdf_html =~ s/div class = "mgt"/div class = "mgt align_center"/g;
	#update the pdf report name 	
	#./pdf/cover_en.html line35, update BGI Report => the new report name.
	
	#process the pdf cover, the first page
	if ($arf_lan eq "cn" || $arf_lan eq "CN") {
		open PDF, "/opt/bin/pdf/cover_beta.html" or die $!;
		#open PDFOUT, ">./pdf/cover_cn.html" or die $!;
		open PDFOUT, ">/opt/bin/pdf/cover_cn.html" or die $!;
		while (my $line = <PDF>){
			chomp $line;
			if($line =~ /BGI Report/){
				my $codeType = "";
				if ( -e "$data_path/report.txt" ) {
					# get the file encode, such as utf-8 or gbk2312
					$codeType = `file -bi $data_path/report.txt | sed -e 's/.*[ ]charset=//' |tr '[a-z]' '[A-Z]'`;
				}
				if ( $codeType =~ /UTF-8/ || $codeType =~ /utf-8/) {
					# process the file encode
					##$usermessage{reportNameCN} = encode("gb2312",decode("utf8",$usermessage{reportNameCN}));#by chenwt
				}
				$line =~ s/BGI Report/$usermessage{reportNameCN}/;
			}
	
			print PDFOUT "$line\n";
		
		}
		close PDF;
		close PDFOUT;
	
	} else {
		open PDF, "/opt/bin/pdf/cover_beta.html" or die $!;
        	open PDFOUT, ">/opt/bin/pdf/cover_en.html" or die $!;
		while (my $line = <PDF>){
                	chomp $line;
	                if($line =~ /BGI Report/){
                	        $line =~ s/BGI Report/$usermessage{reportName}/;
                	}

	                print PDFOUT "$line\n";

        	}
	        close PDF;
        	close PDFOUT;
	}
	
	# create the PDF.html
	open IN, "$template/page/Template_pdf.html" or die $!;
	if($arf_lan eq "cn" || $arf_lan eq "CN"){
	       	open OUT, ">$outdir/report/src/page/PDF_cn.html" or die $!;
	}else{
		open OUT, ">$outdir/report/src/page/PDF.html" or die $!;
	}
        while(my $line = <IN>){
        chomp $line;
		if($line =~ /report_beta\.css/){
			$line =~ s/report_beta\.css/report_pdf\.css/g;

		}
               	if($line =~ /\$head_title\$/){
                        $line =~ s/\$head_title\$/<title>PDF<\/title>/;

                }elsif($line =~ /\$logo\$/){
                        my $temp_add_logo = &add_logo;
#                       $line =~ s/\$logo\$/$temp_add_logo/g;

                }elsif($line =~ /\$link\$/){
                	$line =~ s/\$link\$//g;

                }elsif($line =~ /\$head_menu_bar\$/){
                        $line =~ s/\$head_menu_bar\$//g;

                }elsif($line =~ /\$left_menu_bar\$/){
                        print OUT "\t\t\t<div class = \"content\">\n";
                        $line =~ s/\$left_menu_bar\$//g;

                }elsif($line =~ /\$content\$/){
                        $line =~ s/\$content\$/$pdf_html/g;
                        $line .= "\t<br/><br/>\n";
                        $line .= "\t\t\t</div>";
                }
		
		# remove the css
		if($line =~ /margin-left:230px;/){
                        $line =~ s/margin-left:230px;//;

                }
		#replace the css
                if($line =~ /width:1035px/){
                        $line =~ s/width:1035px/width:1265px/;

                }
		if($line =~ /report.js/){
			next;
		}
                print OUT $line;
        }

        close IN;
        close OUT;
	
	# translate the PDF.html to report_en.pdf
	if(-e "$outdir/report/src/page/PDF.html"){
		# sh html2pdf.sh "the first page of the PDF" "input: PDF.html" "language" "outptu: report_en.pdf"
		system("sh /opt/bin/pdf/html2pdf2.13.sh /opt/bin/pdf/cover_en.html $outdir/report/src/page/PDF.html en $outdir/report/report_en.pdf");
	}
	if(-e "$outdir/report/src/page/PDF_cn.html"){
                #system("sh /ifs4/BC_RD/USER/chenweitian/pipeline/RNA_denovo2016a/Report/Transcriptome_Denovo_Report/html2pdf2.sh ./pdf/cover_cn.html $outdir/report/src/page/PDF_cn.html cn $outdir/report/report_cn.pdf");
		system("sh /opt/bin/pdf/html2pdf2.13.sh  /opt/bin/pdf/cover_cn.html  $outdir/report/src/page/PDF_cn.html cn $outdir/report/report_cn.pdf");

    }
	
}


sub referenceIntoWebsite() {
	# #translate \reference{1} into [1]
	# @website_content, [ "0", Results, title, content ];
	my ( $web_content ) = @_;
        my %reference_url_num;
	my $length = scalar ( @$web_content );
	for ( my $i = 0; $i < $length; $i++ ) {
		# @website_content, [ "0", Results, title, content ];
		#@number_reference[ "0", Results, title, $ref_num, "0", $ref_url, $ref_text ];
		# the seconde "0" means the reference is not use in the paragraph
		for my $j (0 .. $#number_reference){
                	if (( $$web_content[$i][1] eq $number_reference[$j][1] ) && ( $$web_content[$i][2] eq $number_reference[$j][2] )) {
                        	if ( $$web_content[$i][3] =~ /\\reference\s*?{\s*?$number_reference[$j][3]}/ ) {
                                        if (!(exists $reference_url_num{$number_reference[$j][5]})) {
                                		my $ref_exist = 1;                                                
						# the reference does not in the website_content
                                		if ( $number_reference[$j][4] eq "0" ) {
                                        		$ref_exist = 0;
                                        		$num_ref++;
							# set the reference number
                                        		$number_reference[$j][4] = $num_ref;
                                                        $reference_url_num{$number_reference[$j][5]} = $num_ref;

                                		}

                                		$$web_content[$i][3] =~ s/\\reference\s*?{\s*?$number_reference[$j][3]}/<a href=\"$number_reference[$j][5]\" target=\"_blank\"><sup>[$number_reference[$j][4]]<\/sup><\/a>/g;
                                		if ( $ref_exist eq "0" ) {
							# if the reference use in the paragraph, push the reference into the @website_content
                                        		$ref_exist = "1";
                                        		$word_line = "\t<div class = \"p2\"><a href = \"$number_reference[$j][5]\" target = \"_blank\">[$number_reference[$j][4]] $number_reference[$j][6]</a></div>\n";
                                        		push @website_content, [ "0", "References", $number_reference[$j][2], $word_line];
                                		}

                                        } else {
                                                $$web_content[$i][3] =~ s/\\reference\s*?{\s*?$number_reference[$j][3]}/<a href=\"$number_reference[$j][5]\" target=\"_blank\"><sup>[$reference_url_num{$number_reference[$j][5]}]<\/sup><\/a>/g;


                                        }
                        	}
                	}
        	}
		
		#if last step can not translate the reference number, this step translate it without check the label name
		for my $j (0 .. $#number_reference){
                	if ( $$web_content[$i][3] =~ /\\reference\s*?{\s*?$number_reference[$j][3]}/){
                                if ( !(exists $reference_url_num{$number_reference[$j][5]}) ) {
                        		my $ref_exist = 1;
	                                if ( $number_reference[$j][4] eq "0" ){
						# the reference does not in the website_content
                	                	$ref_exist = 0;
                        	                $num_ref++;
                                	        $number_reference[$j][4] = $num_ref;
                                                $reference_url_num{$number_reference[$j][5]} = $num_ref;
	                                }
        	                        $$web_content[$i][3] =~ s/\\reference\s*?{\s*?$number_reference[$j][3]}/<a href=\"$number_reference[$j][5]\" target=\"_blank\"><sup>[$number_reference[$j][4]]<\/sup><\/a>/g;
                	                if ( $ref_exist eq "0" ) {
						# push the reference into the website_content
                                		$ref_exist = "1";
                                        	$word_line = "\t<div class = \"p2\"><a href = \"$number_reference[$j][5]\" target = \"_blank\">[$number_reference[$j][4]] $number_reference[$j][6]</a></div>\n";

	                                        push @website_content, [ "0", "References", $number_reference[$j][2], $word_line];
        	                        }
				} else {
					$$web_content[$i][3] =~ s/\\reference\s*?{\s*?$number_reference[$j][3]}/<a href=\"$number_reference[$j][5]\" target=\"_blank\"><sup>[$reference_url_num{$number_reference[$j][5]}]<\/sup><\/a>/g;

				}
                        }
                }
	}	
}

#translate the \table{number}, \figure{number} into website number
sub arf_num2website_num(){
	#report_page_content[ "0", Results, title, content ]
	my ($flag_glo, $type, $title, $temp_content) = @_;
	my @temp_array = ();
	my $temp_ary = 0;
	
	$type =~ s/\s//g;
	$title =~ s/\s//g;
	if($temp_content =~ /\\#/){
		$temp_content =~ s/\\#/#/g;

	}
	if($temp_content =~ /\\\@/){
                $temp_content =~ s/\\\@/\@/g;

        }

	# process the \title{number}
	# in the text content, convert title name to title number
	# this page jump to next page
        if ( $temp_content =~ /\\title\s*?{\s*(.*?)\s*}/ ) {
		my $title_lan = "";
		my $title_flag = 0;
		my $temp_number = $1;
		$temp_number =~ s/\s//g;
		if ( $arf_lan eq "cn" || $arf_lan eq "CN" ) {
			$title_lan = "cn";
		} else {
			$title_lan = "en";
		}
		# @number_title[ Result, language(en or cn), number(website numbser), title_num(arf number), title name ];
		for my $i ( 0 .. $#number_title ) {
			# arf title number
			my $number_title = $number_title[$i][3];
			# remove the space
			$number_title =~ s/\s//g;
			if ( "$title_lan" eq "$number_title[$i][1]" ) {
				$title_flag = 1;
				if ( $arf_lan eq "cn" || $arf_lan eq "CN" ) {
                               		$temp_content =~ s/\\title\s*?{\s*?$number_title[$i][3]\s*?}/<a href = "$number_title[$i][0]_cn.html#$number_title[$i][2]" class = "black"><b>$number_title[$i][4]<\/b><\/a>/gi;
				} else {
					$temp_content =~ s/\\title\s*?{\s*?$number_title[$i][3]\s*?}/<a href = "$number_title[$i][0].html#$number_title[$i][2]" class = "black"><b>$number_title[$i][4]<\/b><\/a>/gi;
				}
			}
		}
		# last step, can not match \title{number}, match it without  "$title_lan" eq "$number_title[$i][1]"
		if ( $title_flag eq "0" ) {
			for my $i ( 0 .. $#number_title ) {
				my $number_title = $number_title[$i][3];
				$number_title =~ s/\s//g;
                                	if ( $arf_lan eq "cn" || $arf_lan eq "CN" ) {
                                        	$temp_content =~ s/\\title\s*?{\s*?$number_title[$i][3]\s*?}/<a href = "$number_title[$i][0]_cn.html#$number_title[$i][2]" class = "black"><b>$number_title[$i][4]<\/b><\/a>/gi;
                                	} else {
                                        	$temp_content =~ s/\\title\s*?{\s*?$number_title[$i][3]\s*?}/<a href = "$number_title[$i][0].html#$number_title[$i][2]" class = "black"><b>$number_title[$i][4]<\/b><\/a>/gi;
                                	}
                	}
		}
        }
        	
	
	#process the \table{number}
	#in the text_content, convert table name to table number
	for my $i (0 .. $#number_table){
		# @number_table[ Results, title, table_number(arf), table_number(website)];
		if(($number_table[$i][0] eq $type) &&($number_table[$i][1] eq $title)){
			# Table \table{number} => Table number(website number)
			if($temp_content =~ /Table\s*?\\table\s*?{\s*?$number_table[$i][2]\s*?}/){
                                #$temp_content =~ s/Table\s*?\\table\s*?{\s*?$number_table[$i][2]\s*?}/<a href = "#table$number_table[$i][3]" class = "black"><b>$buttonTable&nbsp;$number_table[$i][3]&nbsp;&nbsp;<\/b><\/a>/g;
				$temp_content =~ s/Table\s*?\\table\s*?{\s*?$number_table[$i][2]\s*?}/<a href = "#table$number_table[$i][3]" class = "black"><b>$buttonTable$number_table[$i][3]<\/b><\/a>/g;

			}elsif($temp_content =~ /表\s*?\\table\s*?{\s*?$number_table[$i][2]\s*?}/){
				# 表 \table{number} => Table number(website number)
				#$temp_content =~ s/表\s*?\\table\s*?{\s*?$number_table[$i][2]\s*?}/<a href = "#table$number_table[$i][3]" class = "black"><b>$buttonTable&nbsp;$number_table[$i][3]&nbsp;&nbsp;<\/b><\/a>/g;
				$temp_content =~ s/表\s*?\\table\s*?{\s*?$number_table[$i][2]\s*?}/<a href = "#table$number_table[$i][3]" class = "black"><b>$buttonTable$number_table[$i][3]<\/b><\/a>/g;
				
                        }elsif($temp_content =~ /\\table\s*?{\s*?$number_table[$i][2]\s*?}/){
				# \table{number} => Table number(website number)
				$temp_content =~ s/\\table\s*?{\s*?$number_table[$i][2]\s*?}/<a href = "#table$number_table[$i][3]" class = "black"><b>$buttonTable$number_table[$i][3]<\/b><\/a>/g;

			}
		}
	}


	# process the \figure{number}
	# in the text_content, convert  figurename to figure number
	# @number_figure [ Result, title, figure_number(arf), figure_number(website)];
	for my $i (0 .. $#number_figure){
		if(($number_figure[$i][0] eq $type) && ($number_figure[$i][1] eq $title)){
			# Figure \figure{number} => Figure number(website number)
			if($temp_content =~ /Figure\s*?\\figure\s*?{\s*?$number_figure[$i][2]\s*?}/){
                                $temp_content =~ s/Figure\s*?\\figure\s*?{\s*?$number_figure[$i][2]\s*?}/<a href = "#figure$number_figure[$i][3]" class = "black"><b>$buttonFigure$number_figure[$i][3]<\/b><\/a>/g;

			}elsif($temp_content =~ /图\s*?\\figure\s*?{\s*?$number_figure[$i][2]\s*?}/){
				#图 \figure{number} => Figure number(website number)
				$temp_content =~ s/图\s*?\\figure\s*?{\s*?$number_figure[$i][2]\s*?}/<a href = "#figure$number_figure[$i][3]" class = "black"><b>$buttonFigure$number_figure[$i][3]<\/b><\/a>/g;
			
                        }elsif($temp_content =~ /\\figure\s*?{\s*?$number_figure[$i][2]\s*?}/){
				# \figure{number} => Figure number(website number)
				$temp_content =~ s/\\figure\s*?{\s*?$number_figure[$i][2]\s*?}/<a href = "#figure$number_figure[$i][3]" class = "black"><b>$buttonFigure$number_figure[$i][3]<\/b><\/a>/g;

			}
		}
	}
	
	#process the glossary
	if($flag_glo eq "1"){
		for my $i (0 .. $#glossary_content){
			if($temp_content =~ /$glossary_content[$i][1]/i){
				
				# the href link does not replace the glossary
				while($temp_content =~ /(<a\s?href\s?=\s?\".*?\"\s?>.*?<\/a>)/gi){
					$temp_ary++;
					my $temp = $1;
				#	$temp =~ s/\//\\\//gi;
				#	$temp =~ s/\?/\\?/gi;
				#	$temp =~ s/\+/\\+/gi;
				#	$temp =~ s/\*/\\*/gi;
					$temp =~ s/\?/\\?/gi;
					$temp =~ s/\+/\\+/gi;
				#	$temp =~ s/\$/\\$/gi;
					$temp =~ s/\(/\\(/gi;
					$temp =~ s/\)/\\)/gi;
					$temp =~ s/\*/\\*/gi;
				#	$temp =~ s/\_/\\_/gi;
					$temp =~ s/\[/\\[/gi;
					$temp =~ s/\]/\\]/gi;
					$temp =~ s/\^/\\^/gi;
					$temp =~ s/\{/\\{/gi;
					$temp =~ s/\}/\\}/gi;
					$temp =~ s/\|/\\|/gi;
					$temp_content =~ s/$temp/temp$temp_ary temp/;
					push @temp_array, ["temp$temp_ary temp","$temp"];
				}
				
				# add the glossary into the website page
				my $temp_glossary_content;
				$temp_glossary_content = "<span class = \"key_sign\">&nbsp;$glossary_content[$i][1]&nbsp;<div class = \"key_body\"><div class = \"key_title\">$glossary_content[$i][1]</div><div class = \"key_content\">$glossary_content[$i][2]</div></div></span>";
				$temp_content =~ s/\b$glossary_content[$i][1]\b/$temp_glossary_content/gi;
				
				for my $j (0 .. $#temp_array){
					$temp_content =~ s/$temp_array[$j][0]/$temp_array[$j][1]/gi;
	
				}
			#	$temp_content =~ s/\\[/\[/gi;
			#	$temp_content =~ s/\\]/\]/gi;
			}
		}
	}
	
	return $temp_content;
	
}

#####	process the website menu	#####
sub head_menu_bar(){
	# input label, @head_mneu
	# eg. label:Result, @head_menu[Result, Methods, Table, Figure, Reference, Help, FAQs ]
	# output: the menu code in the website page
	my ($current_label, @head_menu) = @_;
	my $head_menu_code = "";
	
	$head_menu_code = "\t<div class = \"move_left left_fixer\">\n";
	$head_menu_code .= "\t\t<div class = \"left_top\">";
	$head_menu_code .= "\t<div><a href = \"http://www.bgitechsolutions.cn\" target = \"_blank\"><img src = \"../img/BGI-LOGO2.png\" width = \"110\" alt = \"\"/></a></div>";
	$head_menu_code .= "\t</div>\n";
	$head_menu_code .= "\t\t<ul class = \"left_ul\">\n";
	foreach(@head_menu){
		if($current_label eq $_){
			if($arf_lan eq "cn" || $arf_lan eq "CN"){
				$head_menu_code .= "\t\t\t<li class = \"menuBG toHtml\" url = \"$_\_cn.html\">$hashMenu{$_}\n";
			}else{
				$head_menu_code .= "\t\t\t<li class = \"menuBG toHtml\" url = \"$_.html\">$hashMenu{$_}\n";
			}
		}else{
			if($arf_lan eq "cn" || $arf_lan eq "CN"){
				$head_menu_code .= "\t\t\t<li class = \"toHtml\" url = \"$_\_cn.html\">$hashMenu{$_}\n";
			}else{
				$head_menu_code .= "\t\t\t<li class = \"toHtml\" url = \"$_.html\">$hashMenu{$_}\n";
			}
		}
		$head_menu_code .= "\t\t\t</li>\n";
	}

	
	$head_menu_code .= "\t\t</ul>\n";
	$head_menu_code .= "\t</div>\n\n";

	return $head_menu_code;
}


#####	process the website the left menu	#####
sub left_menu_bar(){
	#this program process the code the of the let menu 
	#[$type_label, @array[number, title]]
	# the title Hide or Show at the top of the website page
	my ($left_menu_title, @left_menu_array) = @_;
	my $left_menu_code = "";
	my $length = scalar(@left_menu_array);
	if($length > 0){
		$left_menu_code .= "\t<div class = \"catalog\">\n";
		$left_menu_code .= "\t<div class = \"cont_ca\">$buttonContent  <span class = \"span_hide\">[$buttonHide]</span></div>";
		for my $i (0 .. $#left_menu_array){
			if($left_menu_array[$i][0] =~ /table/ || $left_menu_array[$i][0] =~ /figure/){
				$left_menu_code .= "\t\t<div class = \"catalog_li\"><a href = \"#$left_menu_array[$i][0]\">$left_menu_array[$i][1]</a></div>\n";
			}else{
				$left_menu_code .= "\t\t<div class = \"catalog_li\"><a href = \"#$left_menu_array[$i][0]\">$left_menu_array[$i][0] $left_menu_array[$i][1]</a></div>\n";
			}
		}
	
		$left_menu_code .= "\t</div>\n";
	}
	
	return $left_menu_code;
}



#####	process the arf file	#####
sub input_arf(){
	# input the arf file
	my @arf_file = @_;

	open IN, $arf_file[0] or die $!;
	while(<IN>){
		chomp;
		#It's used to print error position
		$line += 1;
		next if(/^$/ || /^#/);
		if(($_ =~ /^(format)\s?=\s?(.*?)$/) && !($lastlabel eq "\@table")){
			$nowlabel = $1;
			# when the $liastlabel is null, do not process, read next line
			if($lastlabel){
				&main_process($lastlabel, @content);
				$exlabel = $lastlabel;
				$lastlabel = $1;
				undef @content;
			}else{
				$exlabel = $lastlabel;
				$lastlabel = $1;
				undef @content;
			}
			$error_line = $line;
		}elsif($_ =~ /^(language)\s?=\s?(.*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;
		
		}elsif($_ =~ /^(\%.*?)(\s*?)$/){
			# add new label
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			$exlabel = $lastlabel;
			$lastlabel = $1;
			$lastlabel =~ s/\s//g;
			undef @content;	
		}elsif($_ =~ /^(\@title)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			#check $lastlabel n $nowlabel
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;
		}elsif($_ =~ /^(\@subtitle)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			#check $lastlabel n $nowlabel
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;
		}elsif($_ =~ /^(\@paragraph)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;		
		}elsif($_ =~ /^(\@table)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;		
		}elsif($_ =~ /^(\@figure)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);	
			$error_line = $line;
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;
		}elsif($_ =~ /^(\@reference)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;	
		}elsif($_ =~ /^(\@glossary)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;	
		}elsif($_ =~ /^(\@FAQ)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;
		}elsif($_ =~ /^(\@.*?)(\s*?)$/){
			$nowlabel = $1;
			&main_process($lastlabel, @content);
			$error_line = $line;
			$exlabel = $lastlabel;
			$lastlabel = $1;
			undef @content;
		}
		push @content, $_;
	}	

	close IN;

	#add the lastlabel
	&main_process($lastlabel, @content);


}


########## check rules n print the message ##########
sub main_process(){
	# input: label, @arf_content
	my ($lastlabel, @arf_content) = @_;

	if($lastlabel eq "format"){
		&format_process(@arf_content);

	}elsif($lastlabel eq "language"){
		&lan_process(@arf_content);
 
	}elsif($lastlabel =~ /^\%(.*?)$/){
		&menu_process(@arf_content);

	}elsif($lastlabel eq "\@title"){
		&title_process(@arf_content);


	}elsif($lastlabel eq "\@subtitle"){
		&subtitle_process(@arf_content);

	}elsif($lastlabel eq "\@paragraph"){
		&paragraph_process(@arf_content);


	}elsif($lastlabel eq "\@table"){
		&table_process(@arf_content);

		
	}elsif($lastlabel eq "\@figure"){
		&figure_process(@arf_content);


	}elsif($lastlabel eq "\@reference"){
		&reference_process(@arf_content);


	}elsif($lastlabel eq "\@glossary"){
		&glossary_process(@arf_content);


	}elsif($lastlabel eq "\@FAQ"){
		&FAQ_process(@arf_content);

	}elsif($lastlabel =~ /(\@.*?)/){
		&wrong_label_process(@arf_content);
	}
}


#################################
sub format_process(){
	# the report not use the format
	my @content = @_;
#	if(!($nowlabel =~ /^(\%)$/)){
#		print "Line:$error_line. The next label should be \%content, such as \%result, \%method, \%help, \%glossary or \%FAQ.\n";
#	}
	foreach(@content){
		if(!$_){
			# if null, read next line
                        next;
                }
		if($_ =~ /(format)\s*?=\s*?(.*?)$/){

			if(!$format){
				$format = $2;
			}else{
				#two formats are different
				my $temp_format = $2;
				#remove the space
				$temp_format =~ s/\s//g;
				my $temp2_format = $format;
				$temp2_format =~ s/\s//g;
			}
		}
	}
}


#####	get the arf language	#####
sub lan_process(){
	my @language = @_;

	foreach(@language){
		if(!$_){
                        next;
                }
		if($_ =~ /^(language)\s*?=\s*?(.*?)$/){
			# mark the arf language
			$arf_lan = $2;
			$arf_lan =~ s/\s//g;
			# set the button content of the website page
			&button_lan($arf_lan);			
		}else{
			# set the button content of the website page
			&button_lan($arf_lan);

		}
	}
}

#set the button language in the website page
sub button_lan(){
	my @lan = @_;
	if($lan[0] eq "cn" || $lan[0] eq "CN"){
		$buttonContent = "内容";
		$buttonHide = "隐藏";
		$buttonFigure = "图";
		$buttonFigureSearch = "搜索";
		$buttonFigureShow = "显示";
		$buttonTable = "表";
		$buttonScrollup = "向上";
		$buttonScrolldown = "向下";
		$buttonDownload = "下载";
		$buttonSeeall = "查看全部";
		
		$hashMenu{"Results"} = "分析结果";
		$hashMenu{"Methods"} = "分析方法";
		$hashMenu{"Tables"} = "结果表格";
		$hashMenu{"Figures"} = "结果图片";
		$hashMenu{"Files"} = "文件";
		$hashMenu{"References"} = "参考文献";
		$hashMenu{"Help"} = "帮助";
		$hashMenu{"FAQs"} = "常见问题";
   		$hashMenu{"Glossaries"} = "名词解释";
	}
}


# process the menu, [Results, Methods, Help, Glossaries, FAQs]
sub menu_process(){
	my @content = @_;
	foreach(@content){

		if(!$_){
			next;
		}
		if($_ =~  /^\%(.*?)\s*?$/){
			my $menu_content = $1;
			$menu_content =~ s/\s//g;
			if($menu_content eq "Results" || $menu_content eq "result"){
				$type_label = "Results";
			}elsif($menu_content eq "Methods" || $menu_content eq "method"){
				$type_label = "Methods";
			}elsif($menu_content eq "Help" || $menu_content eq "help"){
				$type_label = "Help";
			}elsif($menu_content eq "Glossaries" || $menu_content eq "glossary"){
				$type_label = "Glossaries";
			}elsif($menu_content eq "FAQs" || $menu_content eq "FAQ"){
				$type_label = "FAQs";
			}else{
				$type_label = $menu_content;
			}
		
			# if the new label not in @report_menu_order, push it into @report_menu_order, and set the default value
			if(!(grep{$_ eq $type_label}@report_menu_order)){
				push @report_menu_order, $type_label;
				$hash_num_title{$type_label} = 0;
				$hash_num_table{$type_label} = 0;
				$hash_num_figure{$type_label} = 0;
				$hash_num_reference{$type_label} = 0;
                
			}	
		}
	}
}


# process the title 
sub title_process(){
	# input: @title
	# 	 number = aaaa
	#        title
	my @content = @_;
    $hash_num_subtitle{$title_label} = 0;
	my $title_number = "";
	my $title_lan = "";
	# the title number of the website page
	$hash_num_title{$type_label}++;
	#set two &nbsp before the paragraph
	$num_text_content = 0;

	foreach ( @content ) {
		my $temp_content = $_;
		if ( !$temp_content ) {
			next;
		}
		chomp $temp_content;
		if ( $temp_content =~ /^\s*\@title\s*$/) {
			next;
		} elsif ( $temp_content =~ /^\s*number\s*=\s*"(.*)"\s*$/ ) {
			$title_number = $1;
		} elsif ( $temp_content =~ /^\s*number\s*=\s*(.*)\s*$/ ) {
			$title_number = $1;
			
		} else {
			$now_title = $temp_content;
			if ( !($flag_analysis eq 0 ) ) {
				$flag_analysis = 1;
				$word_line = "\t<div class = \"mgt  anlysis\"><a name = \'$hash_num_title{$type_label}\'></a></div>\n";
			} else {
				$word_line = "\t<div><a name = \'$hash_num_title{$type_label}\'></a></div>\n";
			}
			$word_line .= "\t<h2>$hash_num_title{$type_label} $now_title</h2>\n\n\n\n";
			# push the content into @website_content
			push @website_content, [ "0", $type_label, $now_title, $word_line ];
			# push the content into @left_mneu. at the top the website page
			push @left_menu, [$type_label, $hash_num_title{$type_label}, $now_title];
			if($arf_lan eq "cn" || $arf_lan eq "CN"){
				$title_lan = "cn";
			} else {
				$title_lan = "en";
			}
			# process \title{number} in the paragraph
			push @number_title, [ $type_label, $title_lan, $hash_num_title{$type_label}, $title_number , $now_title ];
			$now_title =~ s/\s//g;
		}		
	}
}
# process the subtitle
sub subtitle_process(){
# input: @title
	# 	 number = aaaa
	#        title
	my @content = @_;
	my $subtitle_number = "";
	my $subtitle_lan = "";
    my $sub_title_number=0;
	# the title number of the website page
	$hash_num_subtitle{$title_label}+=0.1;
    $sub_title_number = $hash_num_title{$type_label}+$hash_num_subtitle{$title_label};
    $num_text_content = 0;
    foreach ( @content ) {
		my $temp_content = $_;
		if ( !$temp_content ) {
			next;
		}
		chomp $temp_content;
		if ( $temp_content =~ /^\s*\@subtitle\s*$/) {
			next;
		} elsif ( $temp_content =~ /^\s*number\s*=\s*"(.*)"\s*$/ ) {
			$title_number = $1;
		} elsif ( $temp_content =~ /^\s*number\s*=\s*(.*)\s*$/ ) {
			$title_number = $1;
			
		} else {
			$now_title = $temp_content;
			if ( !($flag_analysis eq 0 ) ) {
				$flag_analysis = 1;
				$word_line = "\t<div class = \"mgt  anlysis\"><a name = \'$sub_title_number\'></a></div>\n";
			} else {
				$word_line = "\t<div><a name = \'$sub_title_number\'></a></div>\n";
			}
			$word_line .= "\t<div class=\"h3_sub\">$sub_title_number $now_title</div>\n\n\n\n";
			# push the content into @website_content
			push @website_content, [ "0", $type_label, $now_title, $word_line ];
			# push the content into @left_mneu. at the top the website page
			push @left_menu, [$type_label, $sub_title_number, $now_title];
			if($arf_lan eq "cn" || $arf_lan eq "CN"){
				$title_lan = "cn";
			} else {
				$title_lan = "en";
			}
			# process \title{number} in the paragraph
			push @number_title, [ $type_label, $title_lan, $sub_title_number, $title_number , $now_title ];
			$now_title =~ s/\s//g;
		}		
	}
}
sub paragraph_process(){
	my @content = @_;
	# mark the paragraps
	my @paragraph_content;
	my $flag_verbatim = 0;
	my $flag_verbatim2 = 0;
	my $temp_verbatim = "";
	my $first_line = 0;
	#undef $word_line
	$word_line = "";
	shift @content;
	foreach(@content){
		if(!$_){
			next;
		}
		if($_ =~ /^\\verbatim(\s*?)$/ ){
			$flag_verbatim = 1;
			next;
		}elsif($_ =~ /^\\end(\s*?)$/){
			$flag_verbatim = 0;
			next;
		}

		#put the paragrapth into the array:@paragraph_content("0 or 1", paragraph). 1 means the paragraph belongs to verbatim
		if($flag_verbatim eq "1"){
			my $temp = "";
			if($_ =~ /^\\\@(.*?)$/){
				$temp = "\@$1";
			}else{
				$temp = $_;
			}
			push @paragraph_content,["1", $temp];
		}else{
			push @paragraph_content, ["0", $_];

		}
	}
	
	if(!(defined $paragraph_content[0][0])){
                return undef;
        }	

	#####	translate into the website code		#####	
	my $length = scalar(@paragraph_content);

	if($length < 2){
	#the paragraph only one line
		if($paragraph_content[0][0] eq "0"){
			if(!$num_text_content){
				$num_text_content = 1;
				$word_line .= "\t<div class = \"p\">$paragraph_content[0][1]</div>\n";
			}else{
				if($exlabel eq "\@table" || $exlabel eq "\@figure" ){
					$word_line .= "\t<br/><div class = \"p\">$paragraph_content[0][1]</div>\n";
				}else{
					$word_line .= "\t<br/><div class = \"p\">$paragraph_content[0][1]</div>\n";
				}
			}
		}elsif($paragraph_content[0][0] eq "1"){
			$word_line .= "\t<div class = \"p_content\">\n";
			$word_line .= "\t<div class = \"p_light\">$paragraph_content[0][1]</div>\n";
			$word_line .= "\t</div><br/>\n";
		}
	}else{
	#the paragraph more than 2 lines
	#	@paragraph_content
	#	["0", content]
	#	["0", content]
	#	["1", content]
	#	["1", content]
	#	["0", content]
	#	["0", content]
		for my $i (0 .. ($#paragraph_content-1)){
			#       @paragraph_content
		        #       ["0", content]
       			#       ["0", content]
			if(($paragraph_content[$i][0] eq "0") && ($paragraph_content[$i+1][0] eq "0")){
				if(!$first_line){
					# process the first line
					$first_line = 1;
					if ( $exlabel eq $lastlabel ) {
						# if last label is @paragraph and now_label is @paragraph, add</br> between them
                                                $word_line .= "\t<br/><div class = \"p\">$paragraph_content[$i][1]</div><br/>\n";
                                        } else {
                                                $word_line .= "\t<div class = \"p\">$paragraph_content[$i][1]</div><br/>\n";
                                        }
					if(($i+2) eq $length){
						# the last paragraph
						# if now_label is @paragraph and next_label is @paragraph, add</br> between them
						if($nowlabel eq $lastlabel){
							$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div><br/>\n";
						}else{
							$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div>\n";
						}
					}else{
						$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div><br/>\n";
					}
				}else{
					if(($i+2) eq $length){
						# the last paragraph
						# if now_label is @paragraph and next_label is @paragraph, add</br> between them
						if($nowlabel eq $lastlabel){
							$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div><br/>\n";
						}else{
							$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div>\n";
						}
					}else{
						$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div><br/>\n";
					}
				}

			#       @paragraph_content
		        #       ["0", content]
        		#       ["1", content]
			}elsif(($paragraph_content[$i][0] eq "0") && ($paragraph_content[$i+1][0] eq "1")){
				if(!$first_line){
					# process the first line
					$first_line = 1;
                    			$word_line .= "\t<div class = \"p\">$paragraph_content[$i][1]</div><br/>\n";
					$word_line .= "\t<div class = \"p_content\">\n";
					if(($i+2) eq $length){
						# the last paragraph
        	           			$word_line .= "\t<div class = \"p_light\">$paragraph_content[$i+1][1]</div>\n";
						# if now_label and the next label arf the same, add <br />
						if($lastlabel eq $nowlabel){
							$word_line .= "\t</div><br/>\n";
						}else{
							$word_line .= "\t</div>\n";
						}
					}else{
						$word_line .= "\t<div class = \"p_light\">$paragraph_content[$i+1][1]</div>\n";
					}
				}else{
					$word_line .= "\t<div class = \"p_content\">\n";
					if(($i+2) eq $length){
						# the last paragraph
                      				$word_line .= "\t<div class = \"p_light\">$paragraph_content[$i+1][1]</div>\n";
						# if now_label and the next label arf the same, add <br />
						if($nowlabel eq $lastlabel){
							$word_line .= "\t</div><br/>\n";
						}else{
							$word_line .= "\t</div>\n";
						}
					}else{
						$word_line .= "\t<div class = \"p_light\">$paragraph_content[$i+1][1]</div>\n";
					}
	            		}

			#       @paragraph_content
        		#       ["1", content]
	        	#       ["0", content]

			}elsif(($paragraph_content[$i][0] eq "1")&&($paragraph_content[$i+1][0] eq "0")){
				if(!$first_line){
                        	        $first_line = 1;
                                	$word_line .= "\t<div class = \"p_content\">\n";
	                                $word_line .= "\t<div class = \"p_light\">$paragraph_content[$i][1]</div>\n";
					$word_line .= "\t</div><br/>\n";
					if(($i+2) eq $length){
						# the last paragraph
						if($nowlabel eq $lastlabel){
							# if now_label and the next label arf the same, add <br />
        	                        		$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div><br/>\n";
						}else{
							$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div>\n";
						}
					}else{
						$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div><br/>\n";
					}
                	        }else{
					$word_line .= "\t</div><br/>\n";
					if(($i+2)eq $length){
						# the last paragraph
						if($nowlabel eq $lastlabel){
							# if now_label and the next label arf the same, add <br />
                                			$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div><br/>\n";
						}else{
							$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div>\n";
						}
					}else{
						$word_line .= "\t<div class = \"p\">$paragraph_content[$i+1][1]</div><br/>\n";
					}
	                        }
			#       @paragraph_content
		        #       ["1", content]
		        #       ["2", content]
			}elsif(($paragraph_content[$i][0] eq "1")&&($paragraph_content[$i+1][0] eq "1")){
				if(!$first_line){
                        	        $first_line = 1;
                                	$word_line .= "\t<div class = \"p_content\">\n";
					$word_line .= "\t<div class = \"p_light\">$paragraph_content[$i][1]</div>\n";
					if(($i+2) eq $length){
						# the last paragraph
	        	                        $word_line .= "\t<div class = \"p_light\">$paragraph_content[$i+1][1]</div>\n";
						if($nowlabel eq $lastlabel){
							# if now_label and the next label arf the same, add <br />
							$word_line .= "\t</div><br/>\n";
						}else{
							$word_line .= "\t</div>\n";
						}
					}else{
						$word_line .= "\t<div class = \"p_light\">$paragraph_content[$i+1][1]</div>\n";

					}
					
                	        }elsif(($i+2) eq $length){
					# the last paragraph
					$word_line .= "\t<div class = \"p_light\">$paragraph_content[$i+1][1]</div>\n";
					if($nowlabel eq $lastlabel){
						# if now_label and the next label arf the same, add <br />
						$word_line .= "</div><br/>";
					}else{
						$word_line .= "</div>";
					}
				}else{
        	                        $word_line .= "\t<div class = \"p_light\">$paragraph_content[$i+1][1]</div>\n";
                	        }
			}
		}
	}
	
	$word_line .= "\n\n\n";
	push @website_content, [ "1", $type_label, $now_title, $word_line];
	
	
}


sub table_process(){
	my @content = @_;
	
	my $flag_title = 0;
	my $flag_file = 0;
	my $flag_format = 0;
	my $flag_footnote = 0;
	my $num_footnote = 0;
	my $flag_view = 0;
	
	my $table_num = "";
	my $table_title = "";
	my @table_file;
	my @table_format;
	my @table_footnote;
	my $table_view = "";
	my $show_download = 1;
	$word_line = "";
	$hash_num_table{$type_label}++;

	# get the table content
	foreach(@content){
		if(!$_){
			next;

		}
		if($_ =~ /^number\s*?=\s*?(.*?)\s*?$/){
			$table_num = $1;
      	                #remove the space
	                $table_num =~ s/\s//g;
			
		}elsif($_ =~ /^title\s*?=\s*?"(.*?)"\s*?$/){
			$table_title = $1;
			$flag_title = 1;

		}elsif($_ =~ /^file\s*?=\s*?<(.*?)>\s*?$/){

			#the file is exist
			$flag_file = 1;

			if($1 =~ /^\s*?url\s*?=\s*?(.*?)$/){
				my $url = $1;
				$url =~ s/\s//g;
				push @table_file, $url;	
			}
	
						
		}elsif($_ =~ /^format\s*?=\s*?<(.*?)>\s*?$/){
			#the format is exist
			$flag_format = 1;
			my $content_format = $1;
			my $field = "";
			my $type = "";
			my $mark_type = "";
			my $precision = "";
			my $desc = "";
			my $align = "left";

			if($content_format =~ /;/){
				my @content = (split /;/, $content_format);
				foreach(@content){
                                	if($_ =~ /^\s*?field\s*=\s*(.*?)$/){
                                                $field = $1;
                                                $field =~ s/\s//g;
                                        }elsif($_ =~ /^\s*?type\s*?=\s*?(.*?)$/){
                                                $type = $1;
                                                #remove the space
                                                $type =~ s/\s//g;
                                                #check the type in format
                                                if($type eq "float"){
							$mark_type = $type;
                                                }
                                                if($type eq "scientific"){
                                                	$mark_type = $type;
						}

                                        }elsif($_ =~ /^\s*?precision\s*?=\s*?(.*?)$/){
                                                $precision = $1;
                                                my $reg1 = qr/^-?\d+(\.\d+)?$/;
                                                my $reg2 = qr/^-?0(\d+)?$/;
                                                #remove the space
                                                $precision =~ s/\s//g;
                                        }elsif($_ =~ /^\s*?desc\s*?=\s*?(.*?)$/){
                                                if(!($1 =~ /"(.*?)"/)){

                                                }else{
                                                        $desc = $1;
                                                }
                                        }elsif($_ =~ /^\s*?align\s*?=\s*?(.*?)\s*?$/){
                                                $align = $1;
                                                #remove the space
                                                $align =~ s/\s//g;
                                        }
                                }
			}
			push @table_format, [$field, $type, $precision, $desc, $align];

		}elsif($_ =~ /^footnote\s*?=\s*?"(.*?)"\s*?$/){
			$flag_footnote = 1;
			push @table_footnote, $1;

		}elsif($_ =~ /^view\s*?=\s*?(.*?)\s*?$/){
			$flag_view = 1;

			my $content_view = $1;
			my $reg1 = qr/^-?\d+(\.\d+)?$/;
			my $reg2 = qr/^-?0(\d+)?$/;
			#remove the space
			$content_view =~ s/\s//g;
			if($content_view eq 0){
				$flag_view = 1;
			}
			$table_view = $content_view if (($content_view =~ $reg1 && $content_view !~ $reg2 )||($content_view eq 0));
		
		}
	}

        if ( $flag_file eq "0" ) {
            print "The \@table does not contain the file.\n";
            exit;

        }
	#####	translate into code	#####	
	$word_line .= "\t<div><a name = \"table$hash_num_table{$type_label}\"></a></div>\n";
	
	if($flag_view){
	# in the table, the "view = number"  exist.
		if($table_view eq 0){
		#The table is link
			my $table_path = "$data_path/$table_file[0]";
			if(!(-e $table_path)){
                                print "The file $table_file[0] does not exist.\n";
                                exit;
                        }
			my $table_dir = $table_file[0];
			$table_dir =~ /(.+\/)/;		
			$table_dir = $1;
			if(!(-d "$outdir/report/$table_dir")){
				system("mkdir -p '$outdir/report/$table_dir'");
			}
			$table_path =~ s/\s//g;	
			system("cp -rf $table_path '$outdir/report/$table_dir'");
			
			if($arf_lan eq "cn" || $arf_lan eq "CN"){
				$word_line .= "\t<div class = \"p1\"><b>$buttonTable$hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title &nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonDownload</a>)</div>\n";
			}else{
				$word_line .= "\t<div class = \"p1\"><b>$buttonTable   $hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title &nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonDownload</a>)</div>\n";
			}
		}else{
			#add the </br> between the paragraph and the table              
                        if($exlabel eq "\@paragraph"){
                                $word_line .= "\t<br/>\n";
                        }
			
			my $sum = 0;
	                my $Is_all_show = 1;
			
			# the table path
			my $table_path = "$data_path/$table_file[0]";
                        $table_path =~ s/\s//g;

			# check the table exists
                        if(!(-e $table_path)){
                                print "The file $table_file[0] does not exist.\n";
                                exit;
                        }
			
			# count the lines of the table
			open COUNT, "$table_path" or die $!;
			while(<COUNT>){
				$sum++;
				# 
                                if(($sum > $table_view)&&!($table_view eq "-1")){
                                        $Is_all_show = 0;
                                        last;
                                }				
			}
			$sum = 0;
			close COUNT;
			
			# the table title
        	        if($flag_title){
				# show the download the button
				if($show_download){
					# set the download 
                                	if($Is_all_show){
						# set the download is "download"
						if($arf_lan eq "cn" || $arf_lan eq "CN"){
							$word_line .= "\t<div class = \"p1 mgft25\"><b>$buttonTable$hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title&nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonDownload</a>)</div>\n";
						}else{
							$word_line .= "\t<div class = \"p1 mgft25\"><b>$buttonTable   $hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title&nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonDownload</a>)</div>\n";
						}
                                	}else{
						# set the download is  "See All"
						if($arf_lan eq "cn" || $arf_lan eq "CN"){
							$word_line .= "\t<div class = \"p1 mgft25\"><b>$buttonTable$hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title&nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonSeeall</a>)</div>\n";
						}else{
							$word_line .= "\t<div class = \"p1 mgft25\"><b>$buttonTable   $hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title&nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonSeeall</a>)</div>\n";
						}
                                        	$Is_all_show = 1;
                                	}
                        	}
	                }

        	        $word_line .= "\t<div class = \"align_center table-container\">\n";
                	$word_line .= "\t<table>\n";
	                $word_line .= "\t<tr>";


        	        my $table_dir = $table_file[0];
                	$table_dir =~ /(.+\/)/;
	                $table_dir = $1;

			if(!(-d "$outdir/report/$table_dir")){
        	        	system("mkdir -p '$outdir/report/$table_dir'");
			}
                	system("cp -rf $table_path '$outdir/report/$table_dir'");
                	system ("cp -rf $table_path '$outdir/report/temp/temp.txt'");
	                system ("dos2unix '$outdir/report/temp/temp.txt'");
			my $absolutely_path = abs_path($outdir);
			my $abs_table_path = "$absolutely_path/report/temp/temp.txt";
			#get the file encoding
			my $type = `$enca_path -L zh_CN $abs_table_path`;
			if($type =~ /UTF-8/ || $type =~ /utf-8/ ){
				#the file encoding is UTF-8
				system("$enca_path -L none -x utf-8 $abs_table_path");
				open TABLE, $abs_table_path or die $!;

			}elsif($type =~ /Unrecognized/){
				my $encode = "";
                        	$encode =  `file -bi $abs_table_path | sed -e 's/.*[ ]charset=//' |tr '[a-z]' '[A-Z'`;
                        	if($encode =~ /UTF-8/){
                                	#the file encoding is UTF-8
					open TABLE, $abs_table_path or die $!;
                        	}else{
                                	#the file encoding is GBK
					system ("iconv -f GBK -t utf8  '$outdir/report/temp/temp.txt' > '$outdir/report/temp/temp_1.txt'");
                                	open TABLE, "$outdir/report/temp/temp_1.txt" or die $!;
                        	}


			}else{
				#the file encoding is not UTF-8
	        	        system ("iconv -f GBK -t utf8  '$outdir/report/temp/temp.txt' > '$outdir/report/temp/temp_1.txt'");
				open TABLE, "$outdir/report/temp/temp_1.txt" or die $!;
			}

			# set the table head (the first line of the table)
	                my $table_head = <TABLE>;
			$table_head =~ s/\s+$//;
			
        	        my @td = (split /\t/, $table_head);
                	for(my $i = 0; $i < @td; $i++){
                        	if($table_format[$i][3]){
					if($table_format[$i][4] eq "left"){
                                        	$word_line .= "<th class = \"align_left\">";

                                 	}elsif($table_format[$i][4] eq "centre"){
                                        	$word_line .= "<th class = \"align_center\">";

	                                }elsif($table_format[$i][4] eq "right"){
        	                                $word_line .= "<th class = \"align_right\">";

                	                }elsif($table_format[$i][4] eq "auto"){
                        	                $word_line .= "<th class = \"align_left\">";

                                	}else{
                                        	$word_line .= "<th class = \"align_left\">";
                                 	}
                                	$word_line .= "<span class = \"key_sign_tb\">$td[$i]<div class = \"key_body\"><div class = \"key_content\">$table_format[$i][3]</div></div></span></th>";
                        	}else{
					if($table_format[$i][4] eq "left"){
                                                $word_line .= "<th class = \"align_left\">";

                                        }elsif($table_format[$i][4] eq "centre"){
                                                $word_line .= "<th class = \"align_center\">";

                                        }elsif($table_format[$i][4] eq "right"){
                                                $word_line .= "<th class = \"align_right\">";

                                        }elsif($table_format[$i][4] eq "auto"){
                                                $word_line .= "<th class = \"align_left\">";

                                        }else{
                                                $word_line .= "<th class = \"align_left\">";
                                        }
                                	$word_line .= "$td[$i]</th>";
                        	}
                	}
	                $word_line .= "</tr>\n";
			
			# read the table data
			while(<TABLE>){
	                        chomp;
				$sum++;
        	                if(($sum > $table_view)&&!($table_view eq "-1")){
                	                $Is_all_show = 0;
                        	        last;
	                        }

                	        $word_line .= "\t<tr>";
                        	my @td2 = (split /\t/);
	                        for(my $i = 0; $i < @td2; $i++){
        	                        my $align = "";
					#print $_;
                	                if($table_format[$i][4] eq "left"){
                        	                $word_line .= "<td class = \"align_left\">";

                                	}elsif($table_format[$i][4] eq "centre"){
                                        	$word_line .= "<td class = \"align_center\">";

	                                }elsif($table_format[$i][4] eq "right"){
        	                                $word_line .= "<td class = \"align_right\">";

                	                }elsif($table_format[$i][4] eq "auto"){
                        	                $word_line .= "<td class = \"align_left\">";

                                	}else{
                                        	$word_line .= "<td class = \"align_left\">";
	                                }

        	                        if($table_format[$i][1] eq "int"){
						my $temp_int = $td2[$i];
                                        	$temp_int =~ s/\s+$//;
                	                        my $temp = &digitize($temp_int);
                        	                $word_line .= "$temp</td>";

                                	}elsif($table_format[$i][1] eq "float"){
						my $temp = &decimal("float", $td2[$i], $table_format[$i][2]);
                                        	$word_line .= "$temp</td>";

	                                }elsif($table_format[$i][1] eq "string"){
        	                                $word_line .= "$td2[$i]</td>";

                	                }elsif($table_format[$i][1] eq "scientific"){
						my $temp = &decimal("scientific", $td2[$i], $table_format[$i][2]);
                        	                $word_line .= "$temp</td>";
                                	}elsif($table_format[$i][1] eq "url"){
						#don't show the download button;
						$show_download = 0;
						#the table data is the link: file = <url = aaaa/aaa/aaa.png; label = "show name">
						if($td2[$i] =~ /^\s*file\s*=\s*<(.*?)>\s*$/){
							my $temp2_content = $1;
							my $temp2_url = "";
							my $temp2_label = "";
							my $fig_path = "";
							#mark the content
							if($temp2_content =~ /;/){
								my @temp2 = (split /;/, $temp2_content);
								foreach(@temp2){
									if(!$_){
										next;
									}									
									#mark the url
									if($_ =~ /^\s*url\s*=\s*(.*?)\s*$/){
										$temp2_url = $1;
										$temp2_url =~ s/\s//g;
									}elsif($_ =~ /^\s*label\s*=\s*"(.*?)"\s*$/){
										#mark the label name
										$temp2_label = $1;			
									}
								}
							}
							#process the content
							if(-e "$data_path/$temp2_url"){
								my $fig_dir = $temp2_url;
								$fig_dir =~ /(.+\/)/;
						                $fig_dir = $1;
								#mkdir the folder
						                if(!(-d "$outdir/report/$fig_dir")){
						                        system("mkdir -p '$outdir/report/$fig_dir'");
                						}
								#process the figure.pdf					           	
						                if($temp2_url =~ /(.*?)\.pdf$/){
									#trantlate the pdf to png
									`$gs_path -dQUIET -dNOSAFER -r300 -dBATCH -sDEVICE=pngalpha -dNOPAUSE -dNOPROMPT -sOutputFile=$outdir/report/$1.png $data_path/$temp2_url`;
						                       # `convert -density 150 $data_path/$temp2_url $outdir/report/$1.png`;
						                        $fig_path = "$1.png";
                        					}elsif($temp2_url =~ /(.*?)\.tif$/){
									`$convert_path $data_path/$temp2_url $outdir/report/$1.gif`;
									$fig_path = "$1.gif";
								}else{
									#copy the figure
									if(!(-e "$outdir/report/$temp2_url")){
						                        	system("cp -rf '$data_path/$temp2_url' '$outdir/report/$fig_dir'");
									}
						                        $fig_path = $temp2_url;
						                }
							}else{
								print "The file $data_path/$temp2_url does not exist.\n";
							}
							#the website code
							$word_line .= "<a href = \"../../$fig_path\" target = \"_blank\">$temp2_label</a></td>";
						}else{
							#the wrong format, does not process
							$word_line .= "$td2[$i]</td>";
						}
					
					}

                        	}

                        	$word_line .= "</tr>\n";

                	}
			
			$word_line .= "\t</table>\n";
	                $word_line .= "\t</div>\n";
	
			# output the table footnote
        	        if($flag_footnote){
                	        foreach(@table_footnote){
					if(!$num_footnote){
						$num_footnote++;
                        	        	$word_line .= "\t<div class = \"p1_desc mgft20\">$_</div>\n";
					}else{
						$word_line .= "\t<div class = \"p1_desc\">$_</div>\n";
					}
	                        }
        	        }
			if($nowlabel eq $lastlabel){
                		$word_line .= "\t<br/>\n"

        		}
                	close TABLE;

	                system ("rm -rf '$outdir/report/temp/temp_1.txt'");
		}

	}else{
	#In the table, the "view = number" does not exist.
		my $sum = 0;
		my $Is_all_show = 1;
		
		#insert the <br> between the paragraph n the table
		if($exlabel eq "\@paragraph"){
                        $word_line .= "\t<br/>\n";
                }
		
		# the table path
		my $table_path = "$data_path/$table_file[0]";
                $table_path =~ s/\s//g;

                if(!(-e $table_path)){
                        print "The file $table_path does not exist.\n";
                        exit;
                }
		
		#count the lines fo the table
		open COUNT, "$table_path" or die $!;
		while(<COUNT>){
			chomp;
                        $sum++;
                        if($sum > 20){
                                $Is_all_show = 0;
                                last;
                        }

		}
		$sum = 0;
		close COUNT;
				
		# the table title
		if($flag_title){
			# show the download button
			if($show_download){
				# set the download is "Download"
                        	if($Is_all_show){
					if($arf_lan eq "cn" || $arf_lan eq "CN"){
						$word_line .= "\t<div class = \"p1 mgft25\"><b>$buttonTable$hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title&nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonDownload</a>)</div>\n";
					}else{
						$word_line .= "\t<div class = \"p1 mgft25\"><b>$buttonTable   $hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title&nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonDownload</a>)</div>\n";
					}
                       		}else{
					# set the download is "See All"
					if($arf_lan eq "cn" || $arf_lan eq "CN"){
						$word_line .= "\t<div class = \"p1 mgft25\"><b>$buttonTable$hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title&nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonSeeall</a>)</div>\n";
					}else{
						$word_line .= "\t<div class = \"p1 mgft25\"><b>$buttonTable    $hash_num_table{$type_label}</b>&nbsp;&nbsp;$table_title&nbsp;&nbsp;&nbsp;(<a href = \"../../$table_file[0]\">$buttonSeeall</a>)</div>\n";
					}
                                	$Is_all_show = 1;
                        	}
                	}
		}

		$word_line .= "\t<div class = \"align_center table-container\">\n";
		$word_line .= "\t<table>\n";
		$word_line .= "\t\t<tr>";
		
		
		my $table_dir = $table_file[0];
		$table_dir =~ /(.+\/)/;
		$table_dir = $1;

		if(!(-d "$outdir/report/$table_dir")){
			system("mkdir -p '$outdir/report/$table_dir'");
		}
		system("cp -rf $table_path '$outdir/report/$table_dir'");
		system ("cp -rf $table_path '$outdir/report/temp/temp.txt'");
		system ("dos2unix '$outdir/report/temp/temp.txt'");

		my $absolutely_path = abs_path($outdir);
		my $abs_table_path = "$absolutely_path/report/temp/temp.txt";
		#get the file encoding
		my $type = `$enca_path -L zh_CN $abs_table_path`;
		#$type =~ /Unrecognized/
                if($type =~ /UTF-8/ || $type =~ /utf-8/ ){
			# the file encoding is UTF-8
                        system("$enca_path -L none -x utf-8 $abs_table_path");
                        open TABLE, $abs_table_path or die $!;

		}elsif($type =~ /Unrecognized/){
			my $encode = "";
                        $encode =  `file -bi $abs_table_path | sed -e 's/.*[ ]charset=//' |tr '[a-z]' '[A-Z]'`;
                        if($encode =~ /UTF-8/){
                                #the file encoding is UTF-8
				open TABLE, $abs_table_path or die $!;
                        }else{
                                #the file encoding is GBK
				system ("iconv -f GBK -t utf8  '$outdir/report/temp/temp.txt' > '$outdir/report/temp/temp_1.txt'");
                        	open TABLE, "$outdir/report/temp/temp_1.txt" or die $!;
                        }

                }else{	
			#the file encoding is not UTF-8
                        system ("iconv -f GBK -t utf8  '$outdir/report/temp/temp.txt' > '$outdir/report/temp/temp_1.txt'");
                        open TABLE, "$outdir/report/temp/temp_1.txt" or die $!;
                }

		# read the first line of the table
		my $table_head = <TABLE>;
		$table_head =~ s/\s+$//;
		my @td = (split /\t/, $table_head);
		for(my $i = 0; $i < @td; $i++){
			if($table_format[$i][3]){
				if($table_format[$i][4] eq "left"){
                                        $word_line .= "<th class = \"align_left\">";

                                 }elsif($table_format[$i][4] eq "centre"){
                                        $word_line .= "<th class = \"align_center\">";

                                 }elsif($table_format[$i][4] eq "right"){
                                        $word_line .= "<th class = \"align_right\">";

                                 }elsif($table_format[$i][4] eq "auto"){
                                        $word_line .= "<th class = \"align_left\">";

                                 }else{
                                        $word_line .= "<th class = \"align_left\">";
                                 }	
				$word_line .= "<span class = \"key_sign_tb\">$td[$i]<div class = \"key_body\"><div class = \"key_content\">$table_format[$i][3]</div></div></span></th>";
			}else{
				if($table_format[$i][4] eq "left"){
                                        $word_line .= "<th class = \"align_left\">";

                                }elsif($table_format[$i][4] eq "centre"){
                                        $word_line .= "<th class = \"align_center\">";

                                }elsif($table_format[$i][4] eq "right"){
                                        $word_line .= "<th class = \"align_right\">";

                                }elsif($table_format[$i][4] eq "auto"){
                                        $word_line .= "<th class = \"align_left\">";

                             	}else{
                                        $word_line .= "<th class = \"align_left\">";
                                }
				$word_line .= "$td[$i]</th>";
			}	
		}
		$word_line .= "</tr>\n";


		# read the table data
		while(my $tableDate = <TABLE>){
			chomp $tableDate;
			$sum++;
			if($sum > 20){
				$Is_all_show = 0;
				last;
			}
			
			$word_line .= "\t\t<tr>";
			$tableDate =~ s/\s+$//;
			my @td2 = (split /\t/, $tableDate);
			for(my $i = 0; $i < @td2; $i++){
				my $align = "";
				if(!defined($table_format[$i][4])){
					next;
				}
				if(!defined($table_format[$i][1])){
					next;
				}
				if($table_format[$i][4] eq "left"){	
					$word_line .= "<td class = \"align_left\">";

				}elsif($table_format[$i][4] eq "centre"){
					$word_line .= "<td class = \"align_center\">";

				}elsif($table_format[$i][4] eq "right"){
					$word_line .= "<td class = \"align_right\">";

				}elsif($table_format[$i][4] eq "auto"){
					$word_line .= "<td class = \"align_left\">";

				}else{
					$word_line .= "<td class = \"align_left\">";
				}				
				
				if($table_format[$i][1] eq "int"){
					my $temp_int = $td2[$i];
					$temp_int =~ s/\s+$//;
					my $temp = &digitize($temp_int);
					$word_line .= "$temp</td>";

				}elsif($table_format[$i][1] eq "float"){
					my $temp = &decimal("float", $td2[$i], $table_format[$i][2]);
                                        $word_line .= "$temp</td>";

				}elsif($table_format[$i][1] eq "string"){
					$word_line .= "$td2[$i]</td>";

				}elsif($table_format[$i][1]eq "scientific"){
					my $temp = &decimal("scientific", $td2[$i], $table_format[$i][2]);
                                        $word_line .= "$temp</td>";

				}elsif($table_format[$i][1] eq "url"){
					$show_download = 0;
                                        #the table data is the link: file = <url = aaaa/aaa/aaa.png; label = "show name">
                                	if($td2[$i] =~ /^\s*file\s*=\s*<(.*?)>\s*$/){
                                        	my $temp2_content = $1;
                                                my $temp2_url = "";
                                                my $temp2_label = "";
                                                my $fig_path = "";
                                                #mark the content
                                                if($temp2_content =~ /;/){
                                                my @temp2 = (split /;/, $temp2_content);
                                                	foreach(@temp2){
                                                        	if(!$_){
                                                                        next;
                                                                }
                                                                #mark the url
                                                                if($_ =~ /^\s*url\s*=\s*(.*?)\s*$/){
                                                                        $temp2_url = $1;
                                                                        $temp2_url =~ s/\s//g;
                                                                }elsif($_ =~ /^\s*label\s*=\s*"(.*?)"\s*$/){
                                                                        #mark the label name
                                                                        $temp2_label = $1;
                                                                }
                                                        }
                                                }
                                                #process the content
                                                if(-e "$data_path/$temp2_url"){
                                                	my $fig_dir = $temp2_url;
                                                        $fig_dir =~ /(.+\/)/;
                                                        $fig_dir = $1;
                                                        #mkdir the folder
                                                        if(!(-d "$outdir/report/$fig_dir")){
                                                        	system("mkdir -p '$outdir/report/$fig_dir'");
                                                        }
                                                        #process the figure.pdf
                                                        if($temp2_url =~ /(.*?)\.pdf$/){
                                                        #trantlate the pdf to png
								`$gs_path -dQUIET -dNOSAFER -r300 -dBATCH -sDEVICE=pngalpha -dNOPAUSE -dNOPROMPT -sOutputFile=$outdir/report/$1.png $data_path/$temp2_url`;
                                        	       #         `convert -density 150 $data_path/$temp2_url $outdir/report/$1.png`;
                                                                $fig_path = "$1.png";
							}elsif($temp2_url =~ /(.*?)\.tif$/){
								`$convert_path $data_path/$temp2_url $outdir/report/$1.gif`;
								$fig_path = "$1.gif";
                                                        }else{
                                                                #copy the figure
								if(!(-e "$outdir/report/$temp2_url")){
                                                               		system("cp -rf '$data_path/$temp2_url' '$outdir/report/$fig_dir'");
								}
                                                                $fig_path = $temp2_url;
                                                        }
                                                }else{
                                                        print "The file $data_path/$temp2_url does not exist.\n";
                                                }
                                                #the website code
                                                $word_line .= "<a href = \"../../$fig_path\" target = \"_blank\">$temp2_label</a></td>";
                                        }else{
                                                #the wrong format, does not process
                                                $word_line .= "$td2[$i]</td>";
		                        }                                      
				}
			}			
			
			$word_line .= "</tr>\n";
			
		}
		
		$word_line .= "\t</table>\n";
		$word_line .= "\t</div>\n";
		
		# output the table footnote
		if($flag_footnote){
			foreach(@table_footnote){
				if(!$num_footnote){
					$num_footnote++;
					$word_line .= "\t<div class = \"p1_desc mgft20\">$_</div>\n";
				}else{
					$word_line .= "\t<div class = \"p1_desc\">$_</div>\n";
				}
			}
		}
		if($nowlabel eq $lastlabel){
        	        $word_line .= "\t<br/>\n"
	
        	}
		close TABLE;

		system ("rm -rf '$outdir/report/temp/temp_1.txt'");
		
	}
	$word_line .= "\n\n\n";	
	push @website_content,[ "0", $type_label, $now_title, $word_line ];
	if($type_label eq "Results"){
		# if the table belong to Results.html, copy the table to Tables.html
		push @website_content,[ "0", "Tables", $now_title, $word_line ];
		if($table_title =~ /。$/){
                        $table_title =~ s/。$//;

                }elsif($table_title =~ /.\s*$/){
                        $table_title =~ s/\.\s*$//;

                }

		push @left_menu, ["Tables", "table$hash_num_table{$type_label}", "$hash_num_table{$type_label} $table_title"];
	}
	push @number_table, [$type_label, $now_title, $table_num, $hash_num_table{$type_label}];
	

} 

sub figure_process(){
	my @content = @_;
	my $fig_num = "";
	my $num_file = 0;
	my $fig_title = "";
	my @fig_file;
	my $fig_desc = "";
	my @fig_size;
	my $flag_title = 0;
	my $flag_desc = 0;
    my $flag_echarts = 0;
    my $echarts_type = "";
	$word_line = "";
	$hash_num_figure{$type_label}++;
	

	#get the figure content from the arf
	foreach(@content){
		if(!$_){
                        next;
                }

		if($_ =~ /^number\s*?=\s*?(.*?)\s*?$/){
			$fig_num = $1;
       	                #remove the space
                        $fig_num =~ s/\s//g;
			

		}elsif($_ =~ /^title\s*?=\s*?"(.*?)"\s*?$/){
			$flag_title = 1;
			$fig_title = $1;

		}elsif($_ =~ /^file\s*?=\s*?<(.*?)>\s*?$/){
			$num_file++;
			my $temp_file = $1;
			my $temp_url = "";
			my $temp_label = "";
			if($temp_file =~ /;/){
				my @file = (split /;/, $temp_file);
				foreach(@file){
					if($_ =~ /^\s*?url\s*?=\s*?(.*?)\s*?$/){
						$temp_url = $1;
						$temp_url =~ s/\s//g;
		
					}
					if($_ =~ /^\s*?label\s*?=\s*?"(.*?)"\s*?$/){
						$temp_label = $1;

					}
				}
			}else{
				if($temp_file =~ /^\s*?url\s*?=\s*?(.*?)\s*?$/){
					$temp_url = $1;
					$temp_url =~ s/\s//g;
				}
			}
			push @fig_file, [$temp_url, $temp_label];

	
		}elsif($_ =~ /^isEcharts\s*=\s*?"(.*?)"\s*?$/){
            $flag_echarts = 1;
            $echarts_type = $1;
        
        }elsif($_ =~ /^desc\s*?=\s*?"(.*?)"\s*?$/){
			$flag_desc = 1;
			$fig_desc = $1;


		}elsif($_ =~ /^size\s*?=\s*?<(.*?)>\s*?$/){
			my $temp_size = $1;
			my $temp_width = "";
			my $temp_height = "";
			if($temp_size =~ /;/){
				my @size = (split /;/, $temp_size);
				foreach(@size){
					if($_ =~ /\s*?width\s*?=\s*?(\d*?)\s*?$/){
						$temp_width = $1;

					}elsif($_ =~ /^\s*?height\s*?=\s*?(\d*?)\s*?$/){
						$temp_height = $1;

					}
				}	
			}else{
				if($temp_size =~ /\s*?width\s*?=\s*?(\d*?)\s*?$/){
                                	$temp_width = $1;

                        	}elsif($temp_size =~ /^\s*?height\s*?=\s*?(\d*?)\s*?$/){
                                        $temp_height = $1;

                                }
			}

			push @fig_size, [$temp_width, $temp_height];
			

		}
	}



	#####	translate into the website code		#####
     #####   not echarts                         #####
    if(!$flag_echarts){
        if($num_file eq 1){
            #only one figure
            my $fig_path = "";
            my $fig_dir = $fig_file[0][0];
            $fig_dir =~ /(.+\/)/;
            $fig_dir = $1;
            # create the folder 
            if(!(-d "$outdir/report/$fig_dir")){
                            system("mkdir -p '$outdir/report/$fig_dir'");
                    }


            if(-e "$data_path/$fig_file[0][0]"){
                if($fig_file[0][0] =~ /(.*?)\.pdf$/){
                     `$gs_path -dQUIET -dNOSAFER -r300 -dBATCH -sDEVICE=pngalpha -dNOPAUSE -dNOPROMPT -sOutputFile=$outdir/report/$1.png $data_path/$fig_file[0][0]`;
                #	`convert -density 150 $data_path/$fig_file[0][0] $outdir/report/$1.png`;
                    $fig_path = "$1.png";
                }elsif($fig_file[0][0] =~ /(.*?)\.tif$/){
                    #convert tif -> gif
                    `$convert_path $data_path/$fig_file[0][0] $outdir/report/$1.gif`;
                    $fig_path = "$1.gif";
                }else{
    #				system("chmod 755 '$data_path/$fig_file[0][0]'");

                    if(!(-e "'$outdir/report/$fig_file[0][0]")){
                                system("cp -rf '$data_path/$fig_file[0][0]' '$outdir/report/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }
            }else{
                print "The file $fig_file[0][0] does not exist.\n";

            }

            my $size = "";
            if($fig_size[0][0]){
                $size .= "   width = \"$fig_size[0][0]\"";
            }
            if($fig_size[0][1]){
                $size .= "   height = \"$fig_size[0][1]\"";
            }
            #only one figure
            $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
            $word_line .= "\t<div class = \"mgt\"><a href = \"../../$fig_path\" target = \"_blank\"><img src= \"../../$fig_path\" $size/></a></div>\n";
            if($flag_title){
                # the figure title exists.
                if($flag_desc){
                    # the figure desc exits
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        # add "." between figure title and figure desc.
                                            if(!($fig_title =~ /^(.*?)。\s*$/)){
                                            $fig_title .= "。";
                                            }
                                    }else{
                                            if(!($fig_title =~ /^(.*?)\.\s*$/)){
                                            $fig_title .= ".";
                                            }
                                    }
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        # the website page content
                        $word_line .= "\t<div class = \"p1 img_title\"><centet><b>$buttonFigure$hash_num_figure{$type_label}&nbsp;&nbsp;$fig_title&nbsp;&nbsp;&nbsp;</b></center></div><div class = \"p1 img_title\">$fig_desc</div>\n";
                    }else{
                        $word_line .= "\t<div class = \"p1 img_title\"><center><b>$buttonFigure $hash_num_figure{$type_label}&nbsp;&nbsp;$fig_title&nbsp;&nbsp;&nbsp;</b></center></div><div class = \"p1 img_title\">$fig_desc</div>\n";
                    }
                }else{
                    # the figure desc does not exists
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        # the website page content
                        $word_line .= "\t<div class = \"align_center img_title\"><center><b>$buttonFigure$hash_num_figure{$type_label}</b>&nbsp;&nbsp;$fig_title</center></div>\n";
                    }else{
                        $word_line .= "\t<div class = \"align_center img_title\"><center><b>$buttonFigure $hash_num_figure{$type_label}</b>&nbsp;&nbsp;$fig_title&nbsp;&nbsp;&nbsp;</center></div>\n";
                    }
                }
            }
        }elsif($num_file > 1){
        #more than 2 figures
            my @fig_path;
            for my $i (0 .. $#fig_file){
                my $fig_dir = $fig_file[$i][0];
                        $fig_dir =~ /(.+\/)/;
                        $fig_dir = $1;
                        if(!(-d "$outdir/report/$fig_dir")){
                                system("mkdir -p '$outdir/report/$fig_dir'");
                        }
                if(-e "$data_path/$fig_file[$i][0]"){
                    if($fig_file[$i][0] =~ /(.*?)\.pdf$/){
                         `$gs_path -dQUIET -dNOSAFER -r300 -dBATCH -sDEVICE=pngalpha -dNOPAUSE -dNOPROMPT -sOutputFile=$outdir/report/$1.png $data_path/$fig_file[$i][0]`;
                    #	`convert -density 150 $data_path/$fig_file[$i][0] $outdir/report/$1.png`;
                        push @fig_path,["$1.png", $fig_file[$i][1]];
                    }elsif($fig_file[$i][0] =~ /(.*?)\.tif$/){
                        `$convert_path $data_path/$fig_file[$i][0] $outdir/report/$1.gif`;
                        push @fig_path,["$1.gif", $fig_file[$i][1]];

                    }else{
    #					system("chmod 755 '$data_path/$fig_file[$i][0]'");
                        if(!(-e "$outdir/report/$fig_file[$i][0]")){
                                    system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                    }
                }else{
                    print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                }
            }

            my $size = "";
            my $file_list = "";
            if($fig_size[0][0]){
                $size .= "  width = \"$fig_size[0][0]\"";
            }
            if($fig_size[0][1]){
                $size .= "  height = \"$fig_size[0][1]\""
            }	
            for my $i (0 .. $#fig_path){
                $file_list .= "\t\t\t\t\t<li href = \"../../$fig_path[$i][0]\">$fig_path[$i][1]</li>\n";
            }

            $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
            $word_line .= "\t<div class = \"albumSlider lane\">\n";
            $word_line .= "\t<div class=\"selectImg\">\n";
            $word_line .= "\t\t<div class=\"fright\">\n";
            $word_line .= "\t\t\t<input type=\"text\" value=\"\" />\n";
            $word_line .= "\t\t\t<input type=\"button\" value=\"$buttonFigureSearch\" class=\"confirm\" />\n";
            $word_line .= "\t\t\t<input type=\"button\" value=\"$buttonFigureShow\" class=\"showall\" />\n";
            $word_line .= "\t\t</div>\n";
            $word_line .= "\t</div>\n";
            $word_line .= "\t\t<div class = \"fullview\" alt = \"1\"><a href = \"../../$fig_path[0][0]\"><img src = \"../../$fig_path[0][0]\" alt = \"\"/></a></div>\n";
            $word_line .= "\t\t<div class = \"slider\">\n";
            $word_line .= "\t\t\t<div class = \"button movebackward\" title = \"$buttonScrollup\"></div>\n";
            $word_line .= "\t\t\t\t<div class = \"imglistwrap\">\n";
            $word_line .= "\t\t\t\t\t<ul class = \"imglist\">\n";

            $word_line .= $file_list;

            $word_line .= "\t\t\t\t\t</ul>\n";
            $word_line .= "\t\t\t\t</div>\n";
            $word_line .= "\t\t\t<div class = \"button1 moveforward\" title = \"$buttonScrolldown\"></div>\n";
            $word_line .= "\t\t</div>\n";
            $word_line .= "\t</div>\n\n";


            if($flag_title){
                # the title exists
                if($flag_desc){
                    # the figure desc exists
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        # add "." between figure title and figure desc
                        if(!($fig_title =~ /^(.*?)。\s*$/)){
                                            $fig_title .= "。";
                                            }
                    }else{
                        if(!($fig_title =~ /^(.*?)\.\s*$/)){
                                            $fig_title .= ".";
                                        }
                    }
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        $word_line .= "\t<div class = \"p1 img_title\"><center><b>$buttonFigure$hash_num_figure{$type_label}&nbsp;&nbsp;$fig_title</b></center></div>\t<div class = \"p1 img_title\">$fig_desc</div>\n\n\n";
                    }else{
                        $word_line .= "\t<div class = \"p1 img_title\"><center><b>$buttonFigure $hash_num_figure{$type_label}&nbsp;&nbsp;$fig_title</b></center></div>\t<div class = \"p1 img_title\">$fig_desc</div>\n\n\n";
                    }
                }else{
                    # the figure desc does not exists
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        $word_line .= "\t<div class = \"align_left img_title\"><center><b>$buttonFigure$hash_num_figure{$type_label}</b>&nbsp&nbsp;;$fig_title</center></div>\n\n\n";
                    }else{
                        $word_line .= "\t<div class = \"align_left img_title\"><b>$buttonFigure $hash_num_figure{$type_label}</b>&nbsp&nbsp;;$fig_title</center></div>\n\n\n";
                    }
                }
            }
        }
    }else{
    if($echarts_type eq "Distribution of base composition"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\" id=\"BaseCompisition$hash_num_figure{$type_label}\" style=\"width: 700px;height:400px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'BaseCompisition$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar rawdata=[];\n";
                $word_line .="\t\tvar xName=\"\";\n";
                $word_line .="\t\tvar yName=\"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\trawdata = info[\"data\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\t\ttrigger: \'axis\',\n";
                $word_line .="\t\t\t\tformatter: function(data) {\n";
                $word_line .="\t\t\t\t\treturn 'Position: '+ data[0].value[0] + '<br />'\n";
                $word_line .="\t\t\t\t\t+ 'A'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[0].color+'\"></span> :'+data[0].value[1]+'%<br />'\n";
                $word_line .="\t\t\t\t\t+ 'C'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[1].color+'\"></span> :' +data[1].value[1]+'%<br />'\n";
                $word_line .="\t\t\t\t\t + 'G'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[2].color+'\"></span> :'+data[2].value[1]+'%<br />'\n";
                $word_line .="\t\t\t\t\t+ 'T'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[3].color+'\"></span> :'+data[3].value[1]+'%<br />'\n";
                $word_line .="\t\t\t\t\t+ 'N'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[4].color+'\"></span> :'+data[4].value[1]+'%<br />';\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend: {\n";
                $word_line .="\t\t\t\tdata:[\'A\',\'C\',\'G\',\'T\',\'N\'],\n";
                $word_line .="\t\t\t\ttop:28\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: {\n";
                #$word_line .="\t\t\t\tname:  \'Position along reads\',\n";
                $word_line .="\t\t\t\tname:  xName,\n";
                $word_line .="\t\t\t\tnameLocation: \'middle\',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\ttype:'value',\n";
                $word_line .="\t\t\t\tsplitNumber:5,\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tdata:rawdata\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis: {\n";
                #$word_line .="\t\t\t\tname:\'% Percentage\',\n";
                $word_line .="\t\t\t\tname: yName,\n";
                $word_line .="\t\t\t\tnameLocation: \'middle\',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";           
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: \'value\',\n";
                $word_line .="\t\t\t\tsplitNumber:8,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel : {\n";
                $word_line .="\t\t\t\t\tformatter: function (value, index) {\n";
                $word_line .="\t\t\t\t\t\tvar text = value + \" %\";\n";
                $word_line .="\t\t\t\t\t\treturn text;\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tseries: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname: \'A\',\n";
                $word_line .="\t\t\t\ttype: \'line\',\n";
                $word_line .="\t\t\t\tsymbol: 'none',\n";
                $word_line .="\t\t\t\tdata: rawdata.map(function (array) {\n";
                $word_line .="\t\t\t\t\treturn [array[0],array[1]];\n";
                $word_line .="\t\t\t\t})\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname: \'C\',\n";
                $word_line .="\t\t\t\ttype: \'line\',\n";
                $word_line .="\t\t\t\tsymbol: 'none',\n";
                $word_line .="\t\t\t\tdata: rawdata.map(function (array) {\n";
                $word_line .="\t\t\t\t\treturn [array[0],array[2]];\n";
                $word_line .="\t\t\t\t})\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname: \'G\',\n";
                $word_line .="\t\t\t\ttype: \'line\',\n";
                $word_line .="\t\t\t\tsymbol: 'none',\n";
                $word_line .="\t\t\t\tdata: rawdata.map(function (array) {\n";
                $word_line .="\t\t\t\t\treturn [array[0],array[3]];\n";
                $word_line .="\t\t\t\t})\n";
                $word_line .="\t\t\t},\n";   
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname: \'T\',\n";
                $word_line .="\t\t\t\ttype: \'line\',\n";
                $word_line .="\t\t\t\tsymbol: 'none',\n";
                $word_line .="\t\t\t\tdata: rawdata.map(function (array) {\n";
                $word_line .="\t\t\t\t\treturn [array[0],array[4]];\n";
                $word_line .="\t\t\t\t})\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname: \'N\',\n";
                $word_line .="\t\t\t\ttype: \'line\',\n";
                $word_line .="\t\t\t\tsymbol: 'none',\n";
                $word_line .="\t\t\t\tdata: rawdata.map(function (array) {\n";
                $word_line .="\t\t\t\t\treturn [array[0],array[5]];\n";
                $word_line .="\t\t\t\t})\n";
                $word_line .="\t\t\t}\n";                  
                $word_line .="\t\t\t]\n";    
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"BaseCompisition$hash_num_figure{$type_label}\" style=\"width: 700px;height:400px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'BaseCompisition$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tfunction tArray(array){\n";
                $word_line .="\t\t\tvar tarray=[];\n";
                $word_line .="\t\t\tfor(var j=0;j<array[0].length;j++){\n";
                $word_line .="\t\t\t\ttarray[j]=[];\n";
                $word_line .="\t\t\t\tfor(var i=0;i<array.length;i++){\n";
                $word_line .="\t\t\t\t\ttarray[j][i]=array[i][j];\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\treturn tarray;\n";
                $word_line .="\t\t};\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar rawdata${j}=[];\n";
                    $word_line .="\tvar xName${j}=\"\";\n";
                    $word_line .="\tvar yName${j}=\"\";\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\trawdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar data${j} = tArray(rawdata${j});\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tbaseOption:{\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\taxisType: \'category\',\n";
                $word_line .="\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\tcontrolStyle: {\n";
                $word_line .="\t\t\t\t\tposition: \'left\',\n";
                $word_line .="\t\t\t\t\titemSize:15\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\tnumber:10\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\t\ttrigger: \'axis\',\n";
                $word_line .="\t\t\t\tformatter: function(data) {\n";
                $word_line .="\t\t\t\t\treturn 'Position: '+ data[0].value[0] + '<br />'\n";
                $word_line .="\t\t\t\t\t+ 'A'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[0].color+'\"></span> :'+data[0].value[1]+'%<br />'\n";
                $word_line .="\t\t\t\t\t+ 'C'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[1].color+'\"></span> :' +data[1].value[1]+'%<br />'\n";
                $word_line .="\t\t\t\t\t + 'G'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[2].color+'\"></span> :'+data[2].value[1]+'%<br />'\n";
                $word_line .="\t\t\t\t\t+ 'T'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[3].color+'\"></span> :'+data[3].value[1]+'%<br />'\n";
                $word_line .="\t\t\t\t\t+ 'N'+ '<span style=\"display: inline-block;height: 9px; width: 9px;border-radius: 50%;background-color:'+data[4].color+'\"></span> :'+data[4].value[1]+'%<br />';\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend: {\n";
                $word_line .="\t\t\t\tdata:[\'A\',\'C\',\'G\',\'T\',\'N\'],\n";
                $word_line .="\t\t\t\ttop:28\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\tname:  \'Position along reads\',\n";
                $word_line .="\t\t\t\tnameLocation: \'middle\',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\ttype:'value',\n";
                $word_line .="\t\t\t\tsplitNumber:5,\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tdata:data1[0]\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\tname:\'% Percentage\',\n";
                $word_line .="\t\t\t\tnameLocation: \'middle\',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";           
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: \'value\',\n";
                $word_line .="\t\t\t\tsplitNumber:8,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel : {\n";
                $word_line .="\t\t\t\t\tformatter: function (value, index) {\n";
                $word_line .="\t\t\t\t\t\tvar text = value + \" %\";\n";
                $word_line .="\t\t\t\t\t\treturn text;\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t},\n";
                $word_line .="\t\t\toptions: [\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                   # $word_line .="\t\t\ttitle: {text: \'$fig_file[$i][1] Base Composition of Raw Data\'},\n";
                    $word_line .="\t\t\tyAxis: {name:yName${j}},\n";
                    $word_line .="\t\t\txAxis: {name:xName${j}},\n";
                    $word_line .="\t\t\t\n";
                    $word_line .="\t\t\tseries: [\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname: \'A\',\n";
                    $word_line .="\t\t\t\ttype: \'line\',\n";
                    $word_line .="\t\t\t\tsymbol: 'none',\n";
                    $word_line .="\t\t\t\tdata: rawdata${j}.map(function (array) {\n";
                    $word_line .="\t\t\t\t\treturn [array[0],array[1]];\n";
                    $word_line .="\t\t\t\t})\n";
                    $word_line .="\t\t\t},\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname: \'C\',\n";
                    $word_line .="\t\t\t\ttype: \'line\',\n";
                    $word_line .="\t\t\t\tsymbol: 'none',\n";
                    $word_line .="\t\t\t\tdata: rawdata${j}.map(function (array) {\n";
                    $word_line .="\t\t\t\t\treturn [array[0],array[2]];\n";
                    $word_line .="\t\t\t\t})\n";
                    $word_line .="\t\t\t},\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname: \'G\',\n";
                    $word_line .="\t\t\t\ttype: \'line\',\n";
                    $word_line .="\t\t\t\tsymbol: 'none',\n";
                    $word_line .="\t\t\t\tdata: rawdata${j}.map(function (array) {\n";
                    $word_line .="\t\t\t\t\treturn [array[0],array[3]];\n";
                    $word_line .="\t\t\t\t})\n";
                    $word_line .="\t\t\t},\n";   
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname: \'T\',\n";
                    $word_line .="\t\t\t\ttype: \'line\',\n";
                    $word_line .="\t\t\t\tsymbol: 'none',\n";
                    $word_line .="\t\t\t\tdata: rawdata${j}.map(function (array) {\n";
                    $word_line .="\t\t\t\t\treturn [array[0],array[4]];\n";
                    $word_line .="\t\t\t\t})\n";
                    $word_line .="\t\t\t},\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname: \'N\',\n";
                    $word_line .="\t\t\t\ttype: \'line\',\n";
                    $word_line .="\t\t\t\tsymbol: 'none',\n";
                    $word_line .="\t\t\t\tdata: rawdata${j}.map(function (array) {\n";
                    $word_line .="\t\t\t\t\treturn [array[0],array[5]];\n";
                    $word_line .="\t\t\t\t})\n";
                    $word_line .="\t\t\t}\n";                  
                    $word_line .="\t\t\t]\n";                
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }
        }
        elsif($echarts_type eq "Distribution of base quality"){
            if($num_file eq 1){
                 my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"BaseQual$hash_num_figure{$type_label}\" style=\"width: 700px;height:400px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'BaseQual$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\t\tvar x=[];\n";            
                $word_line .="\t\t\tvar y=[];\n";            
                $word_line .="\t\tfunction mapdata(array){\n";
                $word_line .="\t\t\tvar data=[];\n";
                $word_line .="\t\t\tfor(var i=0;i<array.length;i++){\n";
                $word_line .="\t\t\t\tx[i]=array[i][0];\n";
                $word_line .="\t\t\t\tvar total=0;\n";
                $word_line .="\t\t\t\tfor (var j=1;j<array[0].length-6;j++){\n";
                $word_line .="\t\t\t\t\ttotal += array[i][j];\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t\tfor (var j=1;j<array[0].length-6;j++){\n";
                $word_line .="\t\t\t\t\tdata.push([i,j-1,Math.round(array[i][j]/total*10000)/100]);\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\treturn data;\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tvar rawdata=[];\n";
                $word_line .="\t\tvar xName=\"\";\n";
                $word_line .="\t\tvar yName=\"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\trawdata = info[\"data\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar data = mapdata(rawdata);\n";
                $word_line .="\t\tfor(var j=0;j<rawdata[0].length;j++){y[j]=j;}\n";
                $word_line .="\t\tfor(var i=0;i<rawdata.length;i++){x[i]=rawdata[i][0];}\n";
                $word_line .="\t\tvar markline={};\n";
                $word_line .="\t\tmarkline={symbol: [\'none\', \'none\'],
    label:{normal:{show:false}},data: [{xAxis:50}],lineStyle: {normal:{color: \"#333\"}}};\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttooltip:{\n";
                $word_line .="\t\t\t\tformatter: function(params) {\n";
                $word_line .="\t\t\t\t\treturn \'Position: \'+ (params.data[0]+1) + \'<br />\' +'Quality: \'+ params.data[1] + \'<br />\'+\'Percentage: \'+ params.data[2] + \'%<br />\';\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                #$word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{pixelRatio:3}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";            
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\ttype: \'value\',\n";
                $word_line .="\t\t\t\tdata: x,\n";
                $word_line .="\t\t\t\tmin:0,\n";
                $word_line .="\t\t\t\tmax:x[x.length-1]+1,\n";
                #$word_line .="\t\t\t\tname:  'Position along reads',\n";
                $word_line .="\t\t\t\tname:  xName,\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:30\n";
                $word_line .="\t\t\t},\n";           
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\ttype: \'category\',\n";
                $word_line .="\t\t\t\tdata: y,\n";
                $word_line .="\t\t\t\tmin:0,\n";
                $word_line .="\t\t\t\tmax:100,\n";
                $word_line .="\t\t\t\tname:yName,\n";
               # $word_line .="\t\t\t\tname:\'Quality Score\',\n";
                $word_line .="\t\t\t\tnameLocation: \'middle\',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false,\n";
                $word_line .="\t\t\t\t\tinterval:4\n";
                $word_line .="\t\t\t\t},\n";            
                $word_line .="\t\t\t\taxisLabel : {\n";
                $word_line .="\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tinterval:4\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\tinside:true,\n";
                $word_line .="\t\t\t\tlength:4\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tvisualMap: {\n";
                $word_line .="\t\t\t\tmin:0,\n";
                $word_line .="\t\t\t\tmax:100,\n";
                $word_line .="\t\t\t\tshow:true,\n";
                $word_line .="\t\t\t\tcolor:[\'#000000\',\'#2b0000\',\'#560000\',\'#800000\',\'#a00000\',\'#ff0000\',\'#ff8000\',\'#ffff00\',\'#7fff00\', \'#00ff00\',\'#ffffff\'],\n";
                $word_line .="\t\t\t\tcalculable: true,\n";
                $word_line .="\t\t\t\torient: 'vertical',\n";
                $word_line .="\t\t\t\tleft: 'right',\n";
                $word_line .="\t\t\t\tbottom: 'center'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tseries: [{\n";
                $word_line .="\t\t\t\ttype: 'heatmap',\n";
                $word_line .="\t\t\t\tlayout: 'none',\n";
                $word_line .="\t\t\t\tname: \"Quality\",\n";
                $word_line .="\t\t\t\tcoordinateSystem: 'cartesian2d',\n";
                $word_line .="\t\t\t\tdata: data,\n";
                $word_line .="\t\t\t\tmarkLine: markline,\n";
                $word_line .="\t\t\t\titemStyle: {\n";
                $word_line .="\t\t\t\t\temphasis: {\n";
                $word_line .="\t\t\t\t\t\tshadowBlur: 10,\n";
                $word_line .="\t\t\t\t\t\tshadowColor: 'rgba(0, 0, 0, 0.5)'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"BaseQual$hash_num_figure{$type_label}\" style=\"width: 700px;height:400px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'BaseQual$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\tvar x=[];\n";            
                $word_line .="\t\t\tvar y=[];\n";            
                $word_line .="\t\tfunction mapdata(array){\n";
                $word_line .="\t\t\tvar data=[];\n";
                $word_line .="\t\t\tfor(var i=0;i<array.length;i++){\n";
                $word_line .="\t\t\t\tx[i]=array[i][0];\n";
                $word_line .="\t\t\t\tvar total=0;\n";
                $word_line .="\t\t\t\tfor (var j=1;j<array[0].length-6;j++){\n";
                $word_line .="\t\t\t\t\ttotal += array[i][j];\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t\tfor (var j=1;j<array[0].length-6;j++){\n";
                $word_line .="\t\t\t\t\tdata.push([i,j-1,Math.round(array[i][j]/total*10000)/100]);\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\treturn data;\n";
                $word_line .="\t\t};\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar rawdata${j}=[];\n";
                    $word_line .="\tvar yName${j}=[];\n";
                    $word_line .="\tvar xName${j}=[];\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\trawdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar data${j} = mapdata(rawdata${j});\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\t\tfor(var j=0;j<rawdata1[0].length;j++){y[j]=j;}\n";
                $word_line .="\t\t\tfor(var i=0;i<rawdata1.length;i++){x[i]=rawdata1[i][0];}\n";
                $word_line .="\t\t\tvar markline={};\n";
                $word_line .="\t\t\tmarkline={symbol: [\'none\', \'none\'],
    label:{normal:{show:false}},data: [{xAxis:50}],lineStyle: {normal:{color: \"#333\"}}};\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tbaseOption: {\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\taxisType: \'category\',\n";
                $word_line .="\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\tcontrolStyle: {\n";
                $word_line .="\t\t\t\t\tposition: \'left\',\n";
                $word_line .="\t\t\t\t\titemSize:15\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\tnumber:10\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";            
                $word_line .="\t\t\ttooltip:{\n";
                $word_line .="\t\t\t\tformatter: function(params) {\n";
                $word_line .="\t\t\t\t\treturn \'Position: \'+ (params.data[0]+1) + \'<br />\' +'Quality: \'+ params.data[1] + \'<br />\'+\'Percentage: \'+ params.data[2] + \'%<br />\';\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                #$word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{pixelRatio:3}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";            
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\ttype: \'value\',\n";
                $word_line .="\t\t\t\tdata: x,\n";
                $word_line .="\t\t\t\tmin:0,\n";
                $word_line .="\t\t\t\tmax:x[x.length-1]+1,\n";
                $word_line .="\t\t\t\tname:  'Position along reads',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:30\n";
                $word_line .="\t\t\t},\n";           
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\ttype: \'category\',\n";
                $word_line .="\t\t\t\tdata: y,\n";
                $word_line .="\t\t\t\tmin:0,\n";
                $word_line .="\t\t\t\tmax:100,\n";
                $word_line .="\t\t\t\tname:\'Quality Score\',\n";
                $word_line .="\t\t\t\tnameLocation: \'middle\',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false,\n";
                $word_line .="\t\t\t\t\tinterval:4\n";
                $word_line .="\t\t\t\t},\n";            
                $word_line .="\t\t\t\taxisLabel : {\n";
                $word_line .="\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:\'#165A8A\'\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tinterval:4\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\tinside:true,\n";
                $word_line .="\t\t\t\tlength:4\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tvisualMap: {\n";
                $word_line .="\t\t\t\tmin:0,\n";
                $word_line .="\t\t\t\tmax:100,\n";
                $word_line .="\t\t\t\tshow:false,\n";
                $word_line .="\t\t\t\tcolor:[\'#000000\',\'#2b0000\',\'#560000\',\'#800000\',\'#a00000\',\'#ff0000\',\'#ff8000\',\'#ffff00\',\'#7fff00\', \'#00ff00\',\'#ffffff\'],\n";
                $word_line .="\t\t\t\tcalculable: true,\n";
                $word_line .="\t\t\t\torient: 'vertical',\n";
                $word_line .="\t\t\t\tleft: 'right',\n";
                $word_line .="\t\t\t\tbottom: 'center'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tseries:[{\n";
                $word_line .="\t\t\t\ttype:\'heatmap\',\n";
                $word_line .="\t\t\t\tname: \"Quality\",\n";
                $word_line .="\t\t\t\tlayout: \'none\',\n";
                $word_line .="\t\t\t\tcoordinateSystem: 'cartesian2d',\n";
                $word_line .="\t\t\t\tsymbolSize:1,\n";
                $word_line .="\t\t\t\tdata: data1,\n";
                $word_line .="\t\t\t\titemStyle: {\n";
                $word_line .="\t\t\t\t\tnormal: {\n";
                $word_line .="\t\t\t\t\t\tcolor:\'skyblue\',\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tlineStyle: {\n";
                $word_line .="\t\t\t\t\tnormal: {\n";
                $word_line .="\t\t\t\t\t\tcolor: 'skyblue',\n";
                $word_line .="\t\t\t\t\t\twidth: 1,\n";
                $word_line .="\t\t\t\t\t\topacity:1\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tmarkLine: markline\n";
                $word_line .="\t\t\t}]\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions:[\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                   # $word_line .="\t\t\t\ttitle: {text: \'$fig_file[$i][1] Base Quality of Raw Data\'},\n";
                    $word_line .="\t\t\tyAxis: {name:yName${j}},\n";
                    $word_line .="\t\t\txAxis: {name:xName${j}},\n";
                    $word_line .="\t\t\t\t series: [{\n";
                    $word_line .="\t\t\t\ttype:\'heatmap\',\n";
                    $word_line .="\t\t\t\tname: \"Quality\",\n";
                    $word_line .="\t\t\t\tlayout: \'none\',\n";
                    $word_line .="\t\t\t\tcoordinateSystem: 'cartesian2d',\n";
                    $word_line .="\t\t\t\tsymbolSize:1,\n";
                    $word_line .="\t\t\t\tdata: data${j},\n";
                    $word_line .="\t\t\t\titemStyle: {\n";
                    $word_line .="\t\t\t\t\tnormal: {\n";
                    $word_line .="\t\t\t\t\t\tcolor:\'skyblue\',\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t},\n";
                    $word_line .="\t\t\t\tlineStyle: {\n";
                    $word_line .="\t\t\t\t\tnormal: {\n";
                    $word_line .="\t\t\t\t\t\tcolor: 'skyblue',\n";
                    $word_line .="\t\t\t\t\t\twidth: 1,\n";
                    $word_line .="\t\t\t\t\t\topacity:1\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t},\n";
                    $word_line .="\t\t\t\tmarkLine: markline\n";
                    $word_line .="\t\t\t\t}\n";
                    $word_line .="\t\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";                                                                                           
            }
        }
        elsif($echarts_type eq "urve of sequencing saturation"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"seqS$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'seqS$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar seqdata=[];\n";
                $word_line .="\t\tvar yName=\"\";\n";
                $word_line .="\t\tvar xName=\"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\tseqdata = info[\"data\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar ymin = Math.floor(seqdata[0][1])-5;\n";
                $word_line .="\t\tfunction tArray(array){\n";
                $word_line .="\t\t\tvar tarray=[];\n";
                $word_line .="\t\t\tfor(var j=0;j<array[0].length;j++){\n";
                $word_line .="\t\t\t\ttarray[j]=[];\n";
                $word_line .="\t\t\t\tfor(var i=0;i<array.length;i++){\n";
                $word_line .="\t\t\t\t\tif(j==1){\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j].toFixed(2);\n";
                $word_line .="\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j];\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\treturn tarray;\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tvar data = tArray(seqdata);\n";             
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\t\ttrigger: 'axis',\n";
                $word_line .="\t\t\t\tformatter: 'Position :  '+ '{b0}<br />'+'radio：'+'{c0}'+'%'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n"; 
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\ttype:'value',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tname:xName,\n";
                #$word_line .="\t\t\t\tname:'Amount of SE reads (100k)',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tdata: data[0]\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis:{\n";
                $word_line .="\t\t\t\tname: yName,\n";
                #$word_line .="\t\t\t\tname: 'Gene identified ratio (%)',\n";
                $word_line .="\t\t\t\tmin:ymin,\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:'#333',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";            
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";           
                $word_line .="\t\t\t\taxisLabel : {\n";
                $word_line .="\t\t\t\t\tformatter: function (value, index) {\n";
                $word_line .="\t\t\t\t\t\tvar text = value + \" %\";\n";
                $word_line .="\t\t\t\t\t\treturn text;\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tseries: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype: 'line',\n";
                $word_line .="\t\t\t\tsymbol: 'none',\n";
                $word_line .="\t\t\t\tcolor:'blue',\n";
                $word_line .="\t\t\t\tdata: seqdata\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t]\n";                  
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"seqS$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'seqS$hash_num_figure{$type_label}\'));\n"; 
                $word_line .="\t\tfunction tArray(array){\n";
                $word_line .="\t\t\tvar tarray=[];\n";
                $word_line .="\t\t\tfor(var j=0;j<array[0].length;j++){\n";
                $word_line .="\t\t\t\ttarray[j]=[];\n";
                $word_line .="\t\t\t\tfor(var i=0;i<array.length;i++){\n";
                $word_line .="\t\t\t\t\tif(j==1){\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j].toFixed(2);\n";
                $word_line .="\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j];\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\treturn tarray;\n";
                $word_line .="\t\t};\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar seqdata${j}=[];\n";
                    $word_line .="\tvar xName${j}=\"\";\n";
                    $word_line .="\tvar yName${j}=\"\";\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\tseqdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar data${j} = tArray(seqdata${j});\n";
                        $word_line .="\t\tvar ymin${j} = seqdata${j}[0][1];\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tbaseOption:{\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\taxisType: \'category\',\n";
                $word_line .="\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\tcontrolStyle: {\n";
                $word_line .="\t\t\t\t\tposition: \'left\',\n";
                $word_line .="\t\t\t\t\titemSize:15\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\tnumber:10\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\t\ttrigger: 'axis',\n";
                $word_line .="\t\t\t\tformatter: 'Position :  '+ '{b0}<br />'+'radio：'+'{c0}'+'%'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n"; 
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\ttype:'value',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tname:'Amount of SE reads (100k)',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tdata: data1[0]\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis:{\n";
                $word_line .="\t\t\t\tname:  'Gene identified ratio (%)',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:'#333',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";            
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";           
                $word_line .="\t\t\t\taxisLabel : {\n";
                $word_line .="\t\t\t\t\tformatter: function (value, index) {\n";
                $word_line .="\t\t\t\t\t\tvar text = value + \" %\";\n";
                $word_line .="\t\t\t\t\t\treturn text;\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions: [\n";
                for my $i (0 .. $#fig_file){
                my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\ttitle:'',\n";
                    
                    $word_line .="\t\t\txAxis: {name:xName${j}},\n";
                    $word_line .="\t\t\t\tyAxis:{min:Math.floor(ymin${j})-5,name:yName${j}},\n";
                    $word_line .="\t\t\t\tseries: [\n";
                    $word_line .="\t\t\t\t{\n";
                    $word_line .="\t\t\t\ttype: 'line',\n";
                    $word_line .="\t\t\t\tsymbol: 'none',\n";
                    $word_line .="\t\t\t\tcolor:'blue',\n";
                    $word_line .="\t\t\t\tdata: seqdata${j}\n";
                    $word_line .="\t\t\t\t}\n";
                    $word_line .="\t\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }
        }
        elsif($echarts_type eq "Reads distribution on reference gene"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"seqR$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'seqR$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar seqdata=[];\n";
                $word_line .="\t\tvar xName=\"\";\n";
                $word_line .="\t\tvar yName=\"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\tseqdata = info[\"data\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tfunction tArray(array){\n";
                $word_line .="\t\t\tvar tarray=[];\n";
                $word_line .="\t\t\tfor(var j=0;j<array[0].length;j++){\n";
                $word_line .="\t\t\t\ttarray[j]=[];\n";
                $word_line .="\t\t\t\tfor(var i=0;i<array.length;i++){\n";
                $word_line .="\t\t\t\t\tif(j==1){\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j].toFixed(2);\n";
                $word_line .="\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j]/array.length;\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\treturn tarray;\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tvar data = tArray(seqdata);\n";             
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\t\ttrigger: 'axis',\n";
                $word_line .="\t\t\t\tformatter: 'Position :  '+ '{b0}<br />'+'radio：'+'{c0}'+'%'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n"; 
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\ttype:'value',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tname:xName,\n";
               # $word_line .="\t\t\t\tname:'Relative Position In Genes',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tdata: data[0]\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis:{\n";
                $word_line .="\t\t\t\tname:  yName,\n";
               # $word_line .="\t\t\t\tname:  'Reads Number of Each Windows',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:'#333',\n";
                $word_line .="\t\t\t\t\tfontSize:14\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";            
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";           
                $word_line .="\t\t\t\taxisLabel : {\n";
                $word_line .="\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t},\n";                  
                $word_line .="\t\t\tseries: [\n";                  
                $word_line .="\t\t\t{\n";                  
                $word_line .="\t\t\t\ttype: 'line',\n";                  
                $word_line .="\t\t\t\tsymbol: 'none',\n";                  
                $word_line .="\t\t\t\tcolor:'blue',\n";                  
                $word_line .="\t\t\t\tdata: seqdata.map(function (array) {\n";                  
                $word_line .="\t\t\t\t\treturn [(array[0]/200).toFixed(2),array[1]];\n";                  
                $word_line .="\t\t\t\t})\n";                  
                $word_line .="\t\t\t}\n";                  
                $word_line .="\t\t\t]\n";                  
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"seqR$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'seqR$hash_num_figure{$type_label}\'));\n"; 
                $word_line .="\t\tfunction tArray(array){\n";
                $word_line .="\t\t\tvar tarray=[];\n";
                $word_line .="\t\t\tfor(var j=0;j<array[0].length;j++){\n";
                $word_line .="\t\t\t\ttarray[j]=[];\n";
                $word_line .="\t\t\t\tfor(var i=0;i<array.length;i++){\n";
                $word_line .="\t\t\t\t\tif(j==1){\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j].toFixed(2);\n";
                $word_line .="\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j]/200;\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\treturn tarray;\n";
                $word_line .="\t\t};\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar seqdata${j}=[];\n";
                    $word_line .="\tvar xName${j}=\"\";\n";
                    $word_line .="\tvar yName${j}=\"\";\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\tseqdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar data${j} = tArray(seqdata${j});\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tbaseOption:{\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\taxisType: \'category\',\n";
                $word_line .="\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\tcontrolStyle: {\n";
                $word_line .="\t\t\t\t\tposition: \'left\',\n";
                $word_line .="\t\t\t\t\titemSize:15\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:'right',\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";           
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\t\ttrigger: 'axis',\n";
                $word_line .="\t\t\t\tformatter: 'Position :  '+ '{b0}<br />'+'radio：'+'{c0}'+'%'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n"; 
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\ttype:'value',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tname:'Relative Position In Genes',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:\'#333\',\n";
                $word_line .="\t\t\t\t\tfontSize:16\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tdata: data1[0]\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis:{\n";
                $word_line .="\t\t\t\tname:  'Reads Number of Each Windows',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{\n";
                $word_line .="\t\t\t\t\tcolor:'#333',\n";
                $word_line .="\t\t\t\t\tfontSize:14\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";            
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tlineStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";           
                $word_line .="\t\t\t\taxisLabel : {\n";
                $word_line .="\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'#165A8A'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions: [\n";
                for my $i (0 .. $#fig_file){
                my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\ttitle:'',\n";
                    $word_line .="\t\t\tyAxis: {name:yName${j}},\n";
                    $word_line .="\t\t\txAxis: {name:xName${j}},\n";
                    $word_line .="\t\t\t\tseries: [\n";
                    $word_line .="\t\t\t\t{\n";
                    $word_line .="\t\t\t\ttype: 'line',\n";
                    $word_line .="\t\t\t\tsymbol: 'none',\n";
                    $word_line .="\t\t\t\tcolor:'blue',\n";
                    $word_line .="\t\t\t\tdata: seqdata${j}.map(function (array) {\n";
                    $word_line .="\t\t\t\t\treturn [(array[0]/200).toFixed(2),array[1]];\n";
                    $word_line .="\t\t\t\t})\n";
                    $word_line .="\t\t\t\t}\n";
                    $word_line .="\t\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";           
            }
        }
        elsif($echarts_type eq "Number of identied genes"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"Genexp$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'Genexp$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tvar expdata = [];\n";
                $word_line .="\t\tvar xName = \"\";\n";
                $word_line .="\t\tvar yName = \"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\texpdata = info[\"data\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar data=[];\n";
                $word_line .="\t\tfor(var i =0;i<expdata[0].length;i++){\n";
                $word_line .="\t\t\tdata[i]=[];\n";
                $word_line .="\t\t\tfor(var j=0;j<expdata.length;j++){\n";
                $word_line .="\t\t\t\tif(i==2){\n";
                $word_line .="\t\t\t\t\tdata[i][j] = ((expdata[j][i-1]/ expdata[j][i])*100).toFixed(2);\n";
                $word_line .="\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\tdata[i][j] = expdata[j][i];\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tcolor: ['#3398DB'],\n";
                $word_line .="\t\t\ttooltip : {\n";
                $word_line .="\t\t\t\ttrigger: 'axis' ,\n";
                $word_line .="\t\t\t\taxisPointer : {  \n";
                $word_line .="\t\t\t\t\ttype : 'shadow' \n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tformatter: '{b0}: {c0}<br />'\n";            
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";             
                $word_line .="\t\t\txAxis : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype :'category',\n";
                $word_line .="\t\t\t\tdata : data[0],\n";
                $word_line .="\t\t\t\tname:xName,\n";
                #$word_line .="\t\t\t\tname:'Total Gene Number in Database:'+expdata[0][2],\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick: {\n";
                $word_line .="\t\t\t\t\talignWithLabel: true\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\tnameLocation:'middle'\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tyAxis : [\n";
                $word_line .="\t\t\t\t{\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tnameGap:50,\n";
                $word_line .="\t\t\t\tname:yName,\n";
                #$word_line .="\t\t\t\tname:'Number of Expressed Genes',\n";
                $word_line .="\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\tshow:false\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttype : 'value'\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tseries : [\n";
                $word_line .="\t\t\t\t{\n";
                $word_line .="\t\t\t\t\tbarWidth:50,\n";
                $word_line .="\t\t\t\t\tname:'total',\n";
                $word_line .="\t\t\t\t\ttype:'bar',\n";
                $word_line .="\t\t\t\t\tdata: data[1],\n";
                $word_line .="\t\t\t\t\titemStyle:{ \n";
                $word_line .="\t\t\t\t\t\tnormal:{ \n";
                $word_line .="\t\t\t\t\t\t\tlabel:{\n";
                $word_line .="\t\t\t\t\t\t\tshow: true, \n";
                $word_line .="\t\t\t\t\t\t\tposition:'top'\n";
                $word_line .="\t\t\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\t\t\tcolor:'black'\n";
                $word_line .="\t\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"Genexp$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'Genexp$hash_num_figure{$type_label}\'));\n"; 
                $word_line .="\t\tfunction tArray(array){\n";
                $word_line .="\t\t\tvar tarray=[];\n";
                $word_line .="\t\t\tfor(var j=0;j<array[0].length;j++){\n";
                $word_line .="\t\t\t\ttarray[j]=[];\n";
                $word_line .="\t\t\t\tfor(var i=0;i<array.length;i++){\n";
                $word_line .="\t\t\t\t\tif(j==2){\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j].toFixed(2);\n";
                $word_line .="\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\ttarray[j][i]=array[i][j];\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\treturn tarray;\n";
                $word_line .="\t\t};\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar expdata${j}=[];\n";
                    $word_line .="\tvar xName${j}=\"\";\n";
                    $word_line .="\tvar yName${j}=\"\";\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\texpdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar data${j} = tArray(expdata${j});\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tbaseOption:{\n";
                $word_line .="\t\t\tcolor: ['#3398DB'],\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\taxisType: 'category',\n";
                $word_line .="\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\tbottom:0,\n";
                $word_line .="\t\t\tzlevel:-1,\n";
                $word_line .="\t\t\tz:-1,\n";
                $word_line .="\t\t\torient:'vertical',\n";
                $word_line .="\t\t\ttop:17,\n";
                $word_line .="\t\t\tright:-5,\n";
                $word_line .="\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:'right',\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";  
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttooltip : {\n";
                $word_line .="\t\t\t\ttrigger: 'axis' ,\n";
                $word_line .="\t\t\t\taxisPointer : {  \n";
                $word_line .="\t\t\t\t\ttype : 'shadow' \n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tformatter: '{b0}: {c0}<br />'\n";            
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";             
                $word_line .="\t\t\txAxis : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype :'category',\n";
               # $word_line .="\t\t\t\tdata : data1[0],\n";
               # $word_line .="\t\t\t\tname:'Total Gene Number in Database:'+expdata1[0][2],\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick: {\n";
                $word_line .="\t\t\t\t\talignWithLabel: true\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\tnameLocation:'middle'\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tyAxis : [\n";
                $word_line .="\t\t\t\t{\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tnameGap:50,\n";
                $word_line .="\t\t\t\tname:'Number of Expressed Genes',\n";
                $word_line .="\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\tshow:false\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttype : 'value'\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions: [\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\txAxis:{name:xName${j},data:data${j}[0]},\n";
                    $word_line .="\t\t\t\tyAxis: {name:yName${j}},\n";
                    #$word_line .="\t\t\txAxis: {name:xName${j}}\n";
                    $word_line .="\t\t\t\tseries : [\n";
                    $word_line .="\t\t\t\t{\n";
                    $word_line .="\t\t\t\t\tbarWidth:50,\n";
                    $word_line .="\t\t\t\t\tname:'total',\n";
                    $word_line .="\t\t\t\t\ttype:'bar',\n";
                    $word_line .="\t\t\t\t\tdata: data${j}[1],\n";
                    $word_line .="\t\t\t\t\titemStyle:{ \n";
                    $word_line .="\t\t\t\t\t\tnormal:{ \n";
                    $word_line .="\t\t\t\t\t\t\tlabel:{\n";
                    $word_line .="\t\t\t\t\t\t\tshow: true, \n";
                    $word_line .="\t\t\t\t\t\t\tposition:'top'\n";
                    $word_line .="\t\t\t\t\t\t\t},\n";
                    $word_line .="\t\t\t\t\t\t\ttextStyle:{\n";
                    $word_line .="\t\t\t\t\t\t\t\tcolor:'black'\n";
                    $word_line .="\t\t\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t}\n";
                    $word_line .="\t\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }
        }
        elsif($echarts_type eq "Heatmap of correlation"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"correlation$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'correlation$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tvar mapdata = [];\n";
                $word_line .="\t\tvar xName = \"\";\n";
                $word_line .="\t\tvar yName = \"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\tmapdata = info[\"data\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar x = [];\n";
                $word_line .="\t\tvar y = [];\n";
                $word_line .="\t\tvar datav=[];\n";
                $word_line .="\t\tfor(var i=1;i<mapdata.length;i++){\n";
                $word_line .="\t\t\ty[i-1]=mapdata[i][0];\n";
                $word_line .="\t\t\tfor(var j=1;j<mapdata[0].length;j++){\n";
                $word_line .="\t\t\t\tx[i-1]=mapdata[0][i];\n";
                $word_line .="\t\t\t\tdatav.push([i-1,j-1,mapdata[i][j].toFixed(3)]);\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttitle: {text:''},\n";
                $word_line .="\t\t\ttooltip: {position: 'top'},\n";
                $word_line .="\t\t\tanimation: false,\n";
                $word_line .="\t\t\tgrid: {\n";
                $word_line .="\t\t\t\ty: '10%'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                #$word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\ttype: 'category',\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tnameGap:25,\n";
                $word_line .="\t\t\t\tname:xName,\n";
                $word_line .="\t\t\t\tdata: x,\n";
                $word_line .="\t\t\t\tsplitArea: {\n";
                $word_line .="\t\t\t\t\tshow: true\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\ttype: 'category',\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tnameGap:30,";
                $word_line .="\t\t\t\tname:yName,\n";
                $word_line .="\t\t\t\tdata: y,\n";
                $word_line .="\t\t\t\tsplitArea: {\n";
                $word_line .="\t\t\t\t\tshow: true\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tvisualMap: {\n";
                $word_line .="\t\t\t\tmin: 0,\n";
                $word_line .="\t\t\t\tmax: 1.000,\n";
                $word_line .="\t\t\t\tcalculable: true,\n";
                $word_line .="\t\t\t\torient: 'vertical',\n";
                $word_line .="\t\t\t\tleft: 'right',\n";
                $word_line .="\t\t\t\tbottom: '50%',\n";
                $word_line .="\t\t\t\talign:'bottom',\n";
                $word_line .="\t\t\t\titemWidth:10,\n";
                $word_line .="\t\t\t\tcolor:['#4068DF','#7D89E7','#A9ABEF','#ACAEF0','#D1D1F6','#FBF9FE','#FFFEFE','#F4F5F4','#F1F1F1', '#F8F8F8','#FFFFFF']\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tseries: [{\n";
                $word_line .="\t\t\t\tname: '',\n";
                $word_line .="\t\t\t\ttype: 'heatmap',\n";
                $word_line .="\t\t\t\tdata: datav,\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tnormal: {\n";
                $word_line .="\t\t\t\t\t\tshow: true\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\titemStyle: {\n";
                $word_line .="\t\t\t\t\temphasis: {\n";
                $word_line .="\t\t\t\t\t\tshadowBlur: 10,\n";
                $word_line .="\t\t\t\t\t\tshadowColor: 'rgba(0, 0, 0, 0.5)'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}]\n";
                $word_line .="\t\t\n";
                $word_line .="\t\t\n";
                $word_line .="\t\t\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"correlation$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'correlation$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\t\n";            
                $word_line .="\t\t\t\n";            
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar mapdata${j}=[];\n";
                    $word_line .="\tvar xName${j}=\"\";\n";
                    $word_line .="\tvar yName${j}=\"\";\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\tmapdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar x${j}=[];\n";
                        $word_line .="\t\tvar y${j}=[];\n";
                        $word_line .="\t\tvar datav${j}=[];\n";
                        $word_line .="\t\tfor(var i=1;i<mapdata${j}.length;i++){\n";   
                        $word_line .="\t\t\ty${j}[i-1]=mapdata${j}[i][0];\n";            
                        $word_line .="\t\t\tfor(var j=1;j<mapdata${j}[0].length;j++){\n";            
                        $word_line .="\t\t\t\tx${j}[i-1]=mapdata${j}[0][i];\n";            
                        $word_line .="\t\t\t\tdatav${j}.push([i-1,j-1,mapdata${j}[i][j].toFixed(3)]);\n";            
                        $word_line .="\t\t\t}\n";            
                        $word_line .="\t\t}\n"; 
                        $word_line .="\t\tdatav${j} = datav${j}.map(function (item) {\n"; 
                        $word_line .="\t\treturn [item[1], item[0], item[2] || '-'];\n"; 
                        $word_line .="\t\t\n"; 
                        $word_line .="\t\t});\n"; 
                        $word_line .="\t\t\n"; 
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\t\t\n";            
                $word_line .="\t\t\t\n"; 
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tbaseOption: {\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\taxisType: \'category\',\n";
                $word_line .="\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\tcontrolStyle: {\n";
                $word_line .="\t\t\t\t\tposition: \'left\',\n";
                $word_line .="\t\t\t\t\titemSize:15\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\tnumber:10\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";            
                $word_line .="\t\t\ttooltip: {position: 'top'},\n";
                $word_line .="\t\t\tanimation: false,\n";
                $word_line .="\t\t\tgrid: {\n";
                $word_line .="\t\t\t\ty: '10%'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                #$word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{pixelRatio:3}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";            
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\ttype: 'category',\n";
                #$word_line .="\t\t\t\tdata: x,\n";
                $word_line .="\t\t\t\tsplitArea: {\n";
                $word_line .="\t\t\t\t\tshow: true\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\ttype: 'category',\n";
                #$word_line .="\t\t\t\tdata: y,\n";
                $word_line .="\t\t\t\tsplitArea: {\n";
                $word_line .="\t\t\t\t\tshow: true\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tvisualMap: {\n";
                $word_line .="\t\t\t\tshow:false,\n";
                $word_line .="\t\t\t\tmin: 0,\n";
                $word_line .="\t\t\t\tmax: 1.000,\n";
                $word_line .="\t\t\t\tcalculable: true,\n";
                $word_line .="\t\t\t\torient: 'vertical',\n";
                $word_line .="\t\t\t\tleft: 'right',\n";
                $word_line .="\t\t\t\tbottom: '50%',\n";
                $word_line .="\t\t\t\talign:'bottom',\n";
                $word_line .="\t\t\t\titemWidth:10,\n";
                $word_line .="\t\t\t\tcolor:['#4068DF','#7D89E7','#A9ABEF','#ACAEF0','#D1D1F6','#FBF9FE','#FFFEFE','#F4F5F4','#F1F1F1', '#F8F8F8','#FFFFFF']\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tseries: [{\n";
                $word_line .="\t\t\t\tname: '',\n";
                $word_line .="\t\t\t\ttype: 'heatmap',\n";
                $word_line .="\t\t\t\tdata: datav1,\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tnormal: {\n";
                $word_line .="\t\t\t\t\t\tshow: true\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\titemStyle: {\n";
                $word_line .="\t\t\t\t\temphasis: {\n";
                $word_line .="\t\t\t\t\t\tshadowBlur: 10,\n";
                $word_line .="\t\t\t\t\t\tshadowColor: 'rgba(0, 0, 0, 0.5)'\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}]\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions:[\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\ttitle: {text: \''},\n";
                    $word_line .="\t\t\t\tyAxis: {data:y${j},name:yName${j},nameLocation:'middle'},\n";
                    $word_line .="\t\t\t\txAxis: {data:x${j},name:xName${j},nameLocation:'middle'},\n";
                    $word_line .="\t\t\t\t series: [{\n";
                    $word_line .="\t\t\t\ttype:\'heatmap\',\n";
                    $word_line .="\t\t\t\tname: \"Quality\",\n";
                    $word_line .="\t\t\t\tlayout: \'none\',\n";
                    $word_line .="\t\t\t\tcoordinateSystem: 'cartesian2d',\n";
                    $word_line .="\t\t\t\tsymbolSize:1,\n";
                    $word_line .="\t\t\t\tdata: datav${j},\n";
                    $word_line .="\t\t\t\titemStyle: {\n";
                    $word_line .="\t\t\t\t\tnormal: {\n";
                    $word_line .="\t\t\t\t\t\tcolor:\'skyblue\',\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t},\n";
                    $word_line .="\t\t\t\tlineStyle: {\n";
                    $word_line .="\t\t\t\t\tnormal: {\n";
                    $word_line .="\t\t\t\t\t\tcolor: 'skyblue',\n";
                    $word_line .="\t\t\t\t\t\twidth: 1,\n";
                    $word_line .="\t\t\t\t\t\topacity:1\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t},\n";
                    $word_line .="\t\t\t\tmarkLine: markline\n";
                    $word_line .="\t\t\t\t}\n";
                    $word_line .="\t\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }
        }
        elsif($echarts_type eq "Principle component analysis"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                my $json_file = "";
                my @group_PCA;
                my @data_array;
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                    $json_file = "$data_path/$fig_file[0][0]";
                    open INJSON,$json_file,or die $!;
		    my $content;
                    read(INJSON, $content, -s $json_file);
                    close INJSON;
                    my $decoded = decode_json($content);
                    for my $item2 (@{$decoded}){
			my $pca_group;
                        foreach $pca_group (@{$item2->{'data'}}){
                            push @data_array,@{$pca_group}[-1];
                        }
                    }
                    @group_PCA=uniqueArray(@data_array);
		   # print "pca has @group_PCA\n";
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }

                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"pca_com$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'pca_com$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tvar x,y,legend,name,newdata,tdata;\n";
                $word_line .="\t\tvar cdata = [];\n";
                $word_line .="\t\tvar sdata = [];\n";
                $word_line .="\t\tvar yName = \"\";\n";
                $word_line .="\t\tvar xName = \"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\tsdata = info[\"data\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tfor(var i=0;i<sdata[1].length;i++){\n";
                $word_line .="\t\t\tcdata[i]=[];\n";
                $word_line .="\t\t\tfor(var j=1;j<sdata.length;j++){\n";
                $word_line .="\t\t\tcdata[i][j-1] = sdata[j][i];\n";
                $word_line .="\t\t\t\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tfunction unique(arr) {\n";
                $word_line .="\t\t\tvar result = [], hash = {};\n";
                $word_line .="\t\t\tfor (var i = 0, elem; (elem = arr[i]) != null; i++) {\n";
                $word_line .="\t\t\t\tif (!hash[elem]) {\n";
                $word_line .="\t\t\t\t\tresult.push(elem);\n";
                $word_line .="\t\t\t\t\thash[elem] = true;\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t return result;\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tlegend = unique(cdata[cdata.length-1]);\n";
                $word_line .="\t\ttdata=[];\n";
                $word_line .="\t\tx = cdata[1];\n";
                $word_line .="\t\ty = cdata[2];\n";
                $word_line .="\t\tnewdata=[];\n";
                $word_line .="\t\tfor(var i=0;i<x.length;i++){\n";
                $word_line .="\t\t\tnewdata.push([(x[i]).toFixed(2),y[i].toFixed(2),cdata[0][i],cdata[cdata.length-1][i]]);\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tfor(var i=0;i<legend.length;i++){  \n";
                $word_line .="\t\t\tvar mdata=[];\n";
                $word_line .="\t\t\tvar tleng=\"\";\n";
                $word_line .="\t\t\tfor(var j=0;j<newdata.length;j++){\n";
                $word_line .="\t\t\t\tif(legend[i]==newdata[j][3]){\n";
                $word_line .="\t\t\t\t\tmdata.push([newdata[j][0],newdata[j][1],newdata[j][2]]);\n";
                $word_line .="\t\t\t\t\ttleng = newdata[j][3];\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\ttdata.push([mdata,tleng]);\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttitle: {text:''},\n";
                $word_line .="\t\t\ttooltip : {\n";
                $word_line .="\t\t\t\ttrigger: 'axis',\n";
                $word_line .="\t\t\t\tshowDelay : 0,\n";
                $word_line .="\t\t\t\taxisPointer:{\n";
                $word_line .="\t\t\t\t\tshow: true,\n";
                $word_line .="\t\t\t\t\ttype : 'cross',\n";
                $word_line .="\t\t\t\t\tlineStyle: {\n";
                $word_line .="\t\t\t\t\ttype : 'dashed',\n";
                $word_line .="\t\t\t\t\twidth : 1\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tformatter: '{c0}',\n";
                $word_line .="\t\t\t\tzlevel: 1\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend:{\n";
                $word_line .="\t\t\t\tdata:legend\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox: {\n";
                $word_line .="\t\t\t\tshow : true,\n";
                $word_line .="\t\t\t\tfeature : {\n";
                $word_line .="\t\t\t\t\tmark : {show: true},\n";
                $word_line .="\t\t\t\t\tdataZoom : {show: true},\n";
                $word_line .="\t\t\t\t\tdataView : {show: true, readOnly: false},\n";
                $word_line .="\t\t\t\t\trestore : {show: true},\n";
                $word_line .="\t\t\t\t\taveAsImage : {show: true}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis : [{\n";
                $word_line .="\t\t\t\ttype : 'value',\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
	        $word_line .="\t\t\t\tnameGap:20,\n";
                $word_line .="\t\t\t\tscale:true,\n";
                #$word_line .="\t\t\t\tname:sdata[0][0]\n";
                $word_line .="\t\t\t\tname:xName\n";
                $word_line .="\t\t\t}],\n";
                $word_line .="\t\t\tyAxis : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype : 'value',\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tnameGap:40,\n";
                $word_line .="\t\t\t\tscale:true,\n";
               # $word_line .="\t\t\t\tname:sdata[0][1]\n";
                $word_line .="\t\t\t\tname:yName\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tseries : [\n";
                for my $i (0 .. $#group_PCA-1){
                    $word_line .="\t\t\t\t{\n";
                    $word_line .="\t\t\t\tname:tdata[$i][1],\n";
                    $word_line .="\t\t\t\ttype:'scatter',\n";
                    $word_line .="\t\t\t\tlarge: true,\n";
                    $word_line .="\t\t\t\tsymbolSize: 10,\n";
                    $word_line .="\t\t\t\tdata:tdata[$i][0]\n";
                    $word_line .="\t\t\t\t},\n";
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                my $fig_dir = $fig_file[0][0];
                #my $json_file = "";
                my @all_group_pca;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"pca_com$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'pca_com$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tfunction unique(arr){\n";
                $word_line .="\t\t\tvar result = [], hash = {};\n";
                $word_line .="\t\t\tfor (var i = 0, elem; (elem = arr[i]) != null; i++) {\n";
                $word_line .="\t\t\t\tif (!hash[elem]) {\n";
                $word_line .="\t\t\t\t\tresult.push(elem);\n";
                $word_line .="\t\t\t\t\thash[elem] = true;\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t return result;\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\t\t\n";            
                $word_line .="\t\t\t\n";
		# my @group_PCA;            
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar pcadata${j}=[];\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        my @group_PCA;
                        my @data_array;
                        my $json_file = "";
                        $json_file = "$data_path/$fig_file[$i][0]";
                        open INJSON,$json_file,or die $!;
			my $content;
                        read(INJSON, $content, -s $json_file);
                        close INJSON;
                        my $decoded = decode_json($content);
                        for my $item2 (@{$decoded}){
			    my $pca_group;
                            foreach $pca_group (@{$item2->{'data'}}){
                                push @data_array,@{$pca_group}[-1];
                            }
                        }
                       # print "group pca $#group_PCA\n";
                        @group_PCA=uniqueArray(@data_array);
                        $all_group_pca[$i] = \@group_PCA;
                        $word_line .="\t\tvar x${j},y${j},legend${j},name${j},newdata${j},tdata${j};\n";
                        $word_line .="\t\tvar cdata${j} = [];\n";
                        $word_line .="\t\tvar sdata${j} = [];\n";
                        $word_line .="\t\tvar xName${j} = \"\";\n";
                        $word_line .="\t\tvar yName${j} = \"\";\n";
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\tsdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";  
                        $word_line .="\t\tfor(var i=0;i<sdata${j}[1].length;i++){\n";
                        $word_line .="\t\t\tcdata${j}[i]=[];\n";
                        $word_line .="\t\t\tfor(var j=1;j<sdata${j}.length;j++){\n";
                        $word_line .="\t\t\tcdata${j}[i][j-1] = sdata${j}[j][i];\n";
                        $word_line .="\t\t\t\n";
                        $word_line .="\t\t\t}\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\tlegend${j} = unique(cdata${j}[cdata${j}.length-1]);\n";
                        $word_line .="\t\ttdata${j}=[];\n";
                        $word_line .="\t\tx${j} = cdata${j}[1];\n";
                        $word_line .="\t\ty${j} = cdata${j}[2];\n";
                        $word_line .="\t\tnewdata${j}=[];\n";
                        $word_line .="\t\tfor(var i=0;i<x${j}.length;i++){\n";
                        $word_line .="\t\t\tnewdata${j}.push([(x${j}[i]).toFixed(2),y${j}[i].toFixed(2),cdata${j}[0][i],cdata${j}[cdata${j}.length-1][i]]);\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\tfor(var i=0;i<legend${j}.length;i++){  \n";
                        $word_line .="\t\t\tvar mdata${j}=[];\n";
                        $word_line .="\t\t\tvar tleng${j}=\"\";\n";
                        $word_line .="\t\t\tfor(var j=0;j<newdata${j}.length;j++){\n";
                        $word_line .="\t\t\t\tif(legend${j}[i]==newdata${j}[j][3]){\n";
                        $word_line .="\t\t\t\t\tmdata${j}.push([newdata${j}[j][0],newdata${j}[j][1],newdata${j}[j][2]]);\n";
                        $word_line .="\t\t\t\t\ttleng${j} = newdata${j}[j][3];\n";
                        $word_line .="\t\t\t\t}\n";
                        $word_line .="\t\t\t}\n";
                        $word_line .="\t\t\ttdata${j}.push([mdata${j},tleng${j}]);\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\t\n"; 
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttitle: {text:''},\n";
                $word_line .="\t\t\tbaseOption: {\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\taxisType: \'category\',\n";
                $word_line .="\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\tcontrolStyle: {\n";
                $word_line .="\t\t\t\t\tposition: \'left\',\n";
                $word_line .="\t\t\t\t\titemSize:15\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\tnumber:10\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";   
                $word_line .="\t\t\ttooltip : {\n";
                $word_line .="\t\t\t\ttrigger: 'axis',\n";
                $word_line .="\t\t\t\tshowDelay : 0,\n";
                $word_line .="\t\t\t\taxisPointer:{\n";
                $word_line .="\t\t\t\t\tshow: true,\n";
                $word_line .="\t\t\t\t\ttype : 'cross',\n";
                $word_line .="\t\t\t\t\tlineStyle: {\n";
                $word_line .="\t\t\t\t\ttype : 'dashed',\n";
                $word_line .="\t\t\t\t\twidth : 1\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tformatter: '{c0}',\n";
                $word_line .="\t\t\t\tzlevel: 1\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend:{\n";
                $word_line .="\t\t\t\tdata:legend1\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox: {\n";
                $word_line .="\t\t\t\tshow : true,\n";
                $word_line .="\t\t\t\tfeature : {\n";
                $word_line .="\t\t\t\t\tmark : {show: true},\n";
                $word_line .="\t\t\t\t\tdataZoom : {show: true},\n";
                $word_line .="\t\t\t\t\tdataView : {show: true, readOnly: false},\n";
                $word_line .="\t\t\t\t\trestore : {show: true},\n";
                $word_line .="\t\t\t\t\taveAsImage : {show: true}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis : [{\n";
                $word_line .="\t\t\t\ttype : 'value',\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tnameGap:20,\n";
                $word_line .="\t\t\t\tscale:true,\n";
                $word_line .="\t\t\t\tname:sdata1[0][0]\n";
                $word_line .="\t\t\t}],\n";
                $word_line .="\t\t\tyAxis : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype : 'value',\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tnameGap:40,";
                $word_line .="\t\t\t\tscale:true,\n";
                $word_line .="\t\t\t\tname:sdata1[0][1]\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions:[\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\ttitle: {text: \''},\n";
                    $word_line .="\t\t\t\tlegend:{data:legend${j}},\n";
                    $word_line .="\t\t\t\tyAxis: {name:yName${j}},\n";
                    $word_line .="\t\t\t\txAxis: {name:xName${j}},\n";
                    $word_line .="\t\t\t\t series: [\n";
                #    print "pcagourp is $#{$all_group_pca[$i]}";
                    for my $k (0 .. $#{$all_group_pca[$i]}-1){
                        $word_line .="\t\t\t\t{\n";
                        $word_line .="\t\t\t\tname:tdata${j}[$k][1],\n";
                        $word_line .="\t\t\t\ttype:'scatter',\n";
                        $word_line .="\t\t\t\tlarge: true,\n";
                        $word_line .="\t\t\t\tsymbolSize: 10,\n";
                        $word_line .="\t\t\t\tdata:tdata${j}[$k][0]\n";
                        $word_line .="\t\t\t\t},\n";
                    }
                    $word_line .="\t\t\t\t\n";
                    $word_line .="\t\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
                $word_line .="\t\t\t\n";            
                $word_line .="\t\t\t\n"; 
            }
        }
        elsif($echarts_type eq "Statistics number of conditional"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"spc_gene$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'spc_gene$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tvar dsdata;\n";
                $word_line .="\t\tvar xName=\"\";\n";
                $word_line .="\t\tvar yName=\"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\tdsdata = info[\"data\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar x = [];\n";
                $word_line .="\t\tvar y = [];\n";
                $word_line .="\t\tvar datan=[];\n";
                $word_line .="\t\tfor(var i=0;i<dsdata.length;i++){  \n";
                $word_line .="\t\t\tx[i]=dsdata[i][0];\n";
                $word_line .="\t\t\ty[i]=dsdata[i][1];\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tdatan=[x,y];\n";
                $word_line .="\t\tvar option ={\n";
                $word_line .="\t\t\tcolor: ['#3398DB'],\n";
                $word_line .="\t\t\ttooltip : {\n";
                $word_line .="\t\t\t\ttrigger: 'axis' ,\n";
                $word_line .="\t\t\t\taxisPointer : {\n";
                $word_line .="\t\t\t\t\ttype : 'shadow'\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tformatter: '{b0}: {c0}<br />'\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\tdataZoom: {}, \n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype : 'category',\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tdata : x,\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tname:xName,\n";
                #$word_line .="\t\t\t\tname:'Sample',\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick: {\n";
                $word_line .="\t\t\t\t\talignWithLabel: true\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tyAxis : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tname:yName,\n";
                #$word_line .="\t\t\t\tname:'GeneNumber',\n";
                $word_line .="\t\t\t\ttype : 'value',\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tseries : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tbarWidth:50,\n";
                $word_line .="\t\t\t\tname:'total',\n";
                $word_line .="\t\t\t\ttype:'bar', \n";
                $word_line .="\t\t\t\tdata: datan[1],\n";
                $word_line .="\t\t\t\titemStyle:{ \n";
                $word_line .="\t\t\t\tnormal:{ \n";
                $word_line .="\t\t\t\tlabel:{\n";
                $word_line .="\t\t\t\tshow: true,\n";
                $word_line .="\t\t\t\tposition:'top'\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\tcolor:'black',\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"spc_gene$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'spc_gene$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";                
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\tvar sdataSource${j};\n";
                    $word_line .="\t\tvar yName${j};\n";
                    $word_line .="\t\tvar xName${j};\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\tsdataSource${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar x${j} = [];\n";
                        $word_line .="\t\tvar y${j} = [];\n";
                        $word_line .="\t\tvar datan${j}=[];\n";
                        $word_line .="\t\tfor(var i=0;i<sdataSource${j}.length;i++){  \n";
                        $word_line .="\t\t\tx${j}[i]=sdataSource${j}[i][0];\n";
                        $word_line .="\t\t\ty${j}[i]=sdataSource${j}[i][1];\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\tdatan${j}=[x${j},y${j}];\n";
                        $word_line .="\t\t\n";
                        $word_line .="\t\t\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option ={\n";
                $word_line .="\t\t\tbaseOption: {\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\taxisType: \'category\',\n";
                $word_line .="\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\tcontrolStyle: {\n";
                $word_line .="\t\t\t\t\tposition: \'left\',\n";
                $word_line .="\t\t\t\t\titemSize:15\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\tnumber:10\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttooltip : {\n";
                $word_line .="\t\t\t\ttrigger: 'axis' ,\n";
                $word_line .="\t\t\t\taxisPointer : {\n";
                $word_line .="\t\t\t\t\ttype : 'shadow'\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tformatter: '{b0}: {c0}<br />'\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\tdataZoom: {}, \n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype : 'category',\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tdata : x1,\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tname:'Sample',\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisTick: {\n";
                $word_line .="\t\t\t\t\talignWithLabel: true\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tyAxis : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tname:'GeneNumber',\n";
                $word_line .="\t\t\t\ttype : 'value',\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLabel:{\n";
                $word_line .="\t\t\t\tmargin:5\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\t},\n"; 
                $word_line .="\t\t\toptions:[\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\tcolor: ['#3398DB'],\n";
                    $word_line .="\t\t\txAxis:{data:x${j},name:xName${j}},\n";
                    $word_line .="\t\t\tyAxis: {name:yName${j}},\n";
                    #$word_line .="\t\t\txAxis: {name:xName${j}}\n";
                    $word_line .="\t\t\t\n";
                    $word_line .="\t\t\tseries : [\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tbarWidth:50,\n";
                    $word_line .="\t\t\t\tname:'total',\n";
                    $word_line .="\t\t\t\ttype:'bar', \n";
                    $word_line .="\t\t\t\tdata: datan${j}[1],\n";
                    $word_line .="\t\t\t\titemStyle:{ \n";
                    $word_line .="\t\t\t\tnormal:{ \n";
                    $word_line .="\t\t\t\tlabel:{\n";
                    $word_line .="\t\t\t\tshow: true,\n";
                    $word_line .="\t\t\t\tposition:'top'\n";
                    $word_line .="\t\t\t\t},\n";
                    $word_line .="\t\t\t\ttextStyle:{\n";
                    $word_line .="\t\t\t\tcolor:'black',\n";
                    $word_line .="\t\t\t\t}\n";
                    $word_line .="\t\t\t\t}\n";
                    $word_line .="\t\t\t\t}\n";
                    $word_line .="\t\t\t}\n";
                    $word_line .="\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }         
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t\t\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }
        }
        elsif($echarts_type eq "Statistic of differentially"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"expressedgenes$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'expressedgenes$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tvar dataSource;\n";
                $word_line .="\t\tvar yName;\n";
                $word_line .="\t\tvar xName;\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\tdataSource = info[\"data\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar datax=[];\n";
                $word_line .="\t\tvar datanewx=[];\n";
                $word_line .="\t\tvar datal=[];\n";
                $word_line .="\t\tvar datas=[];\n";
                $word_line .="\t\tvar dataup=[];\n";
                $word_line .="\t\tvar datadown=[];\n";
                $word_line .="\t\tvar maxdata=dataSource[0][2];\n";
                $word_line .="\t\tfor(var i=0;i<dataSource.length;i++){ \n";
                $word_line .="\t\t\tdatas.push(dataSource[i][2]);\n";
                $word_line .="\t\t\tdatax.push(dataSource[i][0]);\n";
                $word_line .="\t\t\tdatal.push(dataSource[i][1]);\n";
                $word_line .="\t\t\tif(maxdata<dataSource[i][2]){\n";
                $word_line .="\t\t\t\tmaxdata=dataSource[i][2];\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tmaxdata=maxdata+500;\n";
                $word_line .="\t\tfor(var i=0;i<datas.length;i++){\n";
                $word_line .="\t\t\tif((i+1)%2>0){\n";
                $word_line .="\t\t\t\tdataup.push(datas[i]);\n";
                $word_line .="\t\t\t\tdatanewx.push(datax[i]);\n";
                $word_line .="\t\t\t}else{\n";
                $word_line .="\t\t\t\tdatadown.push(datas[i]);\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\t\ttrigger: 'axis'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox: {\n";
                $word_line .="\t\t\t\tfeature: {\n";
                $word_line .="\t\t\t\tdataZoom: {}, \n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend: {\n";
                $word_line .="\t\t\t\tdata:datal\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\ttype: 'category',\n";
                $word_line .="\t\t\t\tname:xName,\n";
                $word_line .="\t\t\t\tnameGap:20,\n";
                $word_line .="\t\t\t\tdata:  datanewx\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tyAxis: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\tname: yName,\n";
                $word_line .="\t\t\t\tnameGap:40,\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                #$word_line .="\t\t\t\tname: 'Number 0f DEGs',\n";
                $word_line .="\t\t\t\tmin: 0,\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tshow:true\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tmax: maxdata,\n";
                $word_line .="\t\t\t\tinterval: 1000,\n";
                $word_line .="\t\t\t\taxisLabel: {\n";
                $word_line .="\t\t\t\t\tformatter: '{value}'\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tseries: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\titemStyle:{ \n";
                $word_line .="\t\t\t\t\tnormal:{ \n";
                $word_line .="\t\t\t\t\t\tlabel:{ \n";
                $word_line .="\t\t\t\t\t\t\tshow: true, \n";
                $word_line .="\t\t\t\t\t\t\tposition:'top'\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tname:datal[1],\n";
                $word_line .="\t\t\t\ttype:'bar',\n";
               # $word_line .="\t\t\t\tbarWidth:60,\n";
                $word_line .="\t\t\t\tanimation:false,\n";
                $word_line .="\t\t\t\tanimationDuration:1000,\n";
                $word_line .="\t\t\t\tanimationDurationUpdate:1000,\n";
                $word_line .="\t\t\t\tdata:datadown\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\titemStyle:{ \n";
                $word_line .="\t\t\t\t\tnormal:{ \n";
                $word_line .="\t\t\t\t\t\tlabel:{ \n";
                $word_line .="\t\t\t\t\t\t\tshow: true, \n";
                $word_line .="\t\t\t\t\t\t\tposition:'top'\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tname:datal[0],\n";
                $word_line .="\t\t\t\ttype:'bar',\n";
               # $word_line .="\t\t\t\tbarWidth:60,\n";
                $word_line .="\t\t\t\tanimation:false,\n";
                $word_line .="\t\t\t\tanimationDuration:1000,\n";
                $word_line .="\t\t\t\tanimationDurationUpdate:1000,\n";
                $word_line .="\t\t\t\tdata:dataup\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"expressedgenes$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'expressedgenes$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";                
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\tvar dataSource${j};\n";
                    $word_line .="\t\tvar yName${j};\n";
                    $word_line .="\t\tvar xName${j};\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\tdataSource${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar datax${j}=[];\n";
                        $word_line .="\t\tvar datanewx${j}=[];\n";
                        $word_line .="\t\tvar datal${j}=[];\n";
                        $word_line .="\t\tvar datas${j}=[];\n";
                        $word_line .="\t\tvar dataup${j}=[];\n";
                        $word_line .="\t\tvar datadown${j}=[];\n";
                        $word_line .="\t\tvar maxdata${j}=dataSource${j}[0][2];\n";
                        $word_line .="\t\tfor(var i=0;i<dataSource${j}.length;i++){ \n";
                        $word_line .="\t\t\tdatas${j}.push(dataSource${j}[i][2]);\n";
                        $word_line .="\t\t\tdatax${j}.push(dataSource${j}[i][0]);\n";
                        $word_line .="\t\t\tdatal${j}.push(dataSource${j}[i][1]);\n";
                        $word_line .="\t\t\tif(maxdata${j}<dataSource${j}[i][2]){\n";
                        $word_line .="\t\t\t\tmaxdata${j}=dataSource${j}[i][2];\n";
                        $word_line .="\t\t\t}\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\tmaxdata${j}=maxdata${j}+500;\n";
                        $word_line .="\t\tfor(var i=0;i<datas${j}.length;i++){\n";
                        $word_line .="\t\t\tif((i+1)%2>0){\n";
                        $word_line .="\t\t\t\tdataup${j}.push(datas${j}[i]);\n";
                        $word_line .="\t\t\t\tdatanewx${j}.push(datax${j}[i]);\n";
                        $word_line .="\t\t\t}else{\n";
                        $word_line .="\t\t\t\tdatadown${j}.push(datas${j}[i]);\n";
                        $word_line .="\t\t\t}\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\t\n";
                        $word_line .="\t\t\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option ={\n";
                $word_line .="\t\t\tbaseOption: {\n";
                $word_line .="\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\taxisType: \'category\',\n";
                $word_line .="\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\tcontrolStyle: {\n";
                $word_line .="\t\t\t\t\tposition: \'left\',\n";
                $word_line .="\t\t\t\t\titemSize:15\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                     my $j = $i+1;
                     $word_line .="\t\t\t\t\t{\n";
                     $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                     $word_line .="\t\t\t\t\t\ttooltip: {\n";
                     $word_line .="\t\t\t\t\t\t\tformatter: \'{b}\'\n";
                     $word_line .="\t\t\t\t\t\t}\n";
                     $word_line .="\t\t\t\t\t},\n";
                }
                $word_line .="\t\t\t\t],\n";
                $word_line .="\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\tnumber:10\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\t\ttrigger: 'axis'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox: {\n";
                $word_line .="\t\t\t\tfeature: {\n";
                $word_line .="\t\t\t\tdataZoom: {}, \n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend: {\n";
                $word_line .="\t\t\t\tdata:datal1\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tnameGap:20,\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\ttype: 'category',\n";
                $word_line .="\t\t\t\tdata:  datanewx1\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\tyAxis: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\tname: 'Number 0f DEGs',\n";
                $word_line .="\t\t\t\tmin: 0,\n";
                $word_line .="\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\taxisLine:{\n";
                $word_line .="\t\t\t\t\tshow:true\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tmax: maxdata1,\n";
                $word_line .="\t\t\t\tinterval: 1000,\n";
                $word_line .="\t\t\t\taxisLabel: {\n";
                $word_line .="\t\t\t\t\tformatter: '{value}'\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t],\n";
                $word_line .="\t\t\t},\n"; 
                $word_line .="\t\t\toptions:[\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\tlegend: {data:datal${j}},\n";
                    $word_line .="\t\t\tyAxis:{max: maxdata${j},name:yName${j}},\n";
                    $word_line .="\t\t\txAxis:{data:datanewx${j},name:xName${j}},\n";
                    $word_line .="\t\t\t\n";
                    $word_line .="\t\t\tseries: [\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\titemStyle:{ \n";
                    $word_line .="\t\t\t\t\tnormal:{ \n";
                    $word_line .="\t\t\t\t\t\tlabel:{ \n";
                    $word_line .="\t\t\t\t\t\t\tshow: true, \n";
                    $word_line .="\t\t\t\t\t\t\tposition:'top'\n";
                    $word_line .="\t\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\n";
                    $word_line .="\t\t\t\t},\n";
                    $word_line .="\t\t\t\tname:datal${j}[1],\n";
                    $word_line .="\t\t\t\ttype:'bar',\n";
                #    $word_line .="\t\t\t\tbarWidth:60,\n";
                    $word_line .="\t\t\t\tanimation:false,\n";
                    $word_line .="\t\t\t\tanimationDuration:1000,\n";
                    $word_line .="\t\t\t\tanimationDurationUpdate:1000,\n";
                    $word_line .="\t\t\t\tdata:datadown${j}\n";
                    $word_line .="\t\t\t},\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\titemStyle:{ \n";
                    $word_line .="\t\t\t\t\tnormal:{ \n";
                    $word_line .="\t\t\t\t\t\tlabel:{ \n";
                    $word_line .="\t\t\t\t\t\t\tshow: true, \n";
                    $word_line .="\t\t\t\t\t\t\tposition:'top'\n";
                    $word_line .="\t\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\n";
                    $word_line .="\t\t\t\t},\n";
                    $word_line .="\t\t\t\tname:datal${j}[0],\n";
                    $word_line .="\t\t\t\ttype:'bar',\n";
                 #   $word_line .="\t\t\t\tbarWidth:60,\n";
                    $word_line .="\t\t\t\tanimation:false,\n";
                    $word_line .="\t\t\t\tanimationDuration:1000,\n";
                    $word_line .="\t\t\t\tanimationDurationUpdate:1000,\n";
                    $word_line .="\t\t\t\tdata:dataup${j}\n";
                    $word_line .="\t\t\t}\n";
                    $word_line .="\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }         
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t\t\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }
        }
        elsif($echarts_type eq "Histogram distribution"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"Histogram distribution$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'Histogram distribution$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tvar ssdata;\n";
                $word_line .="\t\tvar yName;\n";
                $word_line .="\t\tvar xName;\n";
                $word_line .="\t\tvar x=[];\n";
                $word_line .="\t\tvar y=[];\n";
                $word_line .="\t\tvar datan=[];\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\tssdata = info[\"data\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tfor(var i=0;i<ssdata.length;i++){\n";
                $word_line .="\t\t\tx[i]=ssdata[i][0];\n";
                $word_line .="\t\t\ty[i]=ssdata[i][1];\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tdatan = [x,y];\n";
                $word_line .="\t\tvar option ={\n";
                $word_line .="\t\t\tcolor: ['#3398DB'],\n";
                $word_line .="\t\t\ttooltip : {\n";
                $word_line .="\t\t\t\tshow:false,\n";
               # $word_line .="\t\t\t\tshowContent:false,\n";
                $word_line .="\t\t\t\ttrigger: 'axis' ,\n";
                $word_line .="\t\t\t\taxisPointer : {  \n";
                $word_line .="\t\t\t\t\ttype : 'shadow'\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tformatter: ''\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\t\tdataZoom: {}, \n";
                $word_line .="\t\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis : [{\n";
                $word_line .="\t\t\t\t\ttype : 'category',\n";
                $word_line .="\t\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\t\tnameGap:20,\n";
                $word_line .="\t\t\t\t\tdata : x,\n";
                $word_line .="\t\t\t\t\tname:xName,\n";
                #$word_line .="\t\t\t\t\tname:'FPKM Value',\n";
                $word_line .="\t\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\t\taxisLabel:{margin:5},\n";
                $word_line .="\t\t\t\t\taxisTick: {\n";
                $word_line .="\t\t\t\t\t\talignWithLabel: true\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t}],\n";
                $word_line .="\t\t\tyAxis : [{\n";
                $word_line .="\t\t\t\t\taxisLabel:{margin:5},\n";
                $word_line .="\t\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\t\tname:yName,\n";
                #$word_line .="\t\t\t\t\tname:'GeneNumber',\n";
                $word_line .="\t\t\t\t\ttype : 'value'\n";
                $word_line .="\t\t\t}],\n";
                $word_line .="\t\t\tseries : [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tbarWidth:50,\n";
                $word_line .="\t\t\t\tname:'total',\n";
                $word_line .="\t\t\t\ttype:'bar',\n";
                $word_line .="\t\t\t\tdata: datan[1],\n";
                $word_line .="\t\t\t\titemStyle:{\n";
                $word_line .="\t\t\t\t\tnormal:{\n";
                $word_line .="\t\t\t\t\t\tlabel:{ \n";
                $word_line .="\t\t\t\t\t\tshow: false\n";
                $word_line .="\t\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\t\ttextStyle:{\n";
                $word_line .="\t\t\t\t\t\tcolor:'black',\n";
                $word_line .="\t\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";

            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"Histogram distribution$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'Histogram distribution$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";                
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar sdata${j}=[];\n";
                    $word_line .="\tvar yName${j}=\"\";\n";
                    $word_line .="\tvar xName${j}=\"\";\n";
                    $word_line .="\tvar x${j}=[];\n";
                    $word_line .="\tvar y${j}=[];\n";
                    $word_line .="\tvar datan${j}=[];\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\tsdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tfor(var i=0;i<sdata${j}.length;i++){\n";
                        $word_line .="\t\t\tx${j}[i] = sdata${j}[i][0]\n";
                        $word_line .="\t\t\ty${j}[i] = sdata${j}[i][1]\n";
                        $word_line .="\t\t\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\tdatan${j} = [x${j},y${j}];\n";
                        $word_line .="\t\t\n";
                        $word_line .="\t\t\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option ={\n";
                $word_line .="\t\t\tbaseOption: {\n";
                $word_line .="\t\t\t\tcolor: ['#3398DB'],\n";
                $word_line .="\t\t\t\ttooltip : {\n";
                $word_line .="\t\t\t\t\ttrigger: 'axis',\n";
                $word_line .="\t\t\t\t\taxisPointer : {\n";
                $word_line .="\t\t\t\t\t\ttype : 'shadow'\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter: '{b0}: {c0}<br />'\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\t\taxisType: 'category',\n";
                $word_line .="\t\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\t\tzlevel:-1,\n";
                $word_line .="\t\t\t\t\tz:-1,\n";
                $word_line .="\t\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                    $word_line .="\t\t\t\t\t{\n";
                    $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                    $word_line .="\t\t\t\t\ttooltip: {\n";
                    $word_line .="\t\t\t\t\tformatter: '{b}'\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t},\n";
                }                
                $word_line .="\t\t\t\t\t],\n";
                $word_line .="\t\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\tdataZoom: {}, \n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\txAxis :{\t\n";
                $word_line .="\t\t\t\t\ttype : 'category',\n";
                $word_line .="\t\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\t\tdata : x1,\n";
                $word_line .="\t\t\t\t\tname:'FPKM Value',\n";
                $word_line .="\t\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\t\taxisLabel:{margin:5},\n";
                $word_line .="\t\t\t\t\taxisTick: {\n";
                $word_line .="\t\t\t\t\t\talignWithLabel: true\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\tyAxis : {\n";
                $word_line .="\t\t\t\t\taxisLabel:{margin:5},\n";
                $word_line .="\t\t\t\t\tnameGap:30,\n";
                $word_line .="\t\t\t\t\tsplitLine:{\n";
                $word_line .="\t\t\t\t\t\tshow:false\n";
                $word_line .="\t\t\t\t\t},\n";
               # $word_line .="\t\t\t\t\tnameLocation:'middle',\n";
                $word_line .="\t\t\t\t\tname:'GeneNumber',\n";
                $word_line .="\t\t\t\t\ttype : 'value'\n";
                $word_line .="\t\t\t\t},\n";               
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions: [\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t\t{\n";
                    $word_line .="\t\t\t\txAxis:{name:xName${j}},\n";
                    $word_line .="\t\t\t\tyAxis:{name:yName${j}},\n";
		            $word_line .="\t\t\t\t\tseries:[{\n";
                    $word_line .="\t\t\t\t\tbarWidth:50,\n";
                    $word_line .="\t\t\t\t\tname:'total',\n";
                    $word_line .="\t\t\t\t\ttype:'bar', \n";
                    $word_line .="\t\t\t\t\tdata: datan${j}[1],\n";
                    $word_line .="\t\t\t\t\titemStyle:{ \n";
                    $word_line .="\t\t\t\t\t\tnormal:{ \n";
                    $word_line .="\t\t\t\t\t\t\tlabel:{\n";
                    $word_line .="\t\t\t\t\t\t\tshow: false\n";
                    $word_line .="\t\t\t\t\t\t\t},\n";
                    $word_line .="\t\t\t\t\t\t\ttextStyle:{\n";
                    $word_line .="\t\t\t\t\t\t\tcolor:'black',\n";
                    $word_line .="\t\t\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t}]\n";
                    $word_line .="\t\t\t\t},\n";
                    
                }
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }
        }
        elsif($echarts_type eq "Scatter plots"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"Scatter plots$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'Scatter plots$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tvar rawdata = [];\n";
                $word_line .="\t\tvar yName = \"\";\n";
                $word_line .="\t\tvar xName = \"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\trawdata = info[\"data\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar dataup=[];\n";
                $word_line .="\t\tvar datadown=[];\n";
                $word_line .="\t\tvar dataelse=[];\n";
                $word_line .="\t\tfor(var i=1;i<rawdata.length;i++){\n";
                $word_line .="\t\t\tif(rawdata[i][2]==\"Up\"){\n";
                $word_line .="\t\t\t\tdataup.push(rawdata[i].slice(0,2));\n";
                $word_line .="\t\t\t}else if(rawdata[i][2]==\"Down\"){\n";
                $word_line .="\t\t\t\tdatadown.push(rawdata[i].slice(0,2));\n";
                $word_line .="\t\t\t}else{\n";
                $word_line .="\t\t\t\tdataelse.push(rawdata[i].slice(0,2));\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttitle: {\n";
                $word_line .="\t\t\t\ttextStyle:{fontSize:16},left:'center'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\ttrigger: 'axis', \n";
               # $word_line .="\t\t\tformatter: '{b}<br />{a0}: {c0}<br />{a1}: {c1}<br />{a2}: {c2}<br /> ',\n";
                $word_line .="\t\t\tshowDelay : 0,\n";
                $word_line .="\t\t\taxisPointer:{\n";
                $word_line .="\t\t\t\tshow: true,\n";
                $word_line .="\t\t\t\ttype : 'cross',\n";
                $word_line .="\t\t\t\tlineStyle: {\n";
                $word_line .="\t\t\t\t\ttype : 'dashed',\n";
                $word_line .="\t\t\t\t\twidth : 1\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t},\n";
               # $word_line .="\t\t\tshowContent:false\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend: {data:['Up','Down','No'],top:28},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\tname:  xName,\n";
                #$word_line .="\t\t\t\tname:  'Log10(Gene Expression Level)',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\taxisLabel:{margin:2},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\t show:false\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\tname:  yName,\n";
               # $word_line .="\t\t\t\tname:  'Log10(Gene Expression Level)',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{color:'#333',fontSize:16},\n";
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\taxisTick:{show:false}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tseries: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname:'Up',\n";
                $word_line .="\t\t\t\ttype:'scatter',\n";
                $word_line .="\t\t\t\tlarge: true,\n";
                $word_line .="\t\t\t\tsymbolSize: 3,\n";
                $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                $word_line .="\t\t\t\thoverAnimation:false,\n";
                $word_line .="\t\t\t\tanimation:false,\n";
                $word_line .="\t\t\t\tanimationDuration:2000,\n";
                $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                $word_line .="\t\t\t\tdata:dataup\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname:'Down',\n";
                $word_line .="\t\t\t\ttype:'scatter',\n";
                $word_line .="\t\t\t\tlarge: true,\n";
                $word_line .="\t\t\t\tsymbolSize: 3,\n";
                $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                $word_line .="\t\t\t\thoverAnimation:false,\n";
                $word_line .="\t\t\t\tanimation:false,\n";
                $word_line .="\t\t\t\tanimationDuration:2000,\n";
                $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                $word_line .="\t\t\t\tdata:datadown\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname:'No',\n";
                $word_line .="\t\t\t\ttype:'scatter',\n";
                $word_line .="\t\t\t\tlarge: true,\n";
                $word_line .="\t\t\t\tsymbolSize: 3,\n";
                $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                $word_line .="\t\t\t\thoverAnimation:false,\n";
                $word_line .="\t\t\t\tanimation:false,\n";
                $word_line .="\t\t\t\tanimationDuration:2000,\n";
                $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                $word_line .="\t\t\t\tdata:dataelse\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }elsif($num_file > 1){
                my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"Scatter plots$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'Scatter plots$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";                
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\tvar srowdata${j}=[];\n";
                    $word_line .="\tvar yName${j}=\"\";\n";
                    $word_line .="\tvar xName${j}=\"\";\n";
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\tsrowdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar dataup${j}=[];\n";
                        $word_line .="\t\tvar datadown${j}=[];\n";
                        $word_line .="\t\tvar dataelse${j}=[];\n";
                        $word_line .="\t\tfor(var i=1;i<srowdata${j}.length;i++){\n";
                        $word_line .="\t\t\tif(srowdata${j}[i][2]==\"Up\"){\n";
                        $word_line .="\t\t\t\tdataup${j}.push(srowdata${j}[i].slice(0,2));\n";
                        $word_line .="\t\t\t}else if(srowdata${j}[i][2]==\"Down\"){\n";
                        $word_line .="\t\t\t\tdatadown${j}.push(srowdata${j}[i].slice(0,2));\n";
                        $word_line .="\t\t\t}else{\n";
                        $word_line .="\t\t\t\tdataelse${j}.push(srowdata${j}[i].slice(0,2));\n";
                        $word_line .="\t\t\t}\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\t\n";
                        $word_line .="\t\t\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tbaseOption: {\n";
                $word_line .="\t\t\ttitle: {\n";
                $word_line .="\t\t\t\ttextStyle:{fontSize:16},left:'center'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\t\taxisType: 'category',\n";
                $word_line .="\t\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\t\tzlevel:-1,\n";
                $word_line .="\t\t\t\t\tz:-1,\n";
                $word_line .="\t\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                    $word_line .="\t\t\t\t\t{\n";
                    $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                    $word_line .="\t\t\t\t\ttooltip: {\n";
                    $word_line .="\t\t\t\t\tformatter: '{b}'\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t},\n";
                }                
                $word_line .="\t\t\t\t\t],\n";
                $word_line .="\t\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\ttrigger: 'axis', \n";
               # $word_line .="\t\t\tformatter: '{b}<br />{a0}: {c0}<br />{a1}: {c1}<br />{a2}: {c2}<br /> ',\n";
                $word_line .="\t\t\tshowDelay : 0,\n";
                $word_line .="\t\t\taxisPointer:{\n";
                $word_line .="\t\t\t\tshow: true,\n";
                $word_line .="\t\t\t\ttype : 'cross',\n";
                $word_line .="\t\t\t\tlineStyle: {\n";
                $word_line .="\t\t\t\t\ttype : 'dashed',\n";
                $word_line .="\t\t\t\t\twidth : 1\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t},\n";
               # $word_line .="\t\t\tshowContent:false\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend: {data:['Up','Down','No'],top:28},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\tname:  'Log10(Gene Expression Level)',\n";
                $word_line .="\t\t\t\tnameLocation: 'end',\n";
                $word_line .="\t\t\t\taxisLabel:{margin:2},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\t show:false\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\tname:  'Log10(Gene Expression Level)',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{color:'#333',fontSize:16},\n";
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\taxisTick:{show:false}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions: [\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\txAxis:{name:xName},\n";
                    $word_line .="\t\t\tyAxis:{name:yName},\n";
                    $word_line .="\t\t\ttitle: {text: 'Up('+dataup${j}.length+') '+'Down('+datadown${j}.length+') '+'No('+dataelse${j}.length+')'},\n";
                    $word_line .="\t\t\tseries: [\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname:'Up',\n";
                    $word_line .="\t\t\t\ttype:'scatter',\n";
                    $word_line .="\t\t\t\tlarge: true,\n";
                    $word_line .="\t\t\t\tsymbolSize: 3,\n";
                    $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                    $word_line .="\t\t\t\thoverAnimation:false,\n";
                    $word_line .="\t\t\t\tanimation:false,\n";
                    $word_line .="\t\t\t\tanimationDuration:2000,\n";
                    $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                    $word_line .="\t\t\t\tdata:dataup${j}\n";
                    $word_line .="\t\t\t},\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname:'Down',\n";
                    $word_line .="\t\t\t\ttype:'scatter',\n";
                    $word_line .="\t\t\t\tlarge: true,\n";
                    $word_line .="\t\t\t\tsymbolSize: 3,\n";
                    $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                    $word_line .="\t\t\t\thoverAnimation:false,\n";
                    $word_line .="\t\t\t\tanimation:false,\n";
                    $word_line .="\t\t\t\tanimationDuration:2000,\n";
                    $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                    $word_line .="\t\t\t\tdata:datadown${j}\n";
                    $word_line .="\t\t\t},\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname:'No',\n";
                    $word_line .="\t\t\t\ttype:'scatter',\n";
                    $word_line .="\t\t\t\tlarge: true,\n";
                    $word_line .="\t\t\t\tsymbolSize: 3,\n";
                    $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                    $word_line .="\t\t\t\thoverAnimation:false,\n";
                    $word_line .="\t\t\t\tanimation:false,\n";
                    $word_line .="\t\t\t\tanimationDuration:2000,\n";
                    $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                    $word_line .="\t\t\t\tdata:dataelse${j}\n";
                    $word_line .="\t\t\t}\n";
                    $word_line .="\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";
            }
        }
        elsif($echarts_type eq "Volcano graph"){
            if($num_file eq 1){
                my $fig_path = "";
                my $fig_dir = $fig_file[0][0];
                $fig_dir =~ /(.+\/)/;
                $fig_dir = $1;
                # create the folder 
                if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                }
                if(-e "$data_path/$fig_file[0][0]"){
                    if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[0][0]")){
                        system("cp -prf '$data_path/$fig_file[0][0]' '$outdir/report/src/page/$fig_dir'");
                    }
                    $fig_path = $fig_file[0][0];
                }else{
                    print "The file $data_path/$fig_file[0][0] does not exist.\n";
                }
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"Volcano graphs$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'Volcano graphs$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\tvar rawdata = [];\n";
                $word_line .="\t\tvar xName = \"\";\n";
                $word_line .="\t\tvar yName = \"\";\n";
                $word_line .="\t\t\$\.getJSON(\"$fig_file[0][0]\",function(data){\n";
                $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                $word_line .="\t\t\t\trawdata = info[\"data\"];\n";
                $word_line .="\t\t\t\txName = info[\"xName\"];\n";
                $word_line .="\t\t\t\tyName = info[\"yName\"];\n";
                $word_line .="\t\t\t});\n";
                $word_line .="\t\t});\n";
                $word_line .="\t\tvar datatrue=[];\n";
                $word_line .="\t\tvar datafalse=[];\n";
                $word_line .="\t\tfor(var i=1;i<rawdata.length;i++){\n";
                $word_line .="\t\t\tif(rawdata[i][2]==\"FLASE\"){\n";
                $word_line .="\t\t\t\tdatafalse.push(rawdata[i].slice(0,2));\n";
                $word_line .="\t\t\t}else{\n";
                $word_line .="\t\t\t\tdatatrue.push(rawdata[i].slice(0,2));\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t}\n";
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\ttitle: {\n";
                $word_line .="\t\t\t\ttextStyle:{fontSize:16},left:'center',text: 'FALSE('+datafalse.length+') '+'TRUE('+datatrue.length+')'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\ttrigger: 'axis', \n";
               # $word_line .="\t\t\tformatter: '{b}<br />{a0}: {c0}<br />{a1}: {c1}<br />{a2}: {c2}<br /> ',\n";
                $word_line .="\t\t\tshowDelay : 0,\n";
                $word_line .="\t\t\taxisPointer:{\n";
                $word_line .="\t\t\t\tshow: true,\n";
                $word_line .="\t\t\t\ttype : 'cross',\n";
                $word_line .="\t\t\t\tlineStyle: {\n";
                $word_line .="\t\t\t\t\ttype : 'dashed',\n";
                $word_line .="\t\t\t\t\twidth : 1\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t},\n";
               # $word_line .="\t\t\tshowContent:false\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend: {data:['FLASE','TRUE'],top:28},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\tname: xName,\n";
                #$word_line .="\t\t\t\tname:  'Log2(Fold change)',\n";
                $word_line .="\t\t\t\tnameLocation: 'end',\n";
                $word_line .="\t\t\t\taxisLabel:{margin:2},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\t show:false\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\tname:  yName,\n";
                #$word_line .="\t\t\t\tname:  '-Log10(FDR)',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{color:'#333',fontSize:16},\n";
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\taxisTick:{show:false}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tseries: [\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname:'FLASE',\n";
                $word_line .="\t\t\t\ttype:'scatter',\n";
                $word_line .="\t\t\t\tlarge: true,\n";
                $word_line .="\t\t\t\tsymbolSize: 3,\n";
                $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                $word_line .="\t\t\t\thoverAnimation:false,\n";
                $word_line .="\t\t\t\tanimation:false,\n";
                $word_line .="\t\t\t\tanimationDuration:2000,\n";
                $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                $word_line .="\t\t\t\tdata:datafalse\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t{\n";
                $word_line .="\t\t\t\tname:'TRUE',\n";
                $word_line .="\t\t\t\ttype:'scatter',\n";
                $word_line .="\t\t\t\tlarge: true,\n";
                $word_line .="\t\t\t\tsymbolSize: 3,\n";
                $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                $word_line .="\t\t\t\thoverAnimation:false,\n";
                $word_line .="\t\t\t\tanimation:false,\n";
                $word_line .="\t\t\t\tanimationDuration:2000,\n";
                $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                $word_line .="\t\t\t\tdata:datatrue\n";
                $word_line .="\t\t\t}\n";
                $word_line .="\t\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\t\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";;
            }elsif($num_file > 1){
                 my @fig_path;
                #my $fig_length = @fig_file;
                $word_line .= "\t<div><a name = \'figure$hash_num_figure{$type_label}\'></a></div>\n";
                $word_line .= "\t<div class=\"toPage\"  id=\"Volcano graph$hash_num_figure{$type_label}\" style=\"width: 700px;height:500px;margin-top:1.5em;margin-bottom:1.2em;\"></div>\n";
                $word_line .="\t<script type=\"text/javascript\">\n";
                $word_line .="\t\tvar myChart = echarts.init(document.getElementById(\'Volcano graph$hash_num_figure{$type_label}\'));\n";
                $word_line .="\t\t\$\.ajaxSetup({\n";
                $word_line .="\t\t\tasync:false,\n";
                $word_line .="\t\t\tcache:false\n";
                $word_line .="\t\t});\n";                
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    my $fig_dir = $fig_file[$i][0];
                    $fig_dir =~ /(.+\/)/;
                    $fig_dir = $1;
                    if(!(-d "$outdir/report/src/page/$fig_dir")){
                        system("mkdir -p '$outdir/report/src/page/$fig_dir'");
                    }
                    if(-e "$data_path/$fig_file[$i][0]"){
                        if(!(-e "$outdir/report/src/page/$fig_dir/$fig_file[$i][0]")){
                            system("cp -prf '$data_path/$fig_file[$i][0]' '$outdir/report/src/page/$fig_dir'");
                        }
                        push @fig_path, [$fig_file[$i][0], $fig_file[$i][1]];
                        $word_line .="\t\tvar rawdata${j} = [];\n";
                        $word_line .="\t\tvar yName${j} = \"\";\n";
                        $word_line .="\t\tvar xName${j} = \"\";\n";
                        $word_line .="\t\t\$\.getJSON(\"$fig_file[$i][0]\",function(data){\n";
                        $word_line .="\t\t\t\$\.each(data,function(i,info){\n";
                        $word_line .="\t\t\t\trawdata${j} = info[\"data\"];\n";
                        $word_line .="\t\t\t\tyName${j} = info[\"yName\"];\n";
                        $word_line .="\t\t\t\txName${j} = info[\"xName\"];\n";
                        $word_line .="\t\t\t});\n";
                        $word_line .="\t\t});\n";
                        $word_line .="\t\tvar datatrue${j}=[];\n";
                        $word_line .="\t\tvar datafalse${j}=[];\n";
                        $word_line .="\t\tfor(var i=1;i<rawdata${j}.length;i++){\n";
                        $word_line .="\t\t\tif(rawdata${j}[i][2]==\"FLASE\"){\n";
                        $word_line .="\t\t\t\tdatafalse${j}.push(rawdata${j}[i].slice(0,2));\n";
                        $word_line .="\t\t\t}else{\n";
                        $word_line .="\t\t\t\tdatatrue${j}.push(rawdata${j}[i].slice(0,2));\n";
                        $word_line .="\t\t\t}\n";
                        $word_line .="\t\t}\n";
                        $word_line .="\t\t\n";
                        $word_line .="\t\t\n";
                    }else{
                        print "The file $data_path/$fig_file[$i][0] does not exist.\n";
                    }
                }
                $word_line .="\t\tvar option = {\n";
                $word_line .="\t\t\tbaseOption: {\n";
                $word_line .="\t\t\ttitle: {\n";
                $word_line .="\t\t\t\ttextStyle:{fontSize:16},left:'center'\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t\ttimeline: {\n";
                $word_line .="\t\t\t\t\taxisType: 'category',\n";
                $word_line .="\t\t\t\t\tautoPlay: false,\n";
                $word_line .="\t\t\t\t\tplayInterval: 1500,\n";
                $word_line .="\t\t\t\t\tbottom:0,\n";
                $word_line .="\t\t\t\t\tzlevel:-1,\n";
                $word_line .="\t\t\t\t\tz:-1,\n";
                $word_line .="\t\t\t\t\torient:'vertical',\n";
                $word_line .="\t\t\t\t\ttop:17,\n";
                $word_line .="\t\t\t\t\tright:-5,\n";
                $word_line .="\t\t\t\t\tleft:625,\n";
                $word_line .="\t\t\t\t\tdata: [\n";
                for my $i (0 .. $#fig_file){
                    $word_line .="\t\t\t\t\t{\n";
                    $word_line .="\t\t\t\t\t\tvalue: \'$fig_file[$i][1]\',\n";
                    $word_line .="\t\t\t\t\ttooltip: {\n";
                    $word_line .="\t\t\t\t\tformatter: '{b}'\n";
                    $word_line .="\t\t\t\t\t}\n";
                    $word_line .="\t\t\t\t\t},\n";
                }                
                $word_line .="\t\t\t\t\t],\n";
                $word_line .="\t\t\t\t\tlabel: {\n";
                $word_line .="\t\t\t\t\tposition:{\n";
                $word_line .="\t\t\t\t\t\n";
                $word_line .="\t\t\t\t\t},\n";
                $word_line .="\t\t\t\t\tformatter : function(s) {\n";
                $word_line .="\t\t\t\t\tif(s.length>6){\n";
                $word_line .="\t\t\t\t\treturn (s.substr(0,6)+'..');\n";
                $word_line .="\t\t\t\t\t}else{\n";
                $word_line .="\t\t\t\t\treturn s;\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t\t}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\ttooltip: {\n";
                $word_line .="\t\t\ttrigger: 'axis', \n";
               # $word_line .="\t\t\tformatter: '{b}<br />{a0}: {c0}<br />{a1}: {c1}<br />{a2}: {c2}<br /> ',\n";
                $word_line .="\t\t\tshowDelay : 0,\n";
                $word_line .="\t\t\taxisPointer:{\n";
                $word_line .="\t\t\t\tshow: true,\n";
                $word_line .="\t\t\t\ttype : 'cross',\n";
                $word_line .="\t\t\t\tlineStyle: {\n";
                $word_line .="\t\t\t\t\ttype : 'dashed',\n";
                $word_line .="\t\t\t\t\twidth : 1\n";
                $word_line .="\t\t\t\t},\n";
                $word_line .="\t\t\t\t\n";
                $word_line .="\t\t\t},\n";
               # $word_line .="\t\t\tshowContent:false\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tlegend: {data:['FLASE','TRUE'],top:28},\n";
                $word_line .="\t\t\ttoolbox:{\n";
                $word_line .="\t\t\t\tfeature:{\n";
                $word_line .="\t\t\t\tdataZoom: {},\n";
                $word_line .="\t\t\t\trestore: {},\n";
                $word_line .="\t\t\t\tdataView: {},\n";
                $word_line .="\t\t\t\tsaveAsImage:{}\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\txAxis: {\n";
                $word_line .="\t\t\t\tname:  'Log2(Fold change)',\n";
                $word_line .="\t\t\t\tnameLocation: 'end',\n";
                $word_line .="\t\t\t\taxisLabel:{margin:2},\n";
                $word_line .="\t\t\t\taxisTick:{\n";
                $word_line .="\t\t\t\t\t show:false\n";
                $word_line .="\t\t\t\t}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\tyAxis: {\n";
                $word_line .="\t\t\t\tname:  '-Log10(FDR)',\n";
                $word_line .="\t\t\t\tnameLocation: 'middle',\n";
                $word_line .="\t\t\t\tnameTextStyle:{color:'#333',fontSize:16},\n";
                $word_line .="\t\t\t\tnameGap:48,\n";
                $word_line .="\t\t\t\ttype: 'value',\n";
                $word_line .="\t\t\t\taxisTick:{show:false}\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\t},\n";
                $word_line .="\t\t\toptions: [\n";
                for my $i (0 .. $#fig_file){
                    my $j = $i+1;
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\tyAxis:{name:yName${j}},\n";
                    $word_line .="\t\t\txAxis:{name:xName${j}},\n";
                    $word_line .="\t\t\ttitle: {text: 'FALSE('+datafalse${j}.length+') '+'TRUE('+datatrue${j}.length+')'},\n";
                    $word_line .="\t\t\tseries: [\n";
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname:'FLASE',\n";
                    $word_line .="\t\t\t\ttype:'scatter',\n";
                    $word_line .="\t\t\t\tlarge: true,\n";
                    $word_line .="\t\t\t\tsymbolSize: 3,\n";
                    $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                    $word_line .="\t\t\t\thoverAnimation:false,\n";
                    $word_line .="\t\t\t\tanimation:false,\n";
                    $word_line .="\t\t\t\tanimationDuration:2000,\n";
                    $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                    $word_line .="\t\t\t\tdata:datafalse${j}\n";
                    $word_line .="\t\t\t},\n";
                    
                    $word_line .="\t\t\t{\n";
                    $word_line .="\t\t\t\tname:'TRUE',\n";
                    $word_line .="\t\t\t\ttype:'scatter',\n";
                    $word_line .="\t\t\t\tlarge: true,\n";
                    $word_line .="\t\t\t\tsymbolSize: 3,\n";
                    $word_line .="\t\t\t\tlargeThreshold:20000,\n";
                    $word_line .="\t\t\t\thoverAnimation:false,\n";
                    $word_line .="\t\t\t\tanimation:false,\n";
                    $word_line .="\t\t\t\tanimationDuration:2000,\n";
                    $word_line .="\t\t\t\tanimationDurationUpdate:2000,\n";
                    $word_line .="\t\t\t\tdata:datatrue${j}\n";
                    $word_line .="\t\t\t}\n";
                    $word_line .="\t\t\t]\n";
                    $word_line .="\t\t\t},\n";
                }
                $word_line .="\t\t]\n";
                $word_line .="\t\t};\n";
                $word_line .="\t\tmyChart.setOption(option);\n";
                $word_line .="\t</script>\n";;
            
            }
        }
        if($flag_title){
                # the title exists
                if($flag_desc){
                    # the figure desc exists
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        # add "." between figure title and figure desc
                        if(!($fig_title =~ /^(.*?)。\s*$/)){
                            $fig_title .= "。";
                        }
                    }else{
                        if(!($fig_title =~ /^(.*?)\.\s*$/)){
                            $fig_title .= ".";
                        }
                    }
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        $word_line .= "\t<div class = \"p1 img_title\"><b>$buttonFigure$hash_num_figure{$type_label}&nbsp;$fig_title</b>&nbsp;$fig_desc</div>\n\n\n";
                    }else{
                        $word_line .= "\t<div class = \"p1 img_title\"><b>$buttonFigure $hash_num_figure{$type_label}&nbsp;$fig_title</b>&nbsp;$fig_desc</div>\n\n\n";
                    }
                }else{
                    # the figure desc does not exists
                    if($arf_lan eq "cn" || $arf_lan eq "CN"){
                        $word_line .= "\t<div class = \"align_left img_title\"><b>$buttonFigure$hash_num_figure{$type_label}</b>&nbsp;$fig_title</div>\n\n\n";
                    }else{
                        $word_line .= "\t<div class = \"align_left img_title\"><b>$buttonFigure $hash_num_figure{$type_label}</b>&nbsp;$fig_title</div>\n\n\n";
                    }
                }
        }
    
    }
	push @website_content , [ "0", $type_label, $now_title, $word_line ];
	push @number_figure, [$type_label, $now_title, $fig_num, $hash_num_figure{$type_label}];
	if($type_label eq "Results"){
		# if the figure belong to Results.html, copy the figure to Figures.html
		push @website_content, [ "0", "Figures", $now_title, $word_line ];
		if($fig_title =~ /。$/){
			$fig_title =~ s/。$//;

		}elsif($fig_title =~ /.\s*$/){
			$fig_title =~ s/\.\s*$//;

		}
		# Figures.html, at the top of the website page, the figure title Hide or Show
		push @left_menu, ["Figures", "figure$hash_num_figure{$type_label}", "$hash_num_figure{$type_label} $fig_title"];
	}
}

sub reference_process(){
	# process the reference, if the reference already in the @number_reference, do not push it into @number_reference
	my @content = @_;
	my $flag_text = 0;
	my $flag_url = 0;
	my $flag = 0;
	my $ref_num = "";
	my $ref_text = "";
	my $ref_url = "";
	my $temp_num = "";	
	
	$word_line = "";
	
	$hash_num_reference{$type_label}++;
	
	#get the reference content from the arf
	foreach(@content){
		if(!$_){
                        next;
                }
		if($_ =~ /^number(.*?)$/){
                        if(!($1 =~ /^\s*?=\s*?(.*?)\s*?$/)){
	
                        }else{
				$ref_num = $1;
        	                #remove the space
	                        $ref_num =~ s/\s//g;
                        }
		}elsif($_ =~ /^text\s*?=\s*?"(.*?)"\s*?$/){
			$flag_text = 1;
			$ref_text = $1;
	
		}elsif($_ =~ /^url\s*?=\s*?(.*?)\s*?$/){
			$flag_url = 1;
			$ref_url = $1;
			$ref_url =~ s/\s//g;
		}
	}
	
	#####	translate into the website code		#####
#	$word_line .= "\t<div class = \"p\"><a href = \"$ref_url\" target = \"_blank\">[$num_ref] $ref_text</a></div>\n";
	# if the reference already in @number_reference, do not push it into @number_reference;
	for my $i ( 0 .. $#number_reference ) {
		if ( ($ref_url eq $number_reference[$i][5]) && ($ref_num eq $number_reference[$i][3]) ) {
			# exist in the \@number_reference, get the reference number
			$flag = 1;
		}		
	}
	
	if ( !$flag ) {
		push @number_reference, [ "0", $type_label, $now_title, $ref_num, "0", $ref_url, $ref_text ];
	} else {
		$flag = 0;
	}
}

sub glossary_process(){
	# process the glossary
	my @content = @_;
	my $flag_keyword = 0;
	my $flag_desc = 0;
	my @glo_key = "";
	my $string_key = "";
	my $glo_desc = "";
	$word_line = "";
	
	#get the glossary content from arf
	foreach(@content){
		if(!$_){
                        next;
                }
		if($_ =~ /^keyword\s*?=\s*?"(.*?)"\s*?$/){
			$flag_keyword = 1;
			$string_key = $1;
			my $temp_keywords = $1;
			# several keyword use the same desc
			#eg. keyword = AAA;BBB;CCC
			#    desc ABABABBAABABABABBABA
			if($temp_keywords =~ /;/){
				my @temp = (split /;/, $temp_keywords );
				foreach(@temp){
					push @glo_key, $_;
				}
			}else{
				push @glo_key, $temp_keywords;
			}
		}elsif($_ =~ /^desc\s*?=\s*?"(.*?)"\s*?$/){
			$flag_desc = 1;
			$glo_desc = $1;
		}	
	}
	
	

	#####	translate into the website code		#####
	if($flag_keyword && $flag_desc){
		foreach(@glo_key){
			if(!$_){
				next;
			}
			my $key = $_;
			push @glossary_content, [$type_label, $key, $glo_desc];
		}
		$word_line .= "\t<div class = \"g_title\">$string_key</div>\n";
                $word_line .= "\t<div class = \"g_content\">$glo_desc</div>\n";
		push @website_content, [ "0", $type_label, $now_title, $word_line ];
	}

}


# process the FAQs
sub FAQ_process(){
	my @content = @_;
        my $flag_question = 0;
        my $flag_answer = 0;
        my $question = "";
	# @answer: mark the FAQs answer, it may be several line;
        my @answer = "";
        my $word_line = "";

        #get the FAQ content from arf
        foreach(@content){
                if(!$_){
                        next;
                }
                if($_ =~ /^question\s*?=\s*?"(.*?)"\s*?$/){
                        $flag_question = 1;
                        $question = $1;

                }elsif($_ =~ /^answer\s*?=\s*?"(.*?)"\s*?$/){
                        $flag_answer = 1;
                        push @answer, $1;
                }
        }

        #####   translate into the website code         #####
        if($flag_question){
                $word_line = "\t<div class = \"g_title\">$question</div>\n";
                push @website_content , [ "0", $type_label,$now_title, $word_line ];
        }

        if($flag_answer){
                foreach(@answer){
                        if(!$_){
                                next;
                        }
                        $word_line = "\t<div class = \"g_content\">$_</div>\n";
                        push @website_content, [ "0", $type_label, $now_title, $word_line ];
                }
        }
}


# process the wrong label, but do not use it in creating the report
sub wrong_label_process(){
	#print the wrong label
	my @content = @_;
	my $wrong_label = $content[0];
	$wrong_label =~ s/\s//g;
	print $wrong_label;
#	print "Line:$error_line. The wrong label $wrong_label.\n";

}


#process the rich text ,such as \textit{\textbf{content}}
sub rich_text(){
	my @content2 = @_;
	
	my $content = $content2[0];
	while($content =~ /\\textit{(.*?)}/){
		my $temp = $1;
		$content =~ s/\\textit{.*?}/<i>$temp<\/i>/i;

	}
	while($content =~ /\\textbf\{(.*?)\}/){
		my $temp = $1;
		$content =~ s/\\textbf\{.*?\}/<b>$temp<\/b>/i;

	}
	while($content =~ /\\numthousand\{(.*?)\}/){
		my $temp = $1;
		my $result = &digitize($temp);
		$content =~ s/\\numthousand\{.*?\}/$result/i;

	}
	while($content =~ /\\underline\{(.*?)\}/){
                my $temp = $1;
                $content =~ s/\\underline\{.*?\}/<u>$temp<\/u>/i;

        }
	while($content =~ /\\\^{(.*?)}/){
		my $temp = $1;
		$content =~ s/\\\^{.*?}/<sup>$temp<\/sup>/i;

	}
	while($content =~ /\\_{(.*?)}/){
		my $temp = $1;
		$content =~ s/\\_{.*?}/<sub>$temp<\/sub>/i;

	}
	while($content =~ /\\url{(.*?)}/){
		my $temp = $1;
		$content =~ s/\\url{.*?}/<a href = \"$temp\" target = \"_blank\">$temp<\/a>/i;
	}
        while($content =~ /\\href{(.*?)}{(.*?)}/){
		my $url = "";
                my $path = "";
		my $showName = "";
                $url = $1;
		$showName = $2;
		
		# if the href is a direct, it will link the ftp(cdts)
                if ( -d "$data_path/$url" ) {
			$path = $url;
			if ( $demo ) {
				$content =~ s/\\href{.*?}{.*?}/<i>$showName<\/i>/i;
			} else {
				$content =~ s/\\href{.*?}{.*?}/<a href = \"ftp:\/\/$usermessage{cdtsUser}:$usermessage{cdtsPwd}\@$host\/$usermessage{dataPath}\/$path\" target=\"_blank\" >$showName<\/a>/i;
			}
		} elsif (-e "$data_path/$url"){
			# if it is a file, it will line the file path 
                        my $fig_dir = $url;
			#get the folder path
                        $fig_dir =~ /(.+\/)/;
                        $fig_dir = $1;
			#create the folder path
                        if(!(-d "$outdir/report/$fig_dir")){
                                system("mkdir -p '$outdir/report/$fig_dir'");
                        }

			if ( $url =~ /(.*?)\.tif$/ ) {
				#convert tif -> gif
				`$convert_path $data_path/$url $outdir/report/$1.gif`;
				$path = "../../$1.gif";
			}else{
				if(!(-e "$outdir/report/$url")){
                                	system("cp -rf '$data_path/$url' '$outdir/report/$fig_dir'");
				}
                                $path = "../../$url";
                        }
			$content =~ s/\\href{.*?}{.*?}/<a href = \"$path\" target = \"_blank\">$showName<\/a>/i;

                } else {
			# the href is website url
                        $path = $url;
			$content =~ s/\\href{.*?}{.*?}/<a href = \"$path\" target = \"_blank\">$showName<\/a>/i;

                }
        }
	
	return $content;	
}


###### 123456789 => 123,456,789
sub digitize{
	my $v = shift or return '0';
	$v =~ s/(?<=^\d)(?=(\d\d\d)+$)
		|
		(?<=^\d\d)(?=(\d\d\d)+$)
		|
		(?<=\d)(?=(\d\d\d)+\.)
		|
		(?<=\.\d\d\d)(?!$)
		|
		(?<=\G\d\d\d)(?!\.|$)
		/,/gx;
		return $v;
}

#process the table: float and scientific 
# eg. 123.4567 => 123.45 (it keep two  decimal point)
sub decimal{
        my ($type, $string, $number) = @_;
        $number =~ s/\s//g;
	$string =~ s/\s//g;
        $type =~ s/\s//g;
	my $flag = 0;
	if($string =~ /\%/){
		$flag = 1;
		$string =~ s/\%//;
	}	

        if($type eq "float"){
		if($number eq "0"){
			$string = int($string);
                }elsif($number eq "1"){
                        $string = sprintf"%.1f", $string;

                }elsif($number eq "2"){
                        $string = sprintf"%.2f", $string;

                }elsif($number eq "3"){
                        $string = sprintf"%.3f", $string;

                }elsif($number eq "4"){
                        $string = sprintf"%.4f", $string;

                }elsif($number eq "5"){
                        $string = sprintf"%.5f", $string;

		}elsif($number eq "6"){
                        $string = sprintf"%.6f", $string;

		}else{
			$string = sprintf"%.2f", $string;

		}
        }elsif($type eq "scientific"){
                if($number eq "1"){
                        $string = sprintf"%.1e", $string;

                }elsif($number eq "2"){
                        $string = sprintf"%.2e", $string;

                }elsif($number eq "3"){
                	$string = sprintf"%.3e", $string;

                }elsif($number eq "4"){
                        $string = sprintf"%.4e", $string;

                }elsif($number eq "5"){
                        $string = sprintf"%.5e", $string;

                }elsif($number eq "6"){
                        $string = sprintf"%.6e", $string;

                }elsif($number eq "7"){
                        $string = sprintf"%.7e", $string;

                }elsif($number eq "8"){
                        $string = sprintf"%.8e", $string;

                }elsif($number eq "9"){
                        $string = sprintf"%.9e", $string;

                }else{
			$string = sprintf"%.3e", $string;

		}
        }
	if($flag){
		$string .= "\%";
	}
        return $string;
}


##########	print program information	#########
sub usage{
	die "Description: This program is used to create the report.
	Version:	1.0
	Date:		16/03/2015
	\@author:	dengshengyuan\@genomics.cn

	Usage:
	\tperl $0 [options]
	Options:
	\t-i	<str>	the input arf folder path
	\t-d	<str>	the data path
	\t-t	<str>	the report template
	\t-o 	<str>	the output folder; default: ./
	\t-menu	<str>   change the report menu.For example: change the menu order(-menu \"Introductions,Results,Methods,Tables,Figures,References,FAQs,Help,Files\")
	\t-help|?	print help information

e.g:
\tperl $0 -i ./arf -d ./BGI_result -t ./template -o ./output 
";
}

#####	index_cn.html 	#####
sub index_cn(){
	my $temp_cn;
        $temp_cn = "\t<div class = \"link\">\n";
        $temp_cn .= "\t\t<div class = \"rightline\">\n";
        $temp_cn .= "\t\t\t<a href=\"../../report_cn.pdf\" target = \"_blank\">";
        $temp_cn .= "\t\t\t\t<img style=\"margin-top:20px;\" width=\"50px;\" height=\"50px;\" src=\"../img/pdf.jpg\" title=\"PDF Download\" alt=\"PDF\"/>\n";
        $temp_cn .= "\t\t\t</a>\n";
        $temp_cn .= "\t\t</div>\n";
        $temp_cn .= "\t</div>\n";
        $temp_cn .= "<div class = \"top\" onclick = \"javascript:scroll(0,0)\"></div>\n";
        return $temp_cn;
}

#####	index_en.html	#####
sub index_en(){
	my $temp_en;
        $temp_en = "\t<div class = \"link\">\n";
        $temp_en .= "\t\t<div class=\"rightline\">\n";
        $temp_en .= "\t\t\t<a href=\"../../report_en.pdf\" target = \"_blank\">\n";
        $temp_en .= "\t\t\t\t<img style=\"margin-top:20px;\" width=\"50px;\" height=\"50px;\" src=\"../img/pdf.jpg\" title=\"PDF Download\" alt=\"PDF\" />\n";
        $temp_en .= "\t\t\t</a>\n";
        $temp_en .= "\t\t</div>\n";
        $temp_en .= "\t</div>\n";
        $temp_en .= "<div class = \"top\" onclick = \"javascript:scroll(0,0)\"></div>\n";
        return $temp_en;
}

#####	the Chinese version n the English version	#####
sub index_all(){
	my @lan_index = @_;
	my $index_non;
	
	$index_non = "<div class=\"link\">\n";
	if($lan_index[0] eq "ALL_CN"){
		$index_non .= "\t\t<div class = \"rightline\">\n";
		$index_non .= "\t\t\t<div class = \"imgVersion toHtml\" url = \"Results.html\">\n";
		$index_non .= "\t\t\t</div>\n";
        	$index_non .= "\t\t\t<div class = \"line toHtml\" url = \"Results.html\">\n";
	        $index_non .= "\t\t\t\tEnglish\n";
        	$index_non .= "\t\t\t</div>\n";
	        $index_non .= "\t\t</div>\n";
	}elsif($lan_index[0] eq "ALL_EN"){
		$index_non .= "\t\t<div class = \"rightline\">\n";
		$index_non .= "\t\t\t<div class = \"imgVersion toHtml\" url = \"Results_cn.html\">\n";
		$index_non .= "\t\t\t</div>\n";
        	$index_non .= "\t\t\t<div class = \"line toHtml\" url = \"Results_cn.html\">\n";
	        $index_non .= "\t\t\t\t中文\n";
        	$index_non .= "\t\t\t</div>\n";
	        $index_non .= "\t\t</div>\n";
	}
	$index_non .= "\t<div class=\"rightline\">\n";
        if($lan_index[0] eq "ALL_CN"){
                $index_non .= "\t\t<a href=\"../../report_cn.pdf\" target = \"_blank\">\n";
                $index_non .= "\t\t\t\t<img style=\"margin-top:20px;\" width=\"50px;\" height=\"50px;\" src=\"../img/pdf.jpg\" title=\"PDF Download\" alt=\"PDF\" />\n";
                $index_non .= "\t\t\t</a>\n";

        }else{
                $index_non .= "\t\t<a href=\"../../report_en.pdf\" target = \"_blank\">\n";
                $index_non .= "\t\t\t\t<img style=\"margin-top:20px;\" width=\"50px;\" height=\"50px;\" src=\"../img/pdf.jpg\" title=\"PDF Download\" alt=\"PDF\" />\n";
                $index_non .= "\t\t\t</a>\n";

        }
        $index_non .= "\t\t</div>\n";
        $index_non .= "\t</div>\n";
        $index_non .= "<div class = \"top\" onclick = \"javascript:scroll(0,0)\"></div>";
        return $index_non;
}

########	logo	#########
sub add_logo(){
#This program process the the logo
	my $addlogo;
	if(!$logo){
		$addlogo = "<div class=\"logo_small toHtml\" url=\"http://www.bgitechsolutions.cn\"></div>";
	}else{
		#add an other logo, such as xbio
		$addlogo = "<div class=\"logo_small toHtml\" url=\"http://www.bgitechsolutions.cn\"></div>";
		$addlogo .= "<div class=\"logo_xbio\"></div>";
	}
	return $addlogo;
}


#reset the value
sub reset_value(){
	undef $exlabel;
	undef $lastlabel;
	undef $nowlabel;
	$error_line = 0;
	$line = 0;
	undef $type_label;
	undef $now_title;
	undef @each_title;
	undef @number_table_paragraph;
	undef @number_figure_paragraph;
	undef @number_reference_paragraph;
	undef @number_table;
	undef @number_figure;
	undef @number_reference;
	undef @sum_reference;
	undef @left_menu;
	undef %hash_num_title;
	undef %hash_num_table;
	undef %hash_num_figure;
	undef %hash_num_reference;
	$num_ref = 0;
	undef @content;
	undef @glossary_content;
	undef @website_content;
	undef $word_line;
	$num_text_content = 0;
	$flag_analysis = 0;
	undef @pdf_content;

}

#input the arf file
sub readArfList(){
        my @arf_name = @_;

        foreach(@arf_name){
                $line = 0;
                $lastlabel = "";
                $type_label = "";
                $now_title= "";
                $flag_analysis = 0;

                my $input_arf = $_;
                system("dos2unix $input_arf");

                if(-e $input_arf){
                        my $temp = abs_path($outdir);
                        #因为iconv转码需要转换为新的文件, temp_arf.txt是一个临时文件
                        my $temp_arf = "$temp/report/temp/temp_arf.txt";
                        #change the gbk or utf-8 to utf-8
                        my $type = `$enca_path -L zh_CN $input_arf`;
                        #|| $type =~ /Unrecognized/
                        if($type =~ /UTF-8/ || $type =~ /utf-8/){
                                #the arf file encoding is utf-8
                                system("$enca_path -L none -x utf-8 $input_arf");
                                &input_arf($input_arf);
                                system("rm -rf $input_arf");
                        }elsif($type =~ /Unrecognized/){
                                my $encode = "";
                                $encode = `file -bi $input_arf | sed -e 's/.*[ ]charset=//' |tr '[a-z]' '[A-Z]'`;
                                #if($encode =~ /UTF-8/ || $encode =~ /ISO-8859-1/){
				if($encode =~ /UTF-8/){
                                        #the arf file encoding is utf-8
                                        #system("/export/report/bin/bin/enca -L none -x utf-8 $input_arf");
                                        &input_arf($input_arf);
                                        system("rm -rf $input_arf");
                                }else{
                                        #the arf file encoding is GBK
                                        system("iconv -c -f GBK -t utf8 $input_arf > $temp_arf");
                                        &input_arf($temp_arf);
                                        system("rm -rf $temp_arf");
                                }
                        }else{
                                #the arf file encoding is not GBK
                                system("iconv -c -f GBK -t utf8 $input_arf > $temp_arf");
                                &input_arf($temp_arf);
                                system("rm -rf $temp_arf");
                        }
                }else{
                        print "ERROR: The file $input_arf doesn't exist.\n";
                }
        }
}


#create the HTML
sub createHtml(){
	# set the website language, default EN
	if($page_lan eq "CN"){
        	$lan_version = &index_cn();
	}elsif($page_lan eq "EN"){
        	$lan_version = &index_en();
	}elsif($page_lan eq "ALL_CN" || $page_lan eq "ALL_EN"){
        	#only English version
        	$lan_version = &index_all($page_lan);
	}else{
        	#the website language default EN
        	$lan_version = &index_en();
	}

	my @temp_report_menu;
	foreach(@report_menu_order){
        	if(!($_ eq "Glossaries")){
                	push @temp_report_menu, $_;
        	}
	}

	#translate \reference{1} into [1]
	&referenceIntoWebsite(\@website_content);
	
	#@report_menu_order
	# output the website report
	&output_report_website(\@temp_report_menu, \@left_menu, \@website_content);
	# print the PDF
	&create_pdf(@pdf_content);

	if($page_lan eq "cn" || $page_lan eq "CN"){
        	open F1,"$outdir/report/index.html" or die;
        	open F2,"+< $outdir/report/index.html" or die;

        	while(<F1>){
                	if($_ =~ /Results.html/){
                        	$_ =~ s/Results.html/Results_cn.html/;
                        	print F2 unless m/^#/;
                	}else{
				print F2 $_;
			}
        	}
        	truncate(F2,tell(F2));
        	close F1;
        	close F2;
	}
}

#modifi the file page, insert the dtree code.
sub modifiFilePage{
	my ($filePagePath, $filePageOutPath) = @_;
	my $wordline = "";
	open FILE, "$filePagePath" or die "Can not open $filePagePath";
	open FILEOUT, "> $filePageOutPath" or die "Can not open $filePageOutPath";
	
	while(my $line = <FILE>){
		chomp $line;
		if($line =~ /jquery.fancybox-1.3.4.css/){
			$wordline .= $line;
			$wordline .= "\t<link href=\"../css/jquery.treeview.css\" rel=\"stylesheet\" type=\"text/css\"/>\n";
			$wordline .= "\t<link href=\"../css/screen.css\" rel=\"stylesheet\" type=\"text/css\"/>\n";
			
		}elsif($line =~ /albumSider.js/){
			$wordline .= $line;
			$wordline .= "\t<script src=\"../js/jquery.cookie.js\" type=\"text/javascript\"></script>\n";
			$wordline .= "\t<script src=\"../js/jquery.treeview.js\" type=\"text/javascript\"></script>\n";

			$wordline .= "\t<script type=\"text/javascript\">\n";
			$wordline .= "\t\tfunction StandardTaxRate() {\n";
			$wordline .= "\t\t\t\$.ajax({\n";
			$wordline .= "\t\t\t\turl: \"tree.xml\",";
			$wordline .= "\t\t\t\tdataType: 'xml',";
			$wordline .= "\t\t\t\ttype: 'GET',\n";
			$wordline .= "\t\t\t\terror: function (xml) {\n";
			$wordline .= "\t\t\t\t\talert(\"加载XML 文件出错！\");\n";
			$wordline .= "\t\t\t\t},\n";
			$wordline .= "\t\t\t\tsuccess: function (xml) {\n";
			$wordline .= "\t\t\t\t\tvar nodes = \$(xml).find(\"tree\");\n";
			$wordline .= "\t\t\t\t\trefresh_project_item(nodes, \$(\"#browserDiv\"));\n";
			$wordline .= "\t\t\t\t\t\$(\"#browserDiv\").children(\"ul\").first().treeview();\n";
			$wordline .= "\t\t\t\t}\n";
			$wordline .= "\t\t\t});\n";
			$wordline .= "\t\t}\n";
			$wordline .= "\t\tfunction refresh_project_item(parent, p_div) {\n";
			$wordline .= "\t\t\t\$(parent).children().each(function (n, value) {\n";
			$wordline .= "\t\t\t\tvar ul = \$(\"<ul></ul>\");\n";
			$wordline .= "\t\t\t\t\$(p_div).append(ul);\n";
			$wordline .= "\t\t\t\t//如果标签为<dir name=\"***\"></dir>\n";
			$wordline .= "\t\t\t\tif (this.tagName == \"folderName\") {\n";
			$wordline .= "\t\t\t\t\tvar li = \$(\"<li></li>\");\n";
			$wordline .= "\t\t\t\t\t\$(li).append(\"<span class=\\\"folder\\\">\" + \$(this).attr(\"value\") + \"</span>\").appendTo(ul);";
			$wordline .= "\t\t\t\t\trefresh_project_item(this, li);\n";
			$wordline .= "\t\t\t\t} else {//标签为<file name=\"***\"/>，file一定是叶子节点\n";
			$wordline .= "\t\t\t\t\tvar li = \$(\"<li></li>\");\n";
			$wordline .= "\t\t\t\t\t\$(li).append(\"<span class=\\\"file\\\">\" + \$(this).attr(\"value\") + \"</span>\").appendTo(ul);\n";
			$wordline .= "\t\t\t\t}\n";
			$wordline .= "\t\t\t});\n";
			$wordline .= "\t\t}\n";
			$wordline .= "\t\t\$(function () {\n";
			$wordline .= "\t\t\tStandardTaxRate();\n";
			$wordline .= "\t\t});\n";
			$wordline .= "\t</script>";
			
		}elsif($line =~ /<div class = "content">/){
			my $downloadGuidance = "";
			my $downloadGuidancePDF = "";
			my $downloadGuidanceHost = "";
			my $downloadGuidancePath = "";
			if ( $filePageOutPath =~ /Files_cn.html/ ) {
				$downloadGuidance = "下载指南";
				$downloadGuidancePDF = "DownloadGuidance_CN.pdf";
			} else {
				$downloadGuidance = "Download Guidance";
				$downloadGuidancePDF = "DownloadGuidance_EN.pdf";
			}
			if ( $AREA eq "HK" ) {
				$downloadGuidanceHost = "cdts-hk.genomics.cn";
				$downloadGuidancePath = "http://xbio.genomics.cn/NGS/report";
			} elsif ( $AREA eq "WH" ) {
				$downloadGuidanceHost = "cdts-wh.genomics.cn";
				$downloadGuidancePath = "http://xbio2.genomics.cn/NGS/report"
			} elsif ( $AREA eq "SZ" ) {
				$downloadGuidanceHost = "cdts-sz.genomics.cn";
				$downloadGuidancePath = "http://xbio1.genomics.cn/NGS/report";				
			}
			$wordline .= $line;
			$wordline .= "\t\t<div class=\"download1\" style=\"margin-left:0px;margin-top:10px;\"><a href=\"ftp://$usermessage{cdtsUser}:$usermessage{cdtsPwd}\@$host/$usermessage{dataPath}\" target=\"_blank\" > <img width=\"120px\" src=\"../img/d2.png\" style=\"margin-top:8px;margin-left:10px; \"  alt=\"Data\"/></a>\n";
			$wordline .= "\t\t<div class=\"showMessage\" style=\"position:absolute;display:none; z-index:100; background-color:#f3f4f8;border:1px solid #767676; line-height:24px;padding-left:25px;padding-right:25px;margin-top:-20px;\">Download Files <br />Host: $downloadGuidanceHost <br /> Username: $usermessage{cdtsUser}<br />Password: $usermessage{cdtsPwd} </div>";
			$wordline .= "\t\t<span style=\"display:block;margin-left:150px;margin-top:-40px;margin-bottom:20px;\"><a href=\"$downloadGuidancePath/$downloadGuidancePDF\" target=\"_blank\">$downloadGuidance</a> </span></div>\n";
			$wordline .= "\t\t<div id=\"browserDiv\" class=\"filetree\" style=\"min-height:581px;margin-top:20px;margin-left:15px;\">\n";
			$wordline .= "\t\t</div>\n";
			
		}else{
			$wordline .= "$line\n";
		}		
	}	
	
	print FILEOUT "$wordline\n";
	close FILEOUT;
	close FILE;
}


#output the tree.xml
my $folderFlag = "0";
my $folderFlag2 = "0";
my $folderPre = "";

my $tempPre = "";
my $treeflag = 1;
my $treeflag2 = 1;

sub outPutTreexml{
	my ($in, $out) = @_;
	open OUT, "> $out" or die "Can not open the file.";

	print OUT "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
	print OUT "<trees>\n";
	print OUT " <tree id=\"1\">\n";

	$folderFlag = "0";
	$folderFlag2 = "0";
	$folderPre = "";
	$tempPre = "";
	$treeflag = 1;
	$treeflag2 = 1;

	&printDirTree($in);

	print OUT '     ','</folderName>', "\n";
	print OUT " </tree>\n";
	print OUT "</trees>\n";

	close OUT;
}


sub printDirTree{
        my $curr_dir = $_[0];

        #print the 'root' dir
        if(!$_[1]){
                my $dirname = $curr_dir;
                if($dirname =~ /^.*\/(.*?)\/$/ || $dirname =~ /^.*\/(.*?)$/){
                        $dirname = $1;
                        print OUT '     ','<folderName value="', $dirname, '">', "\n";
                }else{
                        print OUT '     ','<folderName value="', $dirname, '">', "\n";

                }
                $_[1] = '';
        }

        #get all entries in current dir except '.''..'
        opendir DIR, $curr_dir or die "Cannot open $curr_dir: $!\n";
        my @filesNotSort = grep { !/^(\.|\.\.)$/ } (readdir DIR);
	my @files = sort @filesNotSort;
        closedir DIR;

        for (0..$#files) {
                my $pre = $_[1];

                if ($_ < $#files) {
                        if(-d "$curr_dir/$files[$_]"){
				if($files[$_] =~ /^arf$/ || $files[$_] =~ /^resource$/ || $files[$_] =~ /^report$/ ){
                                        next;
                                }
				
                                $treeflag = 0;
                                $folderFlag2 = $folderFlag2 + 1;
                                $folderPre = $pre;
                                print OUT '     ', $pre, '<folderName value="', $files[$_], '">', "\n";
                                $pre .= '  ';
                                &printDirTree("$curr_dir/$files[$_]", $pre);
                        }else{

                                if($files[$_] =~ /^report.txt$/ || $files[$_] =~ /^finish_report.txt$/){

                                }else{

                                        print OUT '     ',$pre, '<fileName value="', $files[$_], '"></fileName>', "\n";
                                }
                        }

                }else {
                        if(-d "$curr_dir/$files[$_]"){
				if($files[$_] =~ /^arf$/ || $files[$_] =~ /^resource$/ || $files[$_] =~ /^report$/ ){
                                        next;
                                }
				
                                $treeflag2 = 0;
                                $folderFlag = $folderFlag + 1;
                                print OUT '     ', $pre, '<folderName value="', $files[$_], '">', "\n";
                                $pre .= '  ';

                                &printDirTree("$curr_dir/$files[$_]", $pre);

                        }else{
                                if($files[$_] =~ /^report.txt$/ || $files[$_] =~ /^finish_report.txt$/){

                                }else{
                                        print OUT '     ', $pre, '<fileName value="', $files[$_], '"></fileName>', "\n";
                                }
                        }

                        if($folderFlag2 gt "0"){
                                $treeflag = 0;
                                $folderFlag2 = $folderFlag2 - 1;
                                print OUT '     ', $folderPre, '</folderName>', "\n";
                        }
                        if($treeflag eq "1"){
                                if(($folderFlag gt "0")){
                                        $folderFlag = $folderFlag - 1;
                                        print OUT '     ', $folderPre, '</folderName>', "\n";
                                }
                        }
                        $treeflag = 1;
                }
        }
        if($treeflag eq "0"){
                $folderFlag = $folderFlag - 1;
                print OUT '     ', $folderPre, '</folderName>', "\n";
        }
        if($treeflag2 eq "0" && $treeflag eq "0"){
                if($folderFlag gt "0"){
                        $folderFlag = $folderFlag - 1;
                        print OUT '     ', $folderPre, '</folderName>', "\n";
                }
        }
}
#toUnique
sub uniqueArray{
    my %seen;
    grep !$seen{$_}++,@_;
}
##########	subroutine end		##########
##################################################

