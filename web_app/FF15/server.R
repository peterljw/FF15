library(shiny)
library(aws.s3)
library(DT)
library(plotly)
library(tidyverse)

######## Data Preprocessing ########

s3BucketName <- "peter-covid-dashboard-data"
Sys.setenv("AWS_ACCESS_KEY_ID" = "AKIAWECDTQ4VU6FGPRHY",
           "AWS_SECRET_ACCESS_KEY" = "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",
           "AWS_DEFAULT_REGION" = "us-east-2")

# load champion statistics
df_champion_stats = aws.s3::s3read_using(read.csv, object = "s3://peter-ff15-data/champion_stats.csv")
df_champion_stats$X = NULL
factor_cols <- sapply(df_champion_stats, is.factor)
df_champion_stats[factor_cols] <- lapply(df_champion_stats[factor_cols], as.character)

# load champion properties
df_champion_properties = aws.s3::s3read_using(read.csv, object = "s3://peter-ff15-data/champion_properties.csv")
df_champion_properties$X = NULL
factor_cols <- sapply(df_champion_properties, is.factor)
df_champion_properties[factor_cols] <- lapply(df_champion_properties[factor_cols], as.character)

######## Helper  Functions ########

choose_top_n_counters <- function(counters,n){
  counters_vector = unlist(strsplit(counters, ","))
  n = max(c(n,length(counters_vector)))
  top_n_counters = paste(counters_vector[1:3],collapse = ',')
  return =(top_n_counters)
}

transform_champion_stats_table <- function(df,ranks){
  
  df$counters = sapply(df$counters,function(x) choose_top_n_counters(x,3))
  
  groupby_champ_lane = df %>%
    filter(rank %in% ranks) %>%
    group_by(champion, lane)
  
  df_champ_stats = groupby_champ_lane %>% summarise(
    tier = round(sum(tier*matches)/sum(matches),digits = 0),
    win_rate = paste0(round(sum(win_rate*matches)/sum(matches),digits = 4)*100,'%'),
    pick_rate = paste0(round(sum(pick_rate*matches)/sum(matches),digits = 4)*100,'%'),
    ban_rate = paste0(round(sum(ban_rate*matches)/sum(matches),digits = 4)*100,'%'),
    counters = paste(counters,collapse=','),
    matches = sum(matches) 
  )%>%
    arrange(tier,desc(win_rate))
  
  df_champ_stats$counters = sapply(df_champ_stats$counters, function(x) paste(unique(unlist(strsplit(x, ","))),collapse = ','))
  return(df_champ_stats)
}

generate_champion_stats_table <- function(df_champion_stats,df_champion_properties,ranks){
  df_champ_stats = transform_champion_stats_table(df_champion_stats,ranks) %>%
    left_join(df_champion_properties[c('champion','primary_class','secondary_class','role')], by='champion') %>%
    select('Champion'=champion,'Lane'=lane,'Tier'=tier,'Win Rate'=win_rate,
           'Pick Rate'=pick_rate,'Ban Rate'=ban_rate,'Primary Class'=primary_class,
           'Secondary Class'=secondary_class,'Role'=role,
           'Counters'=counters,'Matches'=matches)
  return(df_champ_stats)
}


######## Shiny Server ########
shinyServer(function(input, output) {
  ######## Champion Statistics ########
  output$champion_stats_table <- ({
    DT::renderDataTable(generate_champion_stats_table(df_champion_stats,df_champion_properties,input$champion_statistics_rank), 
                        options = list(autoWidth = TRUE,pageLength=15,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  ######## Combat Radar ########
  
  ######## Champion Recommendation ########
  output$champion_recommendation_table <- ({
    DT::renderDataTable(generate_champion_stats_table(df_champion_stats,df_champion_properties,input$pick_ban_rank), 
                        options = list(autoWidth = TRUE,pageLength=10,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
})
