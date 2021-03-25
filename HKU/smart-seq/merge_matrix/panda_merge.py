import pandas as pd
import os

work_dir = os.path.split(os.path.realpath(__file__))[0] + "/"

listf = open(work_dir+"exp.list", "r")

expected_count_df = pd.DataFrame()
TPM_df = pd.DataFrame()
FPKM_df = pd.DataFrame()
sample_list = []

count = 0
for one_file in listf:
	count += 1
	sample_name = one_file.strip().split("/")[-2]
	sample_list.append(sample_name)
	if os.stat(one_file.strip()).st_size == 0:
		print sample_name+" fail!!!"
		continue
	else:
		print sample_name
	#in_df = pd.read_csv(work_dir + one_file.strip(), sep="\t")
	in_df = pd.read_csv(one_file.strip(), sep="\t")
	in_df = in_df.rename(index=in_df["gene_id"])
	# gene_id = in_df["gene_id"]
	one_expected_count = in_df["expected_count"]
	one_TPM = in_df["TPM"]
	one_FPKM = in_df["FPKM"]
	#expected_count.columns = sample_name
	#expected_count = expected_count.rename(columns=sample_name, inplace=True)
	#TPM = TPM.rename(columns=sample_name, inplace=True)
	#FPKM = FPKM.rename(columns=sample_name, inplace=True)
	expected_count_df = pd.concat([expected_count_df,one_expected_count], axis=1)
	TPM_df = pd.concat([TPM_df,one_TPM], axis=1)
	FPKM_df = pd.concat([FPKM_df,one_FPKM], axis=1)
	expected_count_df.fillna(0)
	TPM_df.fillna(0)
	FPKM_df.fillna(0)
	# if count == 3:
	# 	break

expected_count_df.columns = sample_list
TPM_df.columns = sample_list
FPKM_df.columns = sample_list

expected_count_df.to_csv(work_dir+"expected_count.csv",sep=",", encoding='utf-8')
TPM_df.to_csv(work_dir+"TPM.csv",sep=",", encoding='utf-8')
FPKM_df.to_csv(work_dir+"FPKM.csv",sep=",", encoding='utf-8')

listf.close()

# df_bulk = df_bulk.drop_duplicates(subset="gene", keep='first', inplace=False)
# df_bulk = df_bulk.rename(index=df_bulk["gene"])



# 	gene_name, gene_id = 
# 	for one in in_df["gene_id"]:
# 		gene_name, gene_id = in_df["gene_id"].split("_")
