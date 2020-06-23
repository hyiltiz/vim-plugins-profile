#!/usr/bin/perl
# Copyright (C) 2020, Gerhard Gappmeier <gerhard.gappmeier@gmail.com>
# This file is based on vim-plugins-profile.rb, which is much better
# readable than the python variant.
use strict;
use File::Basename;
#use Smart::Comments; # comment in this to enable smart comments

# Users can pass "nvim" as a first argument to use neovim.
my $vim = $ARGV[0] // 'vim';                # vim to use
my $logfile = "vim-plugins-profile.$$.log"; # logfile for profiling
my $plugdir;                                # plugin manager directory
my $gnuplot = '/usr/bin/gnuplot';           # path to gnuplot binary
### logfile: $logfile

# detect vim config dir
my $XDG_CONFIG_HOME = $ENV{'XDG_CONFIG_HOME'} // "$ENV{'HOME'}/.config";
my $VIMFILES_DIR = ($vim eq "nvim") ? "$XDG_CONFIG_HOME/nvim" : "$ENV{HOME}/.vim";
print "Assuming your vimfiles folder is $VIMFILES_DIR.\n";

# start vim with logging and execute the quit command
print "Generating ${vim} startup profile...\n";
system("$vim --startuptime $logfile -c q");

# detect plugin manager
if (-d "$VIMFILES_DIR/plugged") {
    print "vim-plug has been detected.\n";
    $plugdir = "plugged";
} elsif (-d "$VIMFILES_DIR/bundle") {
    print "NeoBundle/Vundle/Pathogen has been detected.\n";
    $plugdir = "bundle";
} else {
    print "Cannot tell your plugin-manager. Adjust this script to meet your own needs for now.\n";
    print "Cue: `plug_dir` variable would be a good starting place.\n";
    exit 1;
}

# now parse the Vim profile
my %profile; # hash with profile data
my $rxtime = qr/\d+\.\d+/; # regex for time values
my $plugpath = "$VIMFILES_DIR/$plugdir/"; # path to plugin manager
my $pluginpath = "$VIMFILES_DIR/plugin/"; # path to Vim's plugin dir
open PROFILE, "<$logfile" or die("Could not open $logfile: $!");
while (<PROFILE>) {
    if (/($rxtime)  ($rxtime)  ($rxtime): sourcing (.*)$/) {
        my ($trace_time, $source_time, $exec_time, $path) = ($1, $2, $3, $4);
        my $name;
        if ($path =~ m/$plugpath/) { # files from plugin manager
            $path =~ s/$plugpath//;
            ($name) = split(/\//, $path); # get 1st folder name
            $name .= " ($plugdir)";
        } elsif ($path =~ m/$pluginpath/) { # files from plugin subfolder (the old way of plugins)
            $path =~ s/$pluginpath//;
            ($name) = split(/\//, $path); # get 1st folder name
            $name .= " (plugin)";
        } else { # other system files, e.g. from /usr/share
            $name = $path;
        }
        $profile{$name} += $exec_time; # sum up the time per name
    }
}
close PROFILE;
unlink $logfile;

# output
my $idx = 0;
foreach my $name (sort { $profile{$b} <=> $profile{$a} } keys %profile) {
    my $time = $profile{$name};
    printf "%40s: (%.3fms) %s\n", $name, $time, '*' x $time;
    last if ($idx == 30); # limit output to 30 highest values
    $idx++;
}

# gnuplot
if (-x $gnuplot) {
    print "Plotting using GNUplot...\n";
    # plot data
    open DATA, ">result.dat" or die("Could not open result.dat: $!");
    print DATA "# Idx\tName\tTime\n";
    my $idx = 1;
    foreach my $name (sort { $profile{$b} <=> $profile{$a} } keys %profile) {
        my $time = $profile{$name};
        printf DATA "$idx\t$name\t$time\n";
        last if ($idx == 30); # limit output to 30 highest values
        $idx++;
    }
    close DATA;

    open GNUPLOT, ">result.gp" or die("Could not open result.gp $!");
    print GNUPLOT <<"EOF";
set title "Vim Profile"
set datafile separator "\t"
#set auto x
set style data histogram
set style fill solid border -1
set style histogram errorbars gap 2 lw 1
set boxwidth 0.9
set ylabel "Execution Time [ms]"
set xtics rotate by 45 right
set grid ytics
set yrange [0:*]
set palette model RGB defined ( 0 'green', 1 'red' )
unset colorbox
set terminal pngcairo size 1280,1024 enhanced font 'Verdana,10'
set output "result.png"
plot 'result.dat' using 1:3:3:xtic(2) title "time [ms]" w boxes palette
EOF
    close GNUPLOT;
    system("$gnuplot result.gp") == 0 or die("gnuplot failed: $!");
    print "Finished. Open result.png to view the plot.\n";
} else {
    print "No GNUplot found. Skip plotting.\n";
}

