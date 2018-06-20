library(shiny)
library(dplyr)
library(lubridate)
library(ggplot2)
library(readr)

options(stringsAsFactors = FALSE)
t_app_data <- read_csv(here::here("Data", "t_app_data.csv")) %>% 
              mutate(F_ERKEZES = ymd(F_ERKEZES)) %>%
              filter(!is.na(F_AJANLAT_STATUS)) %>% 
              mutate_if(is.character, as.factor) 


# User interface ------------------------------------------------------------------------
ui <- fluidPage(titlePanel("Jutalékzárásban érintett állomány"),
                sidebarLayout(
                  sidebarPanel(                    
                    sliderInput("dateInput", strong("Érkezett"),
                                min = min(t_app_data$F_ERKEZES),
                                max = max(t_app_data$F_ERKEZES),
                                c(min(t_app_data$F_ERKEZES), max(t_app_data$F_ERKEZES))),
                    checkboxGroupInput("prodInput", strong("Termékcsoport"),
                                       choices = levels(t_app_data$F_TERMCSOP),
                                       selected = levels(t_app_data$F_TERMCSOP)
                    ),
                    checkboxGroupInput("channelInput", strong("Értékesítési csatorna"),
                                       choices = levels(t_app_data$F_CSATORNA_KAT),
                                       selected = levels(t_app_data$F_CSATORNA_KAT)
                    )
                  ),
                  mainPanel(plotOutput("statusPlot"))
))

# Server --------------------------------------------------------------------------------
server <- function(input, output) {
  
  # Create reactive data input once for reuse in render* funcs below
  filtered <- reactive({
    t_app_data %>%
      filter(
        F_TERMCSOP %in% input$prodInput &
        F_CSATORNA_KAT %in% input$channelInput &
        F_ERKEZES >= input$dateInput[1] &
        F_ERKEZES <= input$dateInput[2]) %>%
        group_by(F_AJANLAT_STATUS, F_DIJ_STATUS) %>%
        summarize(DARAB = length(F_IVK)) %>% 
        ungroup()
  })
 
   
  # Render plot
  output$statusPlot <- renderPlot({
    if (is.null(filtered())) {
      return()
    }

  ggplot(
      filtered(),
      aes(x = F_AJANLAT_STATUS, y = DARAB)
    ) +
      geom_bar(stat = "identity", fill = "steelblue") +
      geom_text(aes(label = DARAB), vjust = 1.6, color = "black", size = 6) +
      theme(
        axis.text.x = element_text(angle = 90, size = 12),
        axis.text.y = element_text(size = 12),
        strip.text.x = element_text(size = 12)
      ) +
      facet_grid(. ~ F_DIJ_STATUS) +
      labs(
        x = "Ajánlat státusza",
        y = "Díj státusza"
      ) +
      coord_cartesian(ylim = c(0, 30000))
  })
}

shinyApp(ui = ui, server = server)