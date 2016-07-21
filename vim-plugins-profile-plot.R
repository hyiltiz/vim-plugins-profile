if("ggplot2" %in% rownames(installed.packages()) == FALSE) {

  isOk <- FALSE
  # we need to install the ggplot2 package
  while(!isOk){
    message("Trying in install the required R:ggplot2 package. Confirm? (y/n)")
    ANSWER <- readLines(con="stdin", 1)
    if (tolower(substr(ANSWER, 1,1)) == "y" ) {
      isOk = TRUE
      message("Confirmed to install.")
      message(" ")
      message("==========================================\n")
      message("Installing required R dependency package...\n")

      # install the required package if not present from the default package repository
      install.packages("ggplot2", repos="http://cran.rstudio.com/", dep = TRUE)
      message("Installation  finished!\n")
      message("==========================================\n")
    }
    else {
      isOk = FALSE
      message("You did not say yes, so aborting.")
      return(-1)
    }
  }
}


out <- tryCatch(
                {
                  require(ggplot2)
                  dat <- read.csv("profile.csv", header = FALSE, col.names = c("TraceTime", "SourceTime", "ExecTime", "PluginName"))
                  dat.n <- aggregate(ExecTime ~ PluginName, data = dat, "sum")
                  
                  # now plot!
                  p <- ggplot(dat.n, aes(x = reorder(PluginName, ExecTime), y = ExecTime, fill = ExecTime)) + 
                    geom_bar(stat="identity") + 
                    xlab("Total Execution Time (ms)")
                    coord_flip()
                  
                  # add in the colors!
                  p <- p + scale_fill_continuous(low = "blue", high = "red", na.value = "grey50", trans = "sqrt", guide= FALSE)
                  
                  # use this if you hate colors to get grey figure
                  # p <- p + scale_fill_continuous(low = "grey50", high = "grey50", na.value = "grey50", trans = "sqrt", guide= FALSE)
                  
                  png("result.png", width = 768, height = 768, bg = "transparent")
                  print(p)
                  dev.off()
                  pdf("result.pdf", width = 768, height = 768, bg = "transparent")
                  print(p)
                  dev.off()
                  svg("result.svg", width = 768, height = 768, bg = "transparent")
                  print(p)
                  dev.off()

                  # sort the data, then save .csv for the result
                  dat.n <- dat.n[order(dat.n$ExecTime, decreasing = TRUE),]
                  dat.n <- dat.n[,2:1]
                  png("result.png", width = 1366, height = 768)
                  print(p)
                  dev.off()
                  write.table(dat.n, "result.csv", sep = "\t", row.names = FALSE)

                },
                error=function(cond) {
                  message("Package R caused an error!")
                  message("Here's the original error message:")
                  message(cond)
                  # Choose a return value in case of error
                  return(NA)
                },
                warning=function(cond) {
                  message("Package R caused a warning:")
                  message("Here's the original warning message:")
                  message(cond)
                  # Choose a return value in case of warning
                  return(NULL)
                },
                finally={
                  # NOTE:
                  # Here goes everything that should be executed at the end,
                  # regardless of success or error.

                  # Do nothing
                }
                )
