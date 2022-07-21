rm(list = ls())
library(ncdf4)
args <- commandArgs(TRUE)

setwd(args[6])

fixmaxmin=function(tas,tasmax,tasmin) {
  if (tas <= tasmin | tas >= tasmax | tasmax <= tasmin) {
    fixtasmax=max(c(tasmax,tasmin))
    fixtasmin=min(c(tasmax,tasmin))
    fixtas=(tasmax+tasmin)/2
  } else {
  fixtas=tas
  fixtasmax=tasmax
  fixtasmin=tasmin
  }
 return(c(fixtas,fixtasmax,fixtasmin))
}

tas.nc <- nc_open(args[1])
tasmax.nc <- nc_open(args[2])
tasmin.nc <- nc_open(args[3])
tas <- ncvar_get(tas.nc, "t2m")
tasmax <- ncvar_get(tasmax.nc, "tx")
tasmin <- ncvar_get(tasmin.nc, "tm")
      
host.tas <- host.tasmax <- host.tasmin  <- array(data=NA,dim=dim(tas))
    
for (i in 1:dim(tas)[1]) {
  for (j in 1:dim(tas)[2]) {
    if (is.na(tas[i,j,1])) {
      host.tas[i,j,] <- NA
      host.tasmax[i,j,] <- NA
      host.tasmin[i,j,] <- NA
      } else {
      for (k in 1:length(tas[i,j,])) {
        host.tas[i,j,k] <- fixmaxmin(tas[i,j,k],tasmax[i,j,k],tasmin[i,j,k])[1] 
        host.tasmax[i,j,k] <- fixmaxmin(tas[i,j,k],tasmax[i,j,k],tasmin[i,j,k])[2] 
        host.tasmin[i,j,k] <- fixmaxmin(tas[i,j,k],tasmax[i,j,k],tasmin[i,j,k])[3] 
      }  
     }
   }
}
# WRITE NCDF
lon.vals <- ncvar_get(tas.nc, "lon"); lat.vals <- ncvar_get(tas.nc, "lat"); time.vals <- ncvar_get(tas.nc, "time")
nx <- length(lon.vals); ny <- length(lat.vals); nt <- length(time.vals)
lon1 <- ncdim_def("longitude", "degrees_east", lon.vals, unlim=FALSE, create_dimvar=TRUE)
lat2 <- ncdim_def("latitude", "degrees_north", lat.vals, unlim=FALSE, create_dimvar=TRUE)
time <- ncdim_def("Time",paste("days since ",args[4],"-",args[5],"-01 12:00:00",sep=""), 0:(dim(tas)[3]-1), unlim=TRUE,create_dimvar=TRUE)
var.tas <- ncvar_def("tas", "C deg ", list(lon1, lat2, time), missval=NA,longname="Biases Corrected Temperature using Quantile Mapping", prec="float", verbose=FALSE)
var.tasmax <- ncvar_def("tasmax", "C deg ", list(lon1, lat2, time), missval=NA,longname="Biases Corrected Temperature using Quantile Mapping", prec="float", verbose=FALSE)
var.tasmin <- ncvar_def("tasmin", "C deg ", list(lon1, lat2, time), missval=NA,longname="Biases Corrected Temperature using Quantile Mapping", prec="float", verbose=FALSE)
fname.tas <- print(paste("tmp.bcsd.tasfix.",args[4],".",args[5],".nc",sep=""))
fname.tasmax <- print(paste("tmp.bcsd.tasmaxfix.",args[4],".",args[5],".nc",sep=""))
fname.tasmin <- print(paste("tmp.bcsd.tasminfix.",args[4],".",args[5],".nc",sep=""))
newtas.nc <- nc_create(fname.tas, list(var.tas),force_v4=FALSE, verbose=FALSE)
ncvar_put(newtas.nc,var.tas,host.tas,start=c(1,1,1), count=c(nx,ny,nt), verbose=FALSE)
nc_close(newtas.nc)
newtasmax.nc <- nc_create(fname.tasmax, list(var.tasmax),force_v4=FALSE, verbose=FALSE)
ncvar_put(newtasmax.nc,var.tasmax,host.tasmax,start=c(1,1,1), count=c(nx,ny,nt), verbose=FALSE)
nc_close(newtasmax.nc)
newtasmin.nc <- nc_create(fname.tasmin, list(var.tasmin),force_v4=FALSE, verbose=FALSE)
ncvar_put(newtasmin.nc,var.tasmin,host.tasmin,start=c(1,1,1), count=c(nx,ny,nt), verbose=FALSE)
nc_close(newtasmin.nc)
