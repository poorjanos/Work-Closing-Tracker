# Load required libs
library(config)
library(here)
library(dplyr)
library(lubridate)


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


# Run query
t_prop_com <- dbGetQuery(jdbcConnection, "select * from t_prop_com")

# Close connection
dbDisconnect(jdbcConnection)


##########################################################################################
# Transform Data #########################################################################
##########################################################################################

t_app_data <- t_prop_com %>%
                mutate(F_ERKEZES = floor_date(ymd_hms(F_ERKEZES), "day"),
                       F_AJANLAT_STATUS = F_KECS_PG,
                       F_DIJ_STATUS = DIJKONYV) %>%
                select(F_IVK, F_ERKEZES, F_CSATORNA_KAT, F_TERMCSOP, F_AJANLAT_STATUS, F_DIJ_STATUS)

# Save to local storage
write.csv(t_app_data,
          here::here("Data", "t_app_data.csv"),
          row.names = FALSE)

