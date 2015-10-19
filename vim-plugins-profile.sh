#! /bin/bash
set -eu

echo "Generating vim startup profile..."
logfile="vim.log"

if [ -f $logfile ]; then
  # clear the log file first
  rm $logfile
fi

vim --startuptime $logfile -c q

whichPlugin="plugged"

echo "Parsing vim startup profile..."
grep 'plugged' vim.log > tmp.log
awk -F\: '{print $1}' tmp.log > tmp1.log
awk -F\: '{print $2}' tmp.log | awk -F\: '{print $2}' tmp.log | sed "s/.*${whichPlugin}\///g"|sed 's/\/.*//g' > tmp2.log
paste tmp1.log tmp2.log |sed 's/\s\+/,/g' > profile.csv
rm tmp.log tmp1.log tmp2.log

echo "Crunching data and generating profile plot ..."

# Check if R is available
echo " "
type R > /dev/null 2>&1 || { echo >&2 "Package R is required but it's not installed. \nPlease install R using your package manager, \nor check out cran.r-project.org for instructions. \nAborting."; exit 1; }

# Still here? Great! Let's move on!
# Let's do the R magic!
R --vanilla --quiet --slave --file="vim-plugins-profile-plot.R"
#R -q -f "vim-plugins-profile-plot.R" > /dev/null 2>&1

# we use result.csv, which is saved from R
# delete profile.csv since it is used to feed into R
rm profile.csv


echo " "
echo 'Your plugins startup profile graph is saved '
echo 'as `profile.png` under current directory.'
echo " "
echo "=========================================="
echo "Top 10 Plugins That Slows Down Vim Startup"
echo "=========================================="
cat -n results.csv |head -n 10 # change this 10 to see more in this `Top List`
echo "=========================================="

echo "Done!"
echo " "
