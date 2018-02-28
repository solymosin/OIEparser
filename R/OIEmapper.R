OIEmapper <-
function(disease, dbfile){
  # shp is
  # dátum intervallum
  db = dbConnect(SQLite(), dbfile)  
  sql = paste("select * from rdat JOIN pdat ON rdat.id=pdat.id where disease='", disease,"'", sep='')
  dat = dbGetQuery(db, sql)
  dbDisconnect(db)
  dat$uid = paste(dat$lons, dat$lats, dat$sdt, sep='-')

  lst = split(dat[,c('id', 'lons', 'lats', 'sdt', 'edt')], dat$uid)
  i = 1
  tmp = lst[[i]]
  tmp = tmp[sort.list(as.Date(tmp$edt), decreasing=T),]
  tmp = tmp[1,]
  tmp$uid = names(lst)[i]
  res = tmp
  for(i in 2:length(lst)){
    tmp = lst[[i]]
    tmp = tmp[sort.list(as.Date(tmp$edt), decreasing=T),]
    tmp = tmp[1,]
    tmp$uid = names(lst)[i]
    res = rbind(res, tmp)
  }
  
  lst = split(dat$url, dat$uid)
  i = 1
  tmp = lst[[i]]
  lres = data.frame(uid=names(lst)[i], link=paste(sort(unique(tmp)), collapse=';'))
  for(i in 2:length(lst)){
    tmp = lst[[i]]
  #   links = sort(unique(tmp))
    lres = rbind(lres, data.frame(uid=names(lst)[i], link=paste(sort(unique(tmp)), collapse='<br />')))
  }

  map = merge(res, lres, by.x='uid', by.y='uid')
  map$x = map$lons
  map$y = map$lats
  coordinates(map) = ~x+y
  proj4string(map) = CRS('+init=epsg:4326')
  # kml(map, kmz=T)
  pnt = 'http://plotkml.r-forge.r-project.org/circle.png'

  kml(map, folder.name=disease, file.name=paste(disease, '.kml', sep=''), subfolder.name='outbreaks', shape=pnt, size=1, kmz=T, colour='red', TimeSpan.begin=res$sdt, TimeSpan.end=res$edt, points_names=paste(res$sdt, res$edt,  sep=' - '), html.table=map$link)
}
