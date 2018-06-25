# Function to read in SQL scripts from file
readQuery <-
  function(file)
    paste(readLines(file, warn = FALSE), collapse = "\n")


# Function to determine log append or overwrite
log_append <- function(){
  # Read history from storage
  t_history <- read.csv2(here::here("Data", "t_history.csv"), stringsAsFactors = FALSE, sep = ",")
  
  # Determine history and current dates for comparison
  naplo_max_idopont <- max(ymd_hms(t_history$IDOPONT))
  zaras_fordulo_idopont <- min(ymd_hms((t_zaras_idoszak[ymd_hms(t_zaras_idoszak$F_MENESZTES) >
                                                          Sys.time(), "F_MENESZTES"]))) + days(1)

  if (naplo_max_idopont < zaras_fordulo_idopont) {
      to_append = TRUE
  } else {
      to_append = FALSE
  }
  
  return(to_append)
}