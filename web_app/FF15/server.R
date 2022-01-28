library(shiny)
library(aws.s3)
library(DT)
library(plotly)
library(highcharter)
library(tidyverse)

######## Data Preprocessing ########

s3BucketName <- "peter-ff15-data"
Sys.setenv("AWS_ACCESS_KEY_ID" = "",
           "AWS_SECRET_ACCESS_KEY" = "",
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
  top_n_counters = paste(counters_vector[1:n],collapse = ', ')
  return =(top_n_counters)
}

transform_champion_stats_table <- function(df,ranks){
  
  df$counters = sapply(df$counters,function(x) choose_top_n_counters(x,3))
  
  groupby_champ_lane = df %>%
    filter(rank %in% ranks) %>%
    group_by(champion, lane)
  
  df_champ_stats = groupby_champ_lane %>% summarise(
    tier = round(sum(tier*matches)/sum(matches),digits = 0),
    win_rate = round(sum(win_rate*matches)/sum(matches),digits = 4)*100,
    pick_rate = round(sum(pick_rate*matches)/sum(matches),digits = 4)*100,
    ban_rate = round(sum(ban_rate*matches)/sum(matches),digits = 4)*100,
    counters = paste(counters,collapse=', '),
    matches = sum(matches), .groups="keep"
  )%>%
    arrange(tier,desc(win_rate))
  
  df_champ_stats$counters = sapply(df_champ_stats$counters, function(x) paste(unique(unlist(strsplit(x, ","))),collapse = ','))

  return(df_champ_stats)
}

generate_champion_stats_table <- function(df_champion_stats,df_champion_properties,ranks){
  df_champ_stats = transform_champion_stats_table(df_champion_stats,ranks) %>%
    left_join(df_champion_properties[c('champion','primary_class','secondary_class','role')], by='champion') %>%
    select('Champion'=champion,'Lane'=lane,'Tier'=tier,'Win Rate %'=win_rate,
           'Pick Rate %'=pick_rate,'Ban Rate %'=ban_rate,'Primary Class'=primary_class,
           'Secondary Class'=secondary_class,'Role'=role,
           'Counters'=counters)
  return(df_champ_stats)
}

generate_rating_table <- function(df_champion_properties,
                                  ally_top,ally_jungle,ally_mid,ally_bot,ally_supp,
                                  enemy_top,enemy_jungle,enemy_mid,enemy_bot,enemy_supp){
  
  ally_team = c(ally_top,ally_jungle,ally_mid,ally_bot,ally_supp)
  ally_team = ally_team[ally_team != "Choosing Champion"]
  
  enemy_team = c(enemy_top,enemy_jungle,enemy_mid,enemy_bot,enemy_supp)
  enemy_team = enemy_team[enemy_team != "Choosing Champion"]
  
  rating = c('AD','AP','Tankiness','Control','Mobility','Utility')
  
  df_ally = df_champion_properties %>% filter(champion %in% ally_team)
  if(nrow(df_ally) == 0){
    ally_value = rep(0,6)
  }else{
    ally_value = c(sum(df_ally$physical_damage),sum(df_ally$magic_damage),
                   sum(df_ally$tankiness),sum(df_ally$control),
                   sum(df_ally$mobility),sum(df_ally$utility))
  }
  
  df_enemy = df_champion_properties %>% filter(champion %in% enemy_team)
  if(nrow(df_enemy) == 0){
    enemy_value = rep(0,6)
  }else{
    enemy_value = c(sum(df_enemy$physical_damage),sum(df_enemy$magic_damage),
                    sum(df_enemy$tankiness),sum(df_enemy$control),
                    sum(df_enemy$mobility),sum(df_enemy$utility))
  }
  
  df_ratings = data.frame(rating,ally_value,enemy_value)
  
  return(df_ratings)
}

plot_combat_radar <- function(df){
  highchart() %>%
    hc_title(text = "Combat Radar") %>%
    hc_chart(polar = T) %>% 
    hc_xAxis(categories = df$rating, 
             labels = list(style = list(fontSize= '14px')), title =NULL, tickmarkPlacement = "on", lineWidth = 0) %>% 
    hc_plotOptions(series = list(marker = list(enabled = F))) %>% 
    hc_yAxis(gridLineInterpolation = "polygon", lineWidth = 0, min = 0) %>% 
    hc_add_series(name = "Ally", df$ally_value, type ="area", color = "#56A5EC", pointPlacement = "on") %>%
    hc_add_series(name = "Enemy", df$enemy_value, type ="area", color = "darkorange", pointPlacement = "on")
}

