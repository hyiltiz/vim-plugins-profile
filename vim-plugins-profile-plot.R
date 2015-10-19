if("ggplot2" %in% rownames(installed.packages()) == FALSE) {

  # we need to install the ggplot2 package
  while(is.na(acr) | acr <= 0 | acr >= 1 ){
    acr <- readline("and the average cancellation rate between 0 and 1 :")
    acr <- ifelse(grepl("[^0-9.]",acr),-1,as.numeric(acr))
  }
  message("==========================================\n")
  message("Installing required R dependency package...\n")

  # install the required package if not present from the default package repository
  install.packages("ggplot2", repos="http://cran.rstudio.com/")
  message("Installation  finished!\n")
  message("==========================================\n")
}
out <- tryCatch(
                {
                  require(ggplot2)
                  dat <- read.csv("profile.csv", header = FALSE, col.names = c("TraceTime", "SourceTime", "ExecTime", "PluginName"))
                  png("profile.png", width = 1366, height = 768)
                  qplot(PluginName, ExecTime, data = dat, stat = "summary", fun.y = "sum", geom = "bar") + coord_flip() + xlab("Installed Plugins") + ylab("Startup Time (ms)")
                  dev.off()

                  dat.n <- aggregate(ExecTime ~ PluginName, data = dat, "sum")
                  dat.n <- dat.n[order(dat.n$ExecTime, decreasing = TRUE),]
                  dat.n <- dat.n[,2:1]
                  write.table(dat.n, "results.csv", sep = "\t", col.names = FALSE, row.names = FALSE)

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
