### BIAS CORRECTION AND CHANGE FACTOR ###


rm(list = ls())
library(ncdf4)
library(abind)
library(dplyr)
args <- commandArgs(TRUE)
setwd(args[3])
yearbgn=as.numeric(args[1])
yearend=as.numeric(args[2])

#### function quantile mapping ####
qm <- function(obs,his,fu) {
  quantile <- ecdf(his)(fu)
  bc <- quantile(obs,quantile,na.rm=FALSE)
  bc <- as.numeric(bc)
  return(bc)
}

for (e in 1:3) {                                                    # loop for tas, tasmax, tasmin
  for (m in 1:12) {                                                 # loop for 12 months
    if (m<10) {                                                     # read mon 01-09 
      obs <- nc_open(print(paste("tmp.obs",e,"_0",m,".anomaly.nc",sep="")))
      his <- nc_open(print(paste("tmp.his",e,"_0",m,".anomaly.nc",sep="")))
      fu <- nc_open(print(paste("tmp.fu",e,"_0",m,".anomaly.nc",sep="")))
    } else {                                                        # read mon 10-12 
      obs <- nc_open(print(paste("tmp.obs",e,"_",m,".anomaly.nc",sep="")))
      his <- nc_open(print(paste("tmp.his",e,"_",m,".anomaly.nc",sep="")))
      fu <- nc_open(print(paste("tmp.fu",e,"_",m,".anomaly.nc",sep="")))
    }
    obs.tas <- ncvar_get(obs, "tas")                                # all variable are tas
    his.tas <- ncvar_get(his, "tas")
    fu.tas <- ncvar_get(fu, "tas")
    
    host <- array(data=NA,dim=dim(fu.tas))                          # create the host blank matrix 
    
    for (i in 1:dim(obs.tas)[1]) {        
      for (j in 1:dim(obs.tas)[2]) {
        if (is.na(obs.tas[i,j,1])) {
          host[i,j,] <- NA                                          # All cells oustside VN will be NA
        } else {
          host[i,j,] <- qm(obs.tas[i,j,],his.tas[i,j,],fu.tas[i,j,]) # QM for inside cells
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
      time <- ncdim_def("Time",paste("years since ",yearbgn,"-0",m,"-16 12:00:00",sep=""), 0:(yearend-yearbgn), unlim=TRUE,create_dimvar=TRUE) #fu year
    } else {
      time <- ncdim_def("Time",paste("years since ",yearbgn,"-",m,"-16 12:00:00",sep=""), 0:(yearend-yearbgn), unlim=TRUE,create_dimvar=TRUE) #fu year
    }
    #Define variable to write to the output
    var_rain.bc <- ncvar_def("tas", "C degree", list(lon1, lat2, time), missval=NA,longname="Biases Corrected Temperature using Quantile Mapping", prec="float", verbose=FALSE)
    
    #Create the blank netcdf file
    fname <- print(paste("tas.",m,".nc",sep=""))
    new.nc <- nc_create(fname, list(var_rain.bc),force_v4=FALSE, verbose=FALSE)
    ncvar_put(new.nc,var_rain.bc,host,start=c(1,1,1), count=c(nx,ny,nt), verbose=FALSE)
    nc_close(new.nc) 
  }
  
  system(paste("sh tmp.split_merge.sh",sep=(""))) # ACtivate a small programe to split and merge back  monthly bias corrected data 
  system(paste("mv bc.tas.nc bc.tas.",e,".nc",sep=(""))) # write loop output for tas, tasmax, tasmin
}
