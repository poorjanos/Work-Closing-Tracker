## app.R ##
library(shinydashboard)
library(shiny)
library(dplyr)
library(lubridate)
library(ggplot2)
library(readr)
library(scales)


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
  dashboardHeader(title = "WorkLoad Tracker"),
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
  )),
  dashboardBody(
    # Top row value boxes
    fluidRow(
      valueBoxOutput("volumeBox"),

      valueBoxOutput("finishedRateBox"),

      valueBoxOutput("timeNowBox")
    ),

    # Middle row plots
    fluidRow(
      box(plotOutput("statusPlot", height = 250),
        solidHeader = TRUE, background = "light-blue",
        title = "Statuszok", width = 4
      ),
      box(plotOutput("pendingPlot", height = 250),
        solidHeader = TRUE, background = "light-blue",
        title = "Fuggo statuszok", width = 8
      )
    ),

    # Bottom row plots
    fluidRow(
      box(plotOutput("volumePlot", height = 120),
        solidHeader = TRUE, background = "teal",
        title = "Allomany fejlodes", width = 6
      ),
      box(plotOutput("burnPlot", height = 120),
        solidHeader = TRUE, background = "teal",
        title = "Burn chart", width = 6
      )
    )
  )
)

server <- function(input, output) {

  # Create reactive data input once for reuse in render* funcs below
  filtered_curr <- reactive({
    t_app_curr %>%
      filter(
        !is.na(F_KECS_PG) &
          F_TERMCSOP %in% input$prodInput &
          F_CSATORNA_KAT %in% input$channelInput &
          DIJ_ERKEZETT %in% input$premiumInput
      )
  })

  filtered_hist <- reactive({
    t_app_hist %>%
      filter(
        !is.na(F_KECS_PG) &
          F_TERMCSOP %in% input$prodInput &
          F_CSATORNA_KAT %in% input$channelInput &
          DIJ_ERKEZETT %in% input$premiumInput
      )
  })
  # Render ValueBoxes

  # Volume
  output$volumeBox <- renderValueBox({
    valueBox(
      paste(sum(filtered_curr()$DARAB, na.rm = TRUE), "db"), "Allomany", icon("signal", lib = "glyphicon"),
      color = "blue"
    )
  })

  # Finished rate
  output$finishedRateBox <- renderValueBox({
    valueBox(
      paste(round(sum(filtered_curr()[filtered_curr()$F_KECS_PG == "Feldolgozott", "DARAB"], na.rm = TRUE) /
        sum(filtered_curr()$DARAB, na.rm = TRUE) * 100, 2), "%"),
      "Feldolgozott",
      icon("ok", lib = "glyphicon"),
      color = "blue"
    )
  })

  # Actual date
  output$timeNowBox <- renderValueBox({
    valueBox(
      max(filtered_curr()$IDOPONT, na.rm = TRUE), "Utolso frissites", icon("time", lib = "glyphicon"),
      color = "blue"
    )
  })

  output$statusPlot <- renderPlot({
    if (is.null(filtered_curr())) {
      return()
    }

    # Render plots

    # Status
    ggplot(
      filtered_curr() %>% group_by(F_KECS_PG) %>% summarize(DARAB = sum(DARAB)),
      aes(x = F_KECS_PG, y = DARAB)
    ) +
      geom_bar(stat = "identity", fill = "steelblue") +
      geom_text(aes(label = DARAB), hjust = 0.5, color = "black") +
      theme(
        axis.text.x = element_text(angle = 90, size = 16)
      ) +
      labs(
        x = "Ajanlat statusza",
        y = "Allomany [db]"
      ) +
      coord_flip() +
      theme_light()
  })

  # Pending breakdown
  output$pendingPlot <- renderPlot({
    if (is.null(filtered_curr())) {
      return()
    }

    ggplot(
      filtered_curr() %>%
        filter(F_KECS_PG != "Feldolgozott") %>%
        group_by(F_KECS_PG, F_KECS) %>%
        summarize(DARAB = sum(DARAB)),
      aes(x = F_KECS, y = DARAB)
    ) +
      geom_bar(stat = "identity", fill = "steelblue") +
      geom_text(aes(label = DARAB), hjust = 0.5, color = "black") +
      theme(
        axis.text.x = element_text(angle = 90, size = 12),
        strip.text.y = element_text(size = 14)
      ) +
      labs(
        x = "Ajanlat statusza",
        y = "Allomany [db]"
      ) +
      facet_grid(. ~ F_KECS_PG, scales = "free") +
      coord_flip() +
      theme_light()
  })

  # Volume TS
  output$volumePlot <- renderPlot({
    if (is.null(filtered_hist())) {
      return()
    }

    ggplot(
      filtered_hist() %>%
        group_by(IDOPONT) %>%
        summarize(DARAB = sum(DARAB)) %>%
        ungroup(),
      aes(x = IDOPONT, y = DARAB, group = 1)
    ) +
      geom_line(size = 1, colour = "steelblue") +
      theme(
        axis.text.x = element_text(angle = 0)
      ) +
      labs(
        x = "Idopont",
        y = "Allomany [db]"
      ) +
      theme_light()
  })

  # Burn chart TS
  output$burnPlot <- renderPlot({
    if (is.null(filtered_hist())) {
      return()
    }

    ggplot(
      filtered_hist() %>%
        mutate(F_KECS_PG = case_when(
          F_KECS_PG == "Feldolgozott" ~ "Feldolgozott",
          TRUE ~ "To-Burn"
        )) %>%
        group_by(IDOPONT, F_KECS_PG) %>%
        summarize(DARAB = sum(DARAB)) %>%
        mutate(TO_BURN_RATE = DARAB / sum(DARAB)) %>%
        filter(F_KECS_PG == "To-Burn") %>%
        ungroup(),
      aes(x = IDOPONT, y = TO_BURN_RATE, group = 1)
    ) +
      geom_line(size = 1, colour = "steelblue") +
      theme(
        axis.text.x = element_text(angle = 0)
      ) +
      scale_y_continuous(labels = percent) +
      labs(
        x = "Idopont",
        y = "Feldolgozatlan [%]"
      ) +
      theme_light()
  })
}

shinyApp(ui, server)