generate_champion_recommendation_table <- function(df_champion_stats,df_champion_properties,ranks,favorite_champions){
  if(favorite_champions == '' | grepl('Enter', favorite_champions, fixed = TRUE)){
    df_champ_stats = transform_champion_stats_table(df_champion_stats,ranks) %>%
      left_join(df_champion_properties[c('champion','primary_class','secondary_class','role')], by='champion') %>%
      select('Champion'=champion,'Lane'=lane,'Tier'=tier,'Win Rate %'=win_rate,
             'Pick Rate %'=pick_rate,'Ban Rate %'=ban_rate,'Primary Class'=primary_class,
             'Secondary Class'=secondary_class,'Role'=role,
             'Counters'=counters)
    return(df_champ_stats)
  } else{
    favorite_champions = unlist(strsplit(favorite_champions, ","))
    favorite_champions = sapply(favorite_champions, trimws)
    df_champ_stats = transform_champion_stats_table(df_champion_stats,ranks) %>%
      left_join(df_champion_properties[c('champion','primary_class','secondary_class','role')], by='champion') %>%
      filter(champion %in% favorite_champions) %>%
      select('Champion'=champion,'Lane'=lane,'Tier'=tier,'Win Rate %'=win_rate,
             'Pick Rate %'=pick_rate,'Ban Rate %'=ban_rate,'Primary Class'=primary_class,
             'Secondary Class'=secondary_class,'Role'=role,
             'Counters'=counters)
    return(df_champ_stats)
  }
}


######## Shiny Server ########
shinyServer(function(input, output) {
  ######## Champion Statistics ########
  
  output$champion_stats_table_top <- ({
    DT::renderDataTable(generate_champion_stats_table(df_champion_stats %>% filter(lane=='Top'),df_champion_properties,input$champion_statistics_rank), 
                        options = list(autoWidth = TRUE,pageLength=15,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  output$champion_stats_table_jungle <- ({
    DT::renderDataTable(generate_champion_stats_table(df_champion_stats %>% filter(lane=='Jungle'),df_champion_properties,input$champion_statistics_rank), 
                        options = list(autoWidth = TRUE,pageLength=15,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  output$champion_stats_table_mid <- ({
    DT::renderDataTable(generate_champion_stats_table(df_champion_stats %>% filter(lane=='Mid'),df_champion_properties,input$champion_statistics_rank), 
                        options = list(autoWidth = TRUE,pageLength=15,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  output$champion_stats_table_bot <- ({
    DT::renderDataTable(generate_champion_stats_table(df_champion_stats %>% filter(lane=='Adc'),df_champion_properties,input$champion_statistics_rank), 
                        options = list(autoWidth = TRUE,pageLength=15,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  output$champion_stats_table_supp <- ({
    DT::renderDataTable(generate_champion_stats_table(df_champion_stats %>% filter(lane=='Supp'),df_champion_properties,input$champion_statistics_rank), 
                        options = list(autoWidth = TRUE,pageLength=15,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  
  
  ######## Combat Radar ########
  output$combat_radar_plot <- renderHighchart({
    df_ratings = generate_rating_table(df_champion_properties,
                                               input$ally_top,input$ally_jungle,input$ally_mid,input$ally_bot,input$ally_supp,
                                               input$enemy_top,input$enemy_jungle,input$enemy_mid,input$enemy_bot,input$enemy_supp)
    plot_combat_radar(df_ratings)
    
  })
  
  ######## Champion Recommendation ########
  
  output$champion_recommendation_table_top <- ({
    DT::renderDataTable(generate_champion_recommendation_table(df_champion_stats %>% filter(lane=='Top'),df_champion_properties,input$pick_ban_rank,input$favorite_champions), 
                        options = list(autoWidth = TRUE,pageLength=10,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  output$champion_recommendation_table_jungle <- ({
    DT::renderDataTable(generate_champion_recommendation_table(df_champion_stats %>% filter(lane=='Jungle'),df_champion_properties,input$pick_ban_rank,input$favorite_champions), 
                        options = list(autoWidth = TRUE,pageLength=10,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  output$champion_recommendation_table_mid <- ({
    DT::renderDataTable(generate_champion_recommendation_table(df_champion_stats %>% filter(lane=='Mid'),df_champion_properties,input$pick_ban_rank,input$favorite_champions), 
                        options = list(autoWidth = TRUE,pageLength=10,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  output$champion_recommendation_table_bot <- ({
    DT::renderDataTable(generate_champion_recommendation_table(df_champion_stats %>% filter(lane=='Adc'),df_champion_properties,input$pick_ban_rank,input$favorite_champions), 
                        options = list(autoWidth = TRUE,pageLength=10,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
  
  output$champion_recommendation_table_supp <- ({
    DT::renderDataTable(generate_champion_recommendation_table(df_champion_stats %>% filter(lane=='Supp'),df_champion_properties,input$pick_ban_rank,input$favorite_champions), 
                        options = list(autoWidth = TRUE,pageLength=10,
                                       searchHighlight = TRUE,
                                       scrollX = TRUE),
                        filter = 'top')
  })
})
