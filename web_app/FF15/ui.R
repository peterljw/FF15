library(shiny)
library(shinydashboard)
library(shinythemes)
library(shinycssloaders)
library(shinyWidgets)

library(DT)
library(plotly)
library(highcharter)
library(tidyverse)

# load champions
s3BucketName <- "peter-ff15-data"
Sys.setenv("AWS_ACCESS_KEY_ID" = "",
           "AWS_SECRET_ACCESS_KEY" = "",
           "AWS_DEFAULT_REGION" = "us-east-2")

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
  dashboardHeader(title = span(img(src="FF15_Logo.png",height = "48px"))),
  
  ####### Dashboard Sidebar #######
  dashboardSidebar(    
    sidebarMenu(
      # pick & ban
      menuItem("Pick & Ban Analyser", tabName = "pick_ban", icon = icon("chess")),
      # game strategy
      menuItem("Game Data Insights", tabName = "game_statistics", icon = icon("chart-bar"),
               menuSubItem("Champion Statistics", tabName = "champion_statistics"),
               menuSubItem("Duo Synergy", tabName = "duo_synergy"),
               menuSubItem("Win Conditions", tabName = "win_conditions"),
               menuSubItem("Champion Tips", tabName = "champion_tips")
      )
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
                           tabsetPanel(
                             tabPanel("Top",DT::dataTableOutput("champion_stats_table_top") %>% withSpinner(type = 8)),
                             tabPanel("Jungle",DT::dataTableOutput("champion_stats_table_jungle") %>% withSpinner(type = 8)),
                             tabPanel("Mid",DT::dataTableOutput("champion_stats_table_mid") %>% withSpinner(type = 8)),
                             tabPanel("Bot",DT::dataTableOutput("champion_stats_table_bot") %>% withSpinner(type = 8)),
                             tabPanel("Supp",DT::dataTableOutput("champion_stats_table_supp") %>% withSpinner(type = 8))
                             )
                           
                           )
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
                # tags$head(
                #   tags$style(type="text/css", 
                #              "label.control-label, .selectize-control.single { 
                #              display: table-cell; 
                #              text-align: center; 
                #              vertical-align: middle; 
                #              } 
                #              label.control-label {
                #              padding-right: 10px;
                #              }
                #              .form-group { 
                #              display: table-row;
                #              }
                #              .selectize-control.single div.item {
                #              padding-right: 15px;
                #              }")
                #   ),
                column(3,
                       box(width = NULL, h4('Ally'), height = '515px',
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
                
                column(6,
                       box(width = NULL, h4('Combat Radar'), height = '515px',
                           highchartOutput("combat_radar_plot")
                       )
                ),
                
                column(3,
                       box(width = NULL, h4('Enemy'), height = '515px',
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
              
              #### Pick & Ban Recommendation ####
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
                           textInput("favorite_champions", label = "", value = "Enter favorite champions separated by comma to limit the recommendations below. (For example: 'Teemo,Garen,Darius')")
                       )
                )
              ),
              fluidRow(
                column(12,
                       box(width = NULL, solidHeader = FALSE,
                           h4("Champion Recommendation"),
                           tabsetPanel(
                             #### Champion Recommendation ####
                             tabPanel("Top",DT::dataTableOutput("champion_recommendation_table_top") %>% withSpinner(type = 8)),
                             tabPanel("Jungle",DT::dataTableOutput("champion_recommendation_table_jungle") %>% withSpinner(type = 8)),
                             tabPanel("Mid",DT::dataTableOutput("champion_recommendation_table_mid") %>% withSpinner(type = 8)),
                             tabPanel("Bot",DT::dataTableOutput("champion_recommendation_table_bot") %>% withSpinner(type = 8)),
                             tabPanel("Supp",DT::dataTableOutput("champion_recommendation_table_supp") %>% withSpinner(type = 8))
                           )
                           )
                           )
                       )
              ) 
    )
    )
  )