library(shiny)
library(shinydashboard)
library(shinythemes)
library(shinycssloaders)
library(shinyWidgets)

library(DT)
library(plotly)
library(tidyverse)

# load champions
df_champion_properties = aws.s3::s3read_using(read.csv, object = "s3://peter-ff15-data/champion_properties.csv")
df_champion_properties$X = NULL
factor_cols <- sapply(df_champion_properties, is.factor)
df_champion_properties[factor_cols] <- lapply(df_champion_properties[factor_cols], as.character)
champion_options = unique(df_champion_properties$champion)

ui <- dashboardPage(
  title = 'FF15',
  # dsahboard color theme
  skin = "black",
  
  ####### Dashboard Title #######
  # dashboardHeader(title = "FF15"),
  dashboardHeader(title = span(img(src="FF15_Logo.jpg",height = "45px"))),
  
  ####### Dashboard Sidebar #######
  dashboardSidebar(    
    sidebarMenu(
      # champion statistics
      menuItem("Champion Statistics", tabName = "champion_statistics", icon = icon("chart-bar")),
      # game strategy
      menuItem("Game Strategy", tabName = "game_strategy", icon = icon("trophy"),
               menuSubItem("Champion Guide", tabName = "champion_guide"),
               menuSubItem("Win Conditions", tabName = "win_conditions"),
               menuSubItem("Duo Synergy", tabName = "duo_synergy")
      ),
      # pick & ban
      menuItem("Pick & Ban", tabName = "pick_ban", icon = icon("chess"))
    )
  ),
  ####### Dashboard Body #######
  dashboardBody(
    tabItems(
      #### Champion Statistics ####
      tabItem(tabName = "champion_statistics",
              fluidRow(
                column(12,
                       box(width = NULL, solidHeader = TRUE,
                           checkboxGroupInput("champion_statistics_rank",
                                              label = "",
                                              choices = c('Iron','Bronze','Silver',
                                                          'Gold','Platinum','Diamond',
                                                          'Master','Grandmaster',
                                                          'Challenger'),
                                              selected = c('Silver','Gold'),
                                              inline = TRUE)
                       )
                )
              ),
              fluidRow(
                column(12,
                       box(width = NULL,
                           DT::dataTableOutput("champion_stats_table") %>% withSpinner(type = 8)) # color=
                )
              )
      ),
      
      #### Win Conditions ####
      tabItem(tabName = "win_conditions"
      ),
      
      #### Duo Synergy####
      tabItem(tabName = "duo_synergy"
      ),
      
      #### Pick & Ban ####
      tabItem(tabName = "pick_ban",
              #### Pick & Ban Interface ####
              fluidRow(
                column(12,
                       box(width = NULL, solidHeader = TRUE,
                           checkboxGroupInput("pick_ban_rank",
                                              label = "",
                                              choices = c('Iron','Bronze','Silver',
                                                          'Gold','Platinum','Diamond',
                                                          'Master','Grandmaster',
                                                          'Challenger'),
                                              selected = c('Silver','Gold'),
                                              inline = TRUE),
                           textInput("favorite_champions", label = "", value = "Enter favorite champions separated by comma (For example: 'Teemo,Garen,Twisted Fate')")
                       )
                )
              ),
              fluidRow(
                tags$head(
                  tags$style(type="text/css", 
                             "label.control-label, .selectize-control.single { 
                             display: table-cell; 
                             text-align: center; 
                             vertical-align: middle; 
                             } 
                             label.control-label {
                             padding-right: 10px;
                             }
                             .form-group { 
                             display: table-row;
                             }
                             .selectize-control.single div.item {
                             padding-right: 15px;
                             }")
                  ),
                column(4,
                       box(width = NULL, h4('Ally'),
                           selectInput("ally_top", h5("Top: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion"),
                           selectInput("ally_jungle", h5("Jungle: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion"),
                           selectInput("ally_mid", h5("Mid: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion"),
                           selectInput("ally_bot", h5("Bot: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion"),
                           selectInput("ally_supp", h5("Supp: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion")
                           )
                ),
                
                column(4,
                       box(width = NULL, h4('Combat Radar')
                       )
                ),
                
                column(4,
                       box(width = NULL, h4('Enemy'),
                           selectInput("enemy_top", h5("Top: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion"),
                           selectInput("enemy_jungle", h5("Jungle: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion"),
                           selectInput("enemy_mid", h5("Mid: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion"),
                           selectInput("enemy_bot", h5("Bot: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion"),
                           selectInput("enemy_supp", h5("Supp: "), 
                                       choices = c("Choosing Champion",champion_options),
                                       selected = "Choosing Champion")
                           )
                )
              ),
              
              #### Pick & Ban Assistance ####
              fluidRow(
                column(12,
                       box(width = NULL, solidHeader = TRUE,
                           tabsetPanel(
                             #### Champion Recommendation ####
                             tabPanel("Champion Recommendation",
                                      checkboxInput("favorite_champions_only", label = "Recommend Faviorite Champions Only", value = FALSE),
                                      DT::dataTableOutput("champion_recommendation_table") %>% withSpinner(type = 8)
                                      ),
                             tabPanel("Composition Comparison"),
                             tabPanel("Counter Strategy")
                           )
                           )
                           )
                       )
              ) 
    )
    )
  )