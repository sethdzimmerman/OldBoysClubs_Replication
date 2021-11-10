# this program reads in:
#   spatial files I made in qgis 
#   the intermediate data file with room attributes 
# and produces: figures to help visualize room prices and rblocks

# in qgis, I have made two types of 'vector' files containing polygons and attribute tables:
#   gpkg files named [dorm][floor]_rooms_georeg.gpkg contain the vector layers of rooms
#   gpkg files named [dorm][floor]_fl_sw_georeg.gpkg contain the vector layers of dorm_floor_stairwell proximity groups
# as well as raster files of the original floor plan images georeferenced to the dorm footprints

# all spatial files are in a mercator projections

# I use the 'tmap' package primarily for visualization
# 


rm(list=ls())

dirRAW<-"../../Raw Data/Layers"
dirINT<-"../../Intermediate Data/Stata Files/"
dirFIG<-"../../Output/Figures/"

setwd(dirRAW)

require(haven) ## version 2.4.3
require(tidyverse) ## version 1.3.0
require(raster) ## version 3.1-5
require(rgdal) ## version 1.4-8
require(sf) ## version 1.0-3
require(tmap) ## version 3.0

gore1 <- readOGR("gore1_rooms_georef.gpkg", stringsAsFactors = FALSE)
plot(gore1)
base_gore1<-raster("gore1_base_georef.tif")
standish1 <- readOGR("standish1_rooms_georef.gpkg", stringsAsFactors = FALSE)
plot(standish1)
smith1 <- readOGR("smith1_rooms_georef.gpkg", stringsAsFactors = FALSE)
plot(smith1)

smith2 <- readOGR("smith2_rooms_georef.gpkg", stringsAsFactors = FALSE)
gore2 <- readOGR("gore2_rooms_georef.gpkg", stringsAsFactors = FALSE)
standish2 <- readOGR("standish2_rooms_georef.gpkg", stringsAsFactors = FALSE)
smith3 <- readOGR("smith3_rooms_georef.gpkg", stringsAsFactors = FALSE)
gore3 <- readOGR("gore3_rooms_georef.gpkg", stringsAsFactors = FALSE)
standish3 <- readOGR("standish3_rooms_georef.gpkg", stringsAsFactors = FALSE)
smith4 <- readOGR("smith4_rooms_georef.gpkg", stringsAsFactors = FALSE)
gore4 <- readOGR("gore4_rooms_georef.gpkg", stringsAsFactors = FALSE)
standish4 <- readOGR("standish4_rooms_georef.gpkg", stringsAsFactors = FALSE)


