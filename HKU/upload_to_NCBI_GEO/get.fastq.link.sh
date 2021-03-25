cut -f2 all.csv -d, | xargs -I{} ln -s {} ./geo_submission_2020Mar30
cut -f3 all.csv -d, | xargs -I{} ln -s {} ./geo_submission_2020Mar30
