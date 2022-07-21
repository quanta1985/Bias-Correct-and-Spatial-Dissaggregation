### BIAS CORRECTION AND CHANGE FACTOR ###

rm(list = ls())
library(ncdf4)
library(abind)
library(dplyr)
library(qmap)
args <- commandArgs(TRUE)
setwd(args[3])
yearbgn=as.numeric(args[1])
yearend=as.numeric(args[2])

#### function quantile mapping ####
qm <- function(obscell,hiscell,fucell){
  QM=fitQmap(obscell,hiscell,method=c("QUANT"))
  bias.corrected <- doQmap(fucell,QM)
  return(bias.corrected)
}


for (m in 1:12) {                                                 # loop for 12 months
  if (m<10) {                                                     # read mon 01-09 
    obs <- nc_open(print(paste("tmp.obs_0",m,".nc",sep="")))
    his <- nc_open(print(paste("tmp.his_0",m,".nc",sep="")))
    fu <- nc_open(print(paste("tmp.fu_0",m,".nc",sep="")))
  } else {                                                        # read mon 10-12 
    obs <- nc_open(print(paste("tmp.obs_",m,".nc",sep="")))
    his <- nc_open(print(paste("tmp.his_",m,".nc",sep="")))
    fu <- nc_open(print(paste("tmp.fu_",m,".nc",sep="")))
  }
  obs.pr <- ncvar_get(obs, "pr")                                # all variable are pr
  his.pr <- ncvar_get(his, "pr")
  fu.pr <- ncvar_get(fu, "pr")
    
  host <- array(data=NA,dim=dim(fu.pr))                          # create the host blank matrix 
    
  for (i in 1:dim(obs.pr)[1]) {        
    for (j in 1:dim(obs.pr)[2]) {
      if (is.na(obs.pr[i,j,1])) {
        host[i,j,] <- NA                                          # All cells oustside VN will be NA
      } else {
        host[i,j,] <- qm(obs.pr[i,j,],his.pr[i,j,],fu.pr[i,j,]) # QM for inside cells
      }
    }
  }
 

#### WRITE NETCDF FILE OUTPUT FOR EACH MONTH####
# there are 10 times step for each months, write to annual data of 10 years (1986-1995)
#Define dimension of output
print(paste("Writing the temperature bias correction using QM"))
lon.vals <- ncvar_get(fu, "lon"); lat.vals <- ncvar_get(fu, "lat"); time.vals <- ncvar_get(fu, "time")
nx <- length(lon.vals); ny <- length(lat.vals); nt <- length(time.vals)
lon1 <- ncdim_def("longitude", "degrees_east", lon.vals, unlim=FALSE, create_dimvar=TRUE)
lat2 <- ncdim_def("latitude", "degrees_north", lat.vals, unlim=FALSE, create_dimvar=TRUE)
if (m<10) {
  time <- ncdim_def("Time",paste("years since ",yearbgn,"-0",m,"-16 12:00:00",sep=""), 0:(yearend-yearbgn), unlim=TRUE,create_dimvar=TRUE) #fu year   i
  } else {
    time <- ncdim_def("Time",paste("years since ",yearbgn,"-",m,"-16 12:00:00",sep=""), 0:(yearend-yearbgn), unlim=TRUE,create_dimvar=TRUE) #fu yearu
  }
#Define variable to write to the output
var_rain.bc <- ncvar_def("pr", "C degree", list(lon1, lat2, time), missval=NA,longname="Biases Correctet precipitation using Quantile Mapping", prec="float", verbose=FALSE)
    
#Create the blank netcdf file
fname <- print(paste("pr.",m,".nc",sep=""))
new.nc <- nc_create(fname, list(var_rain.bc),force_v4=FALSE, verbose=FALSE)
ncvar_put(new.nc,var_rain.bc,host,start=c(1,1,1), count=c(nx,ny,nt), verbose=FALSE)
nc_close(new.nc) 
} 

system(paste("sh tmp.split_merge.sh",sep=(""))) # ACtivate a small programe to split and merge back  monthly bias corrected data 