flsw_smith1 <- readOGR("smith1_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_smith2 <- readOGR("smith2_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_smith3 <- readOGR("smith3_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_smith4 <- readOGR("smith4_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_standish1 <- readOGR("standish1_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_standish2 <- readOGR("standish2_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_standish3 <- readOGR("standish3_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_standish4 <- readOGR("standish4_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_gore1 <- readOGR("gore1_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_gore2 <- readOGR("gore2_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_gore3 <- readOGR("gore3_fl_sw_georef.gpkg", stringsAsFactors = FALSE)
flsw_gore4 <- readOGR("gore4_fl_sw_georef.gpkg", stringsAsFactors = FALSE)

sf_flsw_smith1 <- st_as_sf(flsw_smith1)
sf_flsw_smith2 <- st_as_sf(flsw_smith2)
sf_flsw_smith3 <- st_as_sf(flsw_smith3)
sf_flsw_smith4 <- st_as_sf(flsw_smith4)
sf_flsw_standish1 <- st_as_sf(flsw_standish1)
sf_flsw_standish2 <- st_as_sf(flsw_standish2)
sf_flsw_standish3 <- st_as_sf(flsw_standish3)
sf_flsw_standish4 <- st_as_sf(flsw_standish4)
sf_flsw_gore1 <- st_as_sf(flsw_gore1)
sf_flsw_gore2 <- st_as_sf(flsw_gore2)
sf_flsw_gore3 <- st_as_sf(flsw_gore3)
sf_flsw_gore4 <- st_as_sf(flsw_gore4)

#gore1 <- readOGR("Gore_floor1_room_layer.gpkg", stringsAsFactors = FALSE)
#colnames(gore1@data)<-tolower(colnames(gore1@data)) 

setwd(dirINT)

rooms_all<-read_dta("rooms_all_grays_fixed.dta") 
rooms<-rooms_all[rooms_all$year==1919,] # I am only plotting Gore, Standish, and Smith, so want the earlier set of prices


setwd(dirRAW)

#gore1@data<-base::merge(gore1@data,rooms,
#                        by=c("dorm","roomno","floor"),all.x=TRUE)

# I am converting the spatial files to sf class for compatibility with the 'tmap' package
sf_gore1 <- st_as_sf(gore1) 
sf_standish1<-st_as_sf(standish1) 
sf_smith1<-st_as_sf(smith1) 
sf_gore2 <- st_as_sf(gore2) 
sf_standish2<-st_as_sf(standish2) 
sf_smith2<-st_as_sf(smith2) 
sf_gore3 <- st_as_sf(gore3) 
sf_standish3<-st_as_sf(standish3) 
sf_smith3<-st_as_sf(smith3) 
sf_gore4 <- st_as_sf(gore4) 
sf_standish4<-st_as_sf(standish4) 
sf_smith4<-st_as_sf(smith4) 

# correct typos from the attribute tables (it is easier to do this here than back in qgis)
sf_standish3$dorm[sf_standish3$dorm=="Standsih"]<-"Standish"
sf_flsw_standish2$dorm[sf_flsw_standish2$dorm=="Gore"]<-"Standish"
sf_flsw_standish4$stairwell[sf_flsw_standish4$stairwell=="B 41"]<-"B"

# stack together the 'room' level polygons
dorms<-rbind(sf_gore1,sf_standish1,sf_smith1,
             sf_gore2,sf_standish2,sf_smith2,
             sf_gore3,sf_standish3,sf_smith3,
             sf_gore4,sf_standish4,sf_smith4)
# merge in the flat room data (price, capactity, etc.) to room polygons
dorms<-base::merge(dorms,rooms,by=c("dorm","roomno","floor"),all.x=TRUE)

# stack together the dorm_floor_stairwell proximity groups
# note that  this is the dorm_nbd for the dorms I am dealing with (Gore, Standish, and Smith)
best<-rbind(sf_flsw_gore1,sf_flsw_standish1,sf_flsw_smith1,
            sf_flsw_gore2, sf_flsw_standish2,sf_flsw_smith2, #   
            sf_flsw_gore3,sf_flsw_standish3,sf_flsw_smith3,
            sf_flsw_gore4,sf_flsw_standish4,sf_flsw_smith4)
# select the dorm_nbd level variables from the rooms data
mpi<-rooms[,c("dorm","floor","stairwell","dorm_nbd","dorm_nbd_id","mpi_dorm_nbd")]
mpi<-distinct(mpi)
# merge dorm_nbd level variables into the best prox group spatial file
best<-base::merge(best,mpi,by=c("dorm","stairwell","floor"),all.x=TRUE)

# for the visualization, I chose a low-price rblock and high-price rblock to serve as example cases
# these are on the larger end in terms of number of rooms and are on the high and low ends but not extreme tails of the distribution of prices

# the low-price rblock is a per-student price of $175 with occupancy of two
# 175, 2 
dorms$rblock_low<-NA
dorms$rblock_low[dorms$price_per_student==175 & dorms$roomcap==2]<-1
dorms$mp_best_rblock_low<-dorms$mp_dorm_nbd*dorms$rblock_low

# the high-price rblock is a per-student price of $300 with occupancy of two
# 300, 1
dorms$rblock_high<-NA
dorms$rblock_high[dorms$price_per_student==300 & dorms$roomcap==1]<-1
dorms$mp_best_rblock_high<-dorms$mp_dorm_nbd*dorms$rblock_high

# I drop the fifth floors because they are generally a single high-occupancy room that doubles as an rblock (so they will drop out)
# and twelve floors already make a crowded image 
# drop fifth floors
dorms<-dorms[dorms$floor<5,]
dorms$building<-dorms$dorm
dorms$building[dorms$dorm %in% c("Persis Smith", "James Smith","George Smith")]<-"Smith"
dorms$building_floor<-as.factor(paste0(dorms$building,"; floor ",dorms$floor))

dorms$rblock<-""
dorms$rblock[dorms$rblock_high==1]<-"300"
dorms$rblock[dorms$rblock_low==1]<-"175"

dorms$rblock_text<-""
dorms$rblock_text[dorms$rblock_high==1]<-"$300 per student;\n single"
dorms$rblock_text[dorms$rblock_low==1]<-"$175 per student;\n double"

# drop fifth floor
best<-best[best$floor<5,]
best$building<-best$dorm
best$building[best$dorm %in% c("Persis Smith", "James Smith","George Smith")]<-"Smith"
best$building_floor<-as.factor(paste0(best$building,"; floor ",best$floor))

# a challenge I ran into with making these plots was that tmap, while modeled after ggplot, does not have all the same functionality
# using facets with multiple layers would not display correctly if not all of the facets had records in a layer
# because not ever dorm*floor has each rblock, this was a problem
# the color of the border of polygons could not be assigned by value (unlike the fill), so that was not a work around
# thus, the solution I landed on is the rather clunky code below which makes each figure and then displays them with grid.arrange instead



mpi_breaks<-c(0,25*c(6:11)) #c(25*c(0:9),260) # assign break points to be used in the legend for mean prox group price
ppp_lwd<-2 # line width for the rooms that fall within the rblock
pls<-.7 # panel label size is the font size of the lables, e.g., "Gore; floor 1" displayed above each panel
buildings<-c("Gore","Standish","Smith")
floors<-c(1,2,3,4)

####### Display both high and low rblocks ########
store<-list()
count<-0
for(i in 1:3){
  for (j in 1:length(floors)){
    count<-count+1
    bf<-paste0(buildings[[i]],"; floor ",floors[[j]])
    store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
      tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
      tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) 
    if (bf %in% dorms$building_floor[dorms$rblock_low==1] & bf %in% dorms$building_floor[dorms$rblock_high==1]){ 
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) +
        tm_shape(dorms[dorms$rblock_low==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="green", lwd=ppp_lwd,
                    title = "Randomization block", legend.show=FALSE)+
        tm_shape(dorms[dorms$rblock_high==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="blue", lwd=ppp_lwd,
                    title = "Randomization block", legend.show=FALSE) 
    }else if (bf %in% dorms$building_floor[dorms$rblock_high==1]){ 
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) +
      tm_shape(dorms[dorms$rblock_high==1 & dorms$building_floor==bf,])+
      tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="blue", lwd=ppp_lwd,
                  title = "Randomization block", legend.show=FALSE) 
    }else if (bf %in% dorms$building_floor[dorms$rblock_low==1]){ 
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) +
        tm_shape(dorms[dorms$rblock_low==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="green", lwd=ppp_lwd,
                    title = "Randomization block", legend.show=FALSE) 
    }
    if (bf=="Smith; floor 3"){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks, legend.show = FALSE) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls)+
        tm_shape(dorms[dorms$rblock_low==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="green", lwd=ppp_lwd,
                    title = "Randomization block", legend.show = FALSE)+
        tm_shape(dorms[dorms$rblock_high==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="blue", lwd=ppp_lwd,
                    title = "Randomization block", legend.show = TRUE)+
        tm_layout(panel.labels = bf,  panel.show = TRUE,
                  legend.outside=TRUE, legend.outside.position="bottom")
    }
    if (bf=="Smith; floor 2"){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks, legend.show = FALSE) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls)+
        tm_shape(dorms[dorms$rblock_low==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="green", lwd=ppp_lwd,
                    title = "Randomization block", legend.show = TRUE)+
        tm_layout(panel.labels = bf,  panel.show = TRUE,
                  legend.outside=TRUE, legend.outside.position="bottom")
    }
    if (bf %in% c("Smith; floor 1")){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,
                  legend.outside=TRUE, legend.outside.position="bottom",
                  legend.title.size = 1.25)
    }
    if (bf %in% c("Smith; floor 4")){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks, legend.show = FALSE) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls, attr.outside=TRUE)#+
        #tm_scale_bar(position = "center")+ # tm_compass()+
       # tm_credits("\n footnotes here? \n \n", size=1, position="center")
    }
  }
}
tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3)


