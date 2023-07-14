####
## IUCN Red List of Ecosystems in Africa
## J.R. Ferrer-Paris https://github.com/jrfep
## This is a Shiny web application (in development), showing proportional areas of ecosystem functional groups per region
####


library(shiny)
library(ggplot2)
library(vroom)
library(dplyr)
require(sf)
library(lwgeom)

lcc_proj <- "+proj=lcc +lat_1=20 +lat_2=-23 +lat_0=0 +lon_0=25 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m no_defs"

here::i_am("inc/R/app.R")

Africa <- read_sf(here::here("Data","Africa.gpkg")) %>% 
  st_transform(crs=lcc_proj)

regions <- c("Southern Africa", "Eastern Africa", "Western Africa", "Middle Africa", 
             "Northern Africa", "Marine area")

DataEFGs <- vroom(dir(here::here("Data","area-calc","areas-per-country"),
                      full.names=T))  %>% 
  mutate(code = gsub("([MFTS0-9\\.]+)-[a-z_.]+","\\1", code),
         biome = gsub("([MFTS0-9]+).[0-9]+","\\1", code))

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("IUCN Global Ecosystem Typology in Africa"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
          selectInput("biome", "Choose the biomes:",
                      list(`Terrestrial` = list("T1","T2","T3","T4","T5","T6"),
                           `Pallustrine wetlands` = list("TF1"),
                           `Subterranean` = list("S1","SF1","SM1"),
                           `Freshwater` = list("F1","F2"),
                           `Marine` = list("M1","M2","M3"),
                           `Coastal` = list("FM1", "MT1", "MT2","MFT1"),
                           `Anthropogenic` = list("T7","F3","M4","S2","MT3","SF2")),
                      multiple=TRUE,
                      selected=c("T1","T2","T3","T4","T5","T6","TF1")),

        selectInput("countries", "Choose subregion:",
                    regions,
                    multiple=TRUE)
    ),
        # Show a plot of the generated distribution
        mainPanel(
           plotOutput("polarPlot"),
           plotOutput("mapPlot")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  filteredMap <- reactive({
    if (is.null(input$countries)) {
      Africa
    } else {
      if (any(input$countries) %in% "All") {
        Africa
      } else {
        Africa %>% filter(SUBREGION %in% input$countries)
      }
    }
  })

  filteredData <- reactive({
    if (is.null(input$countries)) {
      DataEFGs %>% 
        filter(biome %in% input$biome) %>% 
        group_by(biome,code) %>% 
        summarise(
          countries=n_distinct(OBJECTID),
          major=sum(major)*100,
          minor=sum(minor)*100)
    } else {
      filteredMap() %>% 
        st_drop_geometry() %>% 
        pull(OBJECTID) -> slc
      
      DataEFGs %>% 
        filter(biome %in% input$biome,OBJECTID %in% slc) %>% 
        group_by(biome,code) %>% 
        summarise(
          countries=n_distinct(OBJECTID),
          major=sum(major)*100,
          minor=sum(minor)*100)
    }
  })

    output$polarPlot <- renderPlot({
      ggplot(filteredData(), aes(x=code, y=major, fill=biome)) + 
        geom_bar(width=1, stat='identity') + 
        theme_light() + 
        coord_polar() + 
        labs(title="Ecosystems in Africa", 
             x="Ecosystem Functional Group",
             y="% of global major distribution",fill="Biome")
      #ggplot(filteredData(), aes(x=code, y=major, fill=biome)) + geom_bar(width=1, stat='identity') + theme_light()
      #p
    })
    output$mapPlot <- renderPlot({
      p <- ggplot(Africa, aes(colour=SUBREGION,fill=SUBREGION %in% "Marine area")) + 
        geom_sf() + 
        theme_light() + 
        theme(legend.position="None") + 
        scale_fill_manual(values=c("lightgrey","aliceblue"))

        p + geom_sf(data=filteredMap(), fill='darkgrey')
        #+ geom_sf_text(  aes(label = ISO_A2))
    })
}

# Run the application
shinyApp(ui = ui, server = server)
