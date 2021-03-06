#!/bin/sh

#  email_loopFiles.sh

printf "ref_type\tsample\tR1_zip\tR2_zip\ttotal_read_prs\tup_reads\t%%dup_reads\tave_read_length\tref\tave_cov_X\tper_cov\tunmapped_contigs\tquality_snps\n" > /scratch/report/stat_table.txt
printf "" > /scratch/report/pre_stat_table.txt
printf "\n" >> /scratch/report/stat_table_cumulative.txt
date >> /scratch/report/stat_table_cumulative.txt

echo "Start Time: `date`" > /scratch/report/dailyTime
starttime=`date +%s`

echo "Please wait.  Searching for TB complex, Brucella and paratuberculosis oligos and then starting appropriate processZips.sh argument"
`loopFiles.sh` &&

echo "" >> /scratch/report/dailyTime
echo "End Time: `date`" >> /scratch/report/dailyTime
endtime=`date +%s`
runtime=$((endtime-starttime))
printf 'Runtime: %dh:%dm:%ds\n' $(($runtime/3600)) $(($runtime%3600/60)) $(($runtime%60)) >> /scratch/report/dailyTime

echo "e-mailing files"

cat /scratch/report/dailyTime > /scratch/report/email_processZips.txt
echo "" >> /scratch/report/email_processZips.txt
echo "ADD_MARKER" >> /scratch/report/email_processZips.txt
echo "" >> /scratch/report/dailyReport.txt
cat /scratch/report/dailyReport.txt >> /scratch/report/email_processZips.txt

cat /scratch/report/spoligoCheck.txt >> /scratch/report/email_processZips.txt
cat /scratch/report/mlstCheck.txt >> /scratch/report/email_processZips.txt

echo "ADD_MARKER" >> /scratch/report/email_processZips.txt

cat /scratch/report/dailyStats.txt >> /scratch/report/email_processZips.txt
echo "" >> /scratch/report/email_processZips.txt

grep -v '*' /scratch/report/email_processZips.txt | grep -v "Stats for BAM file" | sed 's/ADD_MARKER/******************************************/g' > /scratch/report/email_processZips2.txt

#################################################
# Create "here-document"
cat >./excelwriterstats.py <<'EOL'
#!/usr/bin/env python

import sys
import csv
import xlsxwriter

filename = sys.argv[1].replace(".txt",".xlsx")
wb = xlsxwriter.Workbook(filename)
ws = wb.add_worksheet("Sheet1")
with open(sys.argv[1],'r') as csvfile:
    table = csv.reader(csvfile, delimiter='\t')
    i = 0
    for row in table:
        ws.write_row(i, 0, row)
        i += 1

col = len(row)
print (filename, ":", i, "x", col)

wb.close()

EOL

chmod 755 ./excelwriterstats.py

#################################################


sort -k1,2 /scratch/report/pre_stat_table.txt >> /scratch/report/stat_table.txt

./excelwriterstats.py /scratch/report/stat_table.txt

column -t /scratch/report/stat_table.txt > /scratch/report/stat_table.temp; mv /scratch/report/stat_table.temp /scratch/report/stat_table.txt
enscript /scratch/report/stat_table.txt -B -j -r -f "Courier7" -o - | ps2pdf - /scratch/report/stat_table.pdf

if [[ $1 == me ]]; then
	email_list="tod.p.stuber@aphis.usda.gov"
	else
	email_list="tod.p.stuber@aphis.usda.gov Jessica.A.Hicks@aphis.usda.gov suelee.robbe-austerman@aphis.usda.gov patrick.m.camp@aphis.usda.gov David.T.Farrell@aphis.usda.gov Christine.R.Quance@aphis.usda.gov Robin.L.Swanson@aphis.usda.gov" 
fi

cat /scratch/report/email_processZips2.txt | mutt -a /scratch/report/stat_table.xlsx /scratch/report/stat_table.pdf -s "WGS results" -- $email_list

date >> /scratch/report/mlstCheck_all.txt
cat /scratch/report/mlstCheck.txt >> /scratch/report/mlstCheck_all.txt

rm ./excelwriterstats.py
#
#  Created by Tod Stuber on 11/09/12.
#