setwd(dirFIG)
tmap_save(tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3),"mpi_with_two_rblocks.png")
setwd(dirRAW)

####### Display low rblock only ########
store<-list()
count<-0
for(i in 1:3){
  for (j in 1:length(floors)){
    count<-count+1
    bf<-paste0(buildings[[i]],"; floor ",floors[[j]])
    store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
      tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
      tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) 
if (bf %in% dorms$building_floor[dorms$rblock_low==1]){ 
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) +
        tm_shape(dorms[dorms$rblock_low==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="blue", lwd=ppp_lwd,
                    title = "Randomization block", legend.show=FALSE) 
    }
    if (bf=="Smith; floor 2"){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks, legend.show = FALSE) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls)+
        tm_shape(dorms[dorms$rblock_low==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="blue", lwd=ppp_lwd,
                    title = "Randomization block", legend.show = TRUE)+
        tm_layout(panel.labels = bf,  panel.show = TRUE,
                  legend.outside=TRUE, legend.outside.position="bottom", legend.text.size  = 1.5,
                  legend.title.size = 1.5)
    }
    if (bf %in% c("Smith; floor 1")){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,
                  legend.outside=TRUE, legend.outside.position="bottom",
                  legend.title.size = 1.25)
    }
    if (bf %in% c("Smith; floor 4")){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks, legend.show = FALSE) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls, attr.outside=TRUE)#+
      #tm_scale_bar(position = "center")+ # tm_compass()+
      # tm_credits("\n footnotes here? \n \n", size=1, position="center")
    }
  }
}
tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3)

