#! /bin/bash

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
R -q -f "vim-plugins-profile-plot.R" > /dev/null 2>&1

echo " "
echo 'Your plugins startup profile graph is saved '
echo 'as `profile.png` under current directory.'
echo " "
echo "=========================================="
echo "Top 10 Plugins That Slows Down Vim Startup"
echo "=========================================="
cat -n results.csv |head -n 10
echo "=========================================="

echo "Done!"
echo " "
