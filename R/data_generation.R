# Load required libs
library(config)
library(here)
library(dplyr)
library(lubridate)


# Quit if sysdate == weekend ------------------------------------------------------------
stopifnot(!(strftime(Sys.Date(), "%u") == 6 | strftime(Sys.Date(), "%u") == 7))

# Import helper functions
source(here::here("R", "data_manipulation.R"))

##########################################################################################
# Extract Data ###########################################################################
##########################################################################################

# Set JAVA_HOME, set max. memory, and load rJava library
Sys.setenv(JAVA_HOME = "C:\\Program Files\\Java\\jre1.8.0_171")
options(java.parameters = "-Xmx2g")
library(rJava)

# Output Java version
.jinit()
print(.jcall("java/lang/System", "S", "getProperty", "java.version"))

# Load RJDBC library
library(RJDBC)

# Create connection driver and open connection
jdbcDriver <-
  JDBC(driverClass = "oracle.jdbc.OracleDriver", classPath = "C:\\Users\\PoorJ\\Desktop\\ojdbc7.jar")

# Get Kontakt credentials
kontakt <-
  config::get("kontakt",
              file = "C:\\Users\\PoorJ\\Projects\\config.yml")

# Open connection
jdbcConnection <-
  dbConnect(
    jdbcDriver,
    url = kontakt$server,
    user = kontakt$uid,
    password = kontakt$pwd
  )

# Read query
query <- readQuery(here::here("SQL", "query_status.sql"))

# Run query
t_prop_com <- dbGetQuery(jdbcConnection, query)
t_zaras_idoszak <- dbGetQuery(jdbcConnection, "select * from t_jut_zaras")

# Close connection
dbDisconnect(jdbcConnection)


##########################################################################################
# Gen Data for Shinydashboard  ###########################################################
##########################################################################################

t_agg <- t_prop_com %>%
  mutate(
    IDOPONT = ymd_hms(IDOPONT),
    JUTZAR_ERK_IDOSZAK = ymd_hms(JUTZAR_ERK_IDOSZAK),
    JUTZAR_MEN_IDOSZAK = ymd_hms(JUTZAR_MEN_IDOSZAK),
    DIJ_ERKEZETT = case_when(
      !is.na(.$DIJKONYVDAT) ~ "I",
      TRUE ~ "N"
    ),
    JUTZAR_ERK_IDOSZAK_KAT = case_when(
      JUTZAR_ERK_IDOSZAK < max(JUTZAR_MEN_IDOSZAK, na.rm = TRUE) ~ "Korabbi",
      TRUE ~ "Aktualis"
    )
  ) %>%
  group_by(IDOPONT, F_TERMCSOP, F_CSATORNA_KAT,
           F_KECS, F_KECS_PG, DIJ_ERKEZETT,
           JUTZAR_ERK_IDOSZAK, JUTZAR_ERK_IDOSZAK_KAT, JUTZAR_MEN_IDOSZAK) %>%
  summarise(
    DARAB = length(F_IVK),
    AFC_NAP_ATL = mean(AFC_NAPOS)) %>% 
  ungroup()
  


# Determine whether to append or overwrite log
to_append <- log_append()

# Save to local storage
if (to_append == FALSE){
  write.table(t_agg,
              here::here("Data", "t_history.csv"),
              row.names = FALSE,
              col.names = TRUE,
              sep = ",",
              append = FALSE)
} else if (to_append == TRUE){
  write.table(t_agg,
              here::here("Data", "t_history.csv"),
              row.names = FALSE,
              col.names = FALSE,
              sep = ",",
              append = TRUE)
}
