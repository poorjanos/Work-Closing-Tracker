## app.R ##
library(shinydashboard)
library(shiny)
library(dplyr)
library(lubridate)
library(ggplot2)
library(readr)


# Read in csv
options(stringsAsFactors = FALSE)
t_app_hist <- read_csv(here::here("Data", "t_history.csv")) %>%
  mutate(
    IDOPONT = ymd_hms(IDOPONT),
    JUTZAR_ERK_IDOSZAK = ymd_hms(JUTZAR_ERK_IDOSZAK),
    JUTZAR_MEN_IDOSZAK = ymd_hms(JUTZAR_MEN_IDOSZAK)
  ) %>%
  mutate_if(is.character, as.factor)

now <- max(t_app_hist$IDOPONT, na.rm = TRUE)

t_app_curr <- t_app_hist %>% filter(IDOPONT == now)


# Define dashboard components
ui <- dashboardPage(
  dashboardHeader(title = paste0("Jutalek zaras ", "BETA")),
  dashboardSidebar(sidebarMenu(                    
                    checkboxGroupInput("prodInput", strong("Termekcsoport"),
                                       choices = levels(t_app_hist$F_TERMCSOP),
                                       selected = levels(t_app_hist$F_TERMCSOP)
                    ),
                    checkboxGroupInput("channelInput", strong("Ertekesitesi csatorna"),
                                       choices = levels(t_app_hist$F_CSATORNA_KAT),
                                       selected = levels(t_app_hist$F_CSATORNA_KAT)
                    ),
                    checkboxGroupInput("premiumInput", strong("Konyvelt dij"),
                                       choices = levels(t_app_hist$DIJ_ERKEZETT),
                                       selected = levels(t_app_hist$DIJ_ERKEZETT)
                    )
                  )
                ),
  dashboardBody(
                    # Boxes need to be put in a row (or column)
                    fluidRow(
                      # Dynamic valueBoxes
                      valueBoxOutput("volumeBox"),
                      
                      valueBoxOutput("finishedRateBox"),
                      
                      valueBoxOutput("timeLeftBox")
                    ),
                    
                    fluidRow(
                      box(plotOutput("statusPlot", height = 400))
                    )
                  )
  )

server <- function(input, output) {
  
  # Create reactive data input once for reuse in render* funcs below
  filtered_curr <- reactive({
    t_app_curr %>%
      filter(
        F_TERMCSOP %in% input$prodInput &
          F_CSATORNA_KAT %in% input$channelInput &
            DIJ_ERKEZETT %in% input$premiumInput
      )
  })
  
  # Render ValueBoxes
  output$volumeBox <- renderValueBox({
  valueBox(
    paste(sum(filtered_curr()$DARAB, na.rm = TRUE), "db"), "Allomany", icon("signal", lib = "glyphicon"),
    color = "blue"
  )
})

output$finishedRateBox <- renderValueBox({
  valueBox(
    paste(round(sum(filtered_curr()[filtered_curr()$F_KECS_PG == "Feldolgozott", "DARAB"], na.rm = TRUE) / sum(filtered_curr()$DARAB, na.rm = TRUE)*100, 2), "%"), "Feldolgozott", icon("ok", lib = "glyphicon"),
    color = "blue"
  )
})

output$timeLeftBox <- renderValueBox({
  valueBox(
    paste(filtered_curr() %>% tally(), "hours"), "Hatralevo ido", icon("time", lib = "glyphicon"),
    color = "blue"
  )
})
  
output$statusPlot <- renderPlot({
  if (is.null(filtered_curr())) {
    return()
  }
  
  ggplot(
    filtered_curr(),
    aes(x = F_KECS_PG, y = DARAB)
  ) +
    geom_bar(stat = "identity", fill = "steelblue") +
    geom_text(aes(label = DARAB), vjust = 1.6, color = "black", size = 6) +
    theme(
      axis.text.x = element_text(angle = 90, size = 12),
      axis.text.y = element_text(size = 12),
      strip.text.x = element_text(size = 12)
    ) +
    labs(
      x = "Ajanlat_statusza",
      y = "Allomany"
    ) +
    coord_cartesian(ylim = c(0, 30000)) +
    coord_flip()
})
}

shinyApp(ui, server)
