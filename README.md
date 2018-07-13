
# OIEparser

an R package to create SQLite database from the OIE reports

### Installation from github:


```R
library(devtools)

install_github('solymosin/OIEparser')

```

## Example


```R
library(OIEparser)

options(stringsAsFactors=F)

```

### downloading the data of 2018


```R
OIEparser(ystart=2018, yend=2018, timeout=10000, dbfile='db2018.sqlite')
```

### query the ASF outbreaks in wild boars, between 01/01/2018 and 01/03/2018


```R

db = dbConnect(RSQLite::SQLite(), 'db2018.sqlite')

sql = "SELECT * FROM outbreaks LEFT JOIN header ON outbreaks.rptid = header.rptid where 
    disease='African swine fever' and 
    sdate>'2018-01-01' and 
    sdate<'2018-03-01' and 
    species like '%wild%'"

tab = dbGetQuery(db, sql)

head(tab)

```


<table>
<thead><tr><th scope=col>species</th><th scope=col>lat</th><th scope=col>lon</th><th scope=col>sdate</th><th scope=col>edate</th><th scope=col>rptid</th><th scope=col>agent</th><th scope=col>disease</th><th scope=col>url</th><th scope=col>rptid..10</th></tr></thead>
<tbody>
	<tr><td>Wild boar:Suidae(Sus scrofa)                                                 </td><td>52.433889                                                                    </td><td>20.795833                                                                    </td><td>2018-01-02                                                                   </td><td>2018-01-08                                                                   </td><td>2                                                                            </td><td>African swine fever virus                                                    </td><td>African swine fever                                                          </td><td>http://www.oie.int/wahis_2/temp/reports/en_fup_0000025830_20180202_170404.pdf</td><td>2                                                                            </td></tr>
	<tr><td>Wild boar:Suidae(Sus scrofa)                                                 </td><td>52.024444                                                                    </td><td>21.168333                                                                    </td><td>2018-01-02                                                                   </td><td>2018-01-08                                                                   </td><td>2                                                                            </td><td>African swine fever virus                                                    </td><td>African swine fever                                                          </td><td>http://www.oie.int/wahis_2/temp/reports/en_fup_0000025830_20180202_170404.pdf</td><td>2                                                                            </td></tr>
	<tr><td>Wild boar:Suidae(Sus scrofa)                                                 </td><td>52.024444                                                                    </td><td>21.167221                                                                    </td><td>2018-01-02                                                                   </td><td>2018-01-06                                                                   </td><td>2                                                                            </td><td>African swine fever virus                                                    </td><td>African swine fever                                                          </td><td>http://www.oie.int/wahis_2/temp/reports/en_fup_0000025830_20180202_170404.pdf</td><td>2                                                                            </td></tr>
	<tr><td>Wild boar:Suidae(Sus scrofa)                                                 </td><td>52.051944                                                                    </td><td>21.186944                                                                    </td><td>2018-01-02                                                                   </td><td>2018-01-06                                                                   </td><td>2                                                                            </td><td>African swine fever virus                                                    </td><td>African swine fever                                                          </td><td>http://www.oie.int/wahis_2/temp/reports/en_fup_0000025830_20180202_170404.pdf</td><td>2                                                                            </td></tr>
	<tr><td>Wild boar:Suidae(Sus scrofa)                                                 </td><td>52.061667                                                                    </td><td>21.180833                                                                    </td><td>2018-01-02                                                                   </td><td>2018-01-06                                                                   </td><td>2                                                                            </td><td>African swine fever virus                                                    </td><td>African swine fever                                                          </td><td>http://www.oie.int/wahis_2/temp/reports/en_fup_0000025830_20180202_170404.pdf</td><td>2                                                                            </td></tr>
	<tr><td>Wild boar:Suidae(Sus scrofa)                                                 </td><td>52.434167                                                                    </td><td>20.916389                                                                    </td><td>2018-01-02                                                                   </td><td>2018-01-09                                                                   </td><td>2                                                                            </td><td>African swine fever virus                                                    </td><td>African swine fever                                                          </td><td>http://www.oie.int/wahis_2/temp/reports/en_fup_0000025830_20180202_170404.pdf</td><td>2                                                                            </td></tr>
</tbody>
</table>




```R
library(sp)

m = cbind(x=as.numeric(tab$lon), y=as.numeric(tab$lat))
sptab = SpatialPoints(m, proj4string=CRS('+init=epsg:4326'))

plot(sptab)

```

![png](https://github.com/solymosin/OIEparser/blob/master/man/figs/output_8_0.png)


```R
library(tmap)

data(Europe)

tm_shape(Europe) + tm_polygons() + 
tm_shape(sptab) + tm_dots(col='yellow', size=0.1) +
tm_format_Europe() +
tm_style_grey()
```

![png](https://github.com/solymosin/OIEparser/blob/master/man/figs/output_9_1.png)


```R
eu = spTransform(Europe, CRS('+init=epsg:4326'))

tm_shape(eu, bbox=bbox(sptab)) + tm_polygons() + 
tm_shape(sptab) + tm_dots(col='yellow', size=0.1) +
tm_compass(color.light='grey90', size=2, fontsize=1, type='rose', position=c('left', 'top')) +
tm_scale_bar(size=0.6, position=c('right', 'top')) + 
tm_format_Europe() +
tm_style_grey() 

```

![png](https://github.com/solymosin/OIEparser/blob/master/man/figs/output_10_1.png)


### Export as ESRI Shape file


```R
library(rgdal)

writeOGR(obj=sptab, layer='ASF', driver='ESRI Shapefile', dsn='ASF_folder')

```

#### Opening in QGIS 

![QGIS](https://github.com/solymosin/OIEparser/blob/master/man/figs/QGIS.png)

### Export as KML


```R
library(plotKML)

pnt = 'http://plotkml.r-forge.r-project.org/circle.png'

kml(sptab, folder.name='ASF', file.name='ASF.kml', 
    subfolder.name='outbreaks', shape=pnt, size=1, 
    kmz=T, colour='red', 
    TimeSpan.begin=sptab$sdate, TimeSpan.end=sptab$edate, 
    points_names=paste(sptab$sdate, sptab$edate,  sep=' - '), 
    html.table=sptab$url)

```

#### Opening in Google Earth 

![Google Earth](https://github.com/solymosin/OIEparser/blob/master/man/figs/GoogleEarth.png)
