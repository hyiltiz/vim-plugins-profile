#! /bin/bash
set -eu

echo "Generating vim startup profile..."
logfile="vim.log"

if [ -f $logfile ]; then
  # clear the log file first
  rm $logfile
fi

if [[ $# -eq 0 ]]; then
  vim --startuptime $logfile -c q
else
  vim --startuptime $logfile $1
fi


echo 'Assuming your vimfiles folder as `~/.vim/`'
vimfilesDir="$HOME/.vim/"

plugDir=""
if [ -d "${vimfilesDir}plugged" ]; then
  echo "vim-plug has been detected."
  plugDir="plugged"
elif [ -d "${vimfilesDir}bundle" ]; then
  echo "NeoBundle/Vundle/Pathogen has been detected."
  plugDir="bundle"
else
  echo "Cannot tell your plugin-manager. Adjust this bash script\n"
  echo "to meet your own needs for now."
  echo 'Cue: `plugDir` variable would be a good starting place.'
  exit 1
fi



echo "Parsing vim startup profile..."
#logfile=hi.log
grep $plugDir $logfile > tmp.log
awk -F\: '{print $1}' tmp.log > tmp1.log
awk -F\: '{print $2}' tmp.log | awk -F\: '{print $2}' tmp.log | sed "s/.*${plugDir}\///g"|sed 's/\/.*//g' > tmp2.log
paste -d ',' tmp1.log tmp2.log | tr -s ' ' ',' > profile.csv
rm tmp.log tmp1.log tmp2.log
rm $logfile




# Let's do the R magic!
echo "Crunching data and generating profile plot ..."

# Check if R is available
echo " "
type R > /dev/null 2>&1 || { echo >&2 "Package R is required but it's not installed. \nPlease install R using your package manager, \nor check out cran.r-project.org for instructions. \nAborting."; exit 1; }


# Still here? Great! Let's move on!
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
R --vanilla --quiet --slave --file="$DIR/vim-plugins-profile-plot.R"
#R --vanilla --file="vim-plugins-profile-plot.R"  # or use this for debugging

# we use result.csv, which is saved from R
# delete profile.csv since it is used to feed into R
rm profile.csv


echo " "
echo 'Your plugins startup profile graph is saved '
echo 'as `result.png` under current directory.'
echo " "
echo "=========================================="
echo "Top 10 Plugins That Slows Down Vim Startup"
echo "=========================================="
cat -n result.csv |head -n 10 # change this 10 to see more in this `Top List`
echo "=========================================="

echo "Done!"
echo " "