setwd(dirFIG)
tmap_save(tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3),"mpi_with_low_rblock_blue.png")
setwd(dirRAW)


####### Display high rblock only ########
store<-list()
count<-0
for(i in 1:3){
  for (j in 1:length(floors)){
    count<-count+1
    bf<-paste0(buildings[[i]],"; floor ",floors[[j]])
    store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
      tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
      tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) 
   if (bf %in% dorms$building_floor[dorms$rblock_high==1]){ 
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) +
        tm_shape(dorms[dorms$rblock_high==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="blue", lwd=ppp_lwd,
                    title = "Randomization block", legend.show=FALSE) 
    }
    if (bf=="Smith; floor 3"){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks, legend.show = FALSE) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls)+
#        tm_shape(dorms[dorms$rblock_low==1 & dorms$building_floor==bf,])+
#        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="green", lwd=ppp_lwd,
#                    title = "Randomization block", legend.show = FALSE)+
        tm_shape(dorms[dorms$rblock_high==1 & dorms$building_floor==bf,])+
        tm_polygons("rblock_text",alpha=0, border.alpha=1 , border.col="blue", lwd=ppp_lwd,
                    title = "Randomization block", legend.show = TRUE)+
        tm_layout(panel.labels = bf,  panel.show = TRUE,
                  legend.outside=TRUE, legend.outside.position="bottom")
    }
      if (bf %in% c("Smith; floor 4")){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,
                  legend.outside=TRUE, legend.outside.position="bottom",
                  legend.title.size = 1.25)
    }
  }
}
tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3)

setwd(dirFIG)
tmap_save(tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3),"mpi_with_high_rblock.png")
setwd(dirRAW)

## ####### MPI only ########
store<-list()
count<-0
for(i in 1:3){
  for (j in 1:length(floors)){
    count<-count+1
    bf<-paste0(buildings[[i]],"; floor ",floors[[j]])
    store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
      tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
      tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) 
    if (bf %in% c("Smith; floor 4")){
      store[[count]]<-tm_shape(best[best$building_floor==bf,])+ 
        tm_polygons("mpi_dorm_nbd", title="Mean Neighborhood Price", breaks=mpi_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,
                  legend.outside=TRUE, legend.outside.position="bottom",
                  legend.title.size = 1.25)
    }
  }
}
tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3)

setwd(dirFIG)
tmap_save(tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3),"mpi.png")
setwd(dirRAW)



## ####### PPS (price per student) only ########
pps_breaks<-c(100*c(0:5))
store<-list()
count<-0
for(i in 1:3){
  for (j in 1:length(floors)){
    count<-count+1
    bf<-paste0(buildings[[i]],"; floor ",floors[[j]])
    store[[count]]<-tm_shape(dorms[dorms$building_floor==bf,])+ 
      tm_polygons("price_per_student", title="Price Per Student", palette="Blues", breaks=pps_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
      tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,legend.show=FALSE) 
    if (bf %in% c("Smith; floor 4")){
      store[[count]]<-tm_shape(dorms[dorms$building_floor==bf,])+ 
        tm_polygons("price_per_student", title="Price Per Student", palette="Blues", breaks=pps_breaks) + #+ tm_facets("building_floor")+ #+tm_layout(legend.outside = TRUE) 
        tm_layout(panel.labels = bf,  panel.show = TRUE, panel.label.size = pls,
                  legend.outside=TRUE, legend.outside.position="bottom",
                  legend.title.size = 1.25)
    }
  }
}
tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3)

setwd(dirFIG)
tmap_save(tmap_arrange(store,heights = c(.25,.25,.5),nrow = 3),"pps.png")

