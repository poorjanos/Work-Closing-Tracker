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
# Gen Data for Shiny App #################################################################
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


##########################################################################################
# Gen Data for Flexdashboard  ############################################################
##########################################################################################

t_volume <- t_prop_com %>%
            mutate(
              F_ERKEZES = floor_date(ymd_hms(F_ERKEZES), "day"),
              F_ERKEZES_HET = paste0(
                year(F_ERKEZES), "/",
                ifelse(week(F_ERKEZES) < 10,
                       paste0("0", week(F_ERKEZES)), week(F_ERKEZES)
                ))) %>%
            group_by(F_ERKEZES, F_ERKEZES_HET, F_KECS, ALLOMANY) %>%
            summarise(DARAB = length(F_IVK)) %>%
            filter(DARAB >= 20) %>%
            ungroup()


t_men <- t_prop_com %>%
  mutate(
    F_LEZARAS = floor_date(ymd_hms(F_LEZARAS), "day"),
    F_LEZARAS_HET = case_when(
      is.na(F_LEZARAS) ~ "fuggo",
      TRUE ~ paste0(
        year(F_LEZARAS), "/",
        ifelse(week(F_LEZARAS) < 10,
               paste0("0", week(F_LEZARAS)), week(F_LEZARAS)
        )))) %>%
  group_by(F_LEZARAS_HET, ALLOMANY) %>%
  summarise(DARAB = length(F_IVK)) %>%
  filter(DARAB >= 20) %>%
  ungroup()



ggplot(t_volumes, aes(F_ERKEZES_HET, DARAB)) +
  geom_bar


