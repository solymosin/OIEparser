.oielinker <-
function(ystart, yend){
    Sys.setlocale(locale='C')
    no = (yend-ystart+1)*12
    pb = progress_bar$new(total=no)
    htms = c()
    for(y in ystart:yend){
        for(m in 1:12){
            h = new_handle()
            handle_setopt(h, customrequest = "POST")
            handle_setform(h, pdf_report_type="imm", month=as.character(m), year=as.character(y))
            r = curl_fetch_memory('http://www.oie.int/wahis_2/public/wahid.php/Diseaseinformation/reportarchive', h)
            htm = rawToChar(r$content)
            htm = strsplit(htm, '\n')[[1]]
            htms = c(htms, htm[which(grepl('reports/en_', htm))])    
            pb$tick()
            Sys.sleep(1/no)
        }
    }
    links = substr(htms, 46, 136-22)
    pdfs = paste('en_', matrix(unlist(strsplit(links, 'en_')), ncol=2, byrow=T)[,2], sep='')
    pdfs[which(substr(pdfs,37-3,37)!='.pdf')] = paste(pdfs[which(substr(pdfs,37-3,37)!='.pdf')], 'pdf', sep='')
    urls = paste('http://www.oie.int/wahis_2/temp/reports/', pdfs, sep='')
    return(urls)
}
.oiedl <-
function(urls, timeout=10000){
    Sys.setlocale(category='LC_ALL', locale='')
    no = length(urls)
    pb = progress_bar$new(total=no)
    report.lst = list()
    for(i in 1:no){
        h = new_handle()
        handle_setopt(h, connecttimeout_ms=timeout, timeout_ms=timeout)        
        url = urls[i]
        tmp = tempfile()
        curl_download(url, tmp, handle=h)
        u = pdf_text(tmp)
        report.lst[[i]] = u
        pb$tick()
        Sys.sleep(1/no)
    }
    return(report.lst)
}

.oszlop.tart <-
function(x){
  return(max(nchar(gsub(' ', '', x))))
}


.parse_step <- 
function(urls, report.lst){

k0 = 'Outbreak details'
stop.kod = 'Outbreak summary:'
stop.kodb = 'Epidemiology'

all.tab.lst = list()

head.dat = data.frame(agent=NA, disease=NA, url=NA, rptid=NA)
kus = c()

no = length(report.lst)
pb = progress_bar$new(total=no)
ku = 1
for(u in report.lst){
    fejlec = strsplit(u[[1]], k0)[[1]][1]
    
    tmp.agent = tmp.disease = NA

    fsorok = strsplit(fejlec, '\n')[[1]]
    bsor = fsorok[which(substr(fsorok, 1, 7)=='Disease')]
    if(length(bsor)>0){
        tmp.disease = strsplit(str_trim(gsub('Disease', '', bsor)), '    ')[[1]][1]        
    } 
    csor = fsorok[which(tolower(substr(fsorok, 1, 12))=='causal agent')]
    if(length(csor)>0){
        tmp.agent = strsplit(str_trim(substr(csor,13,nchar(csor))), '    ')[[1]][1]    
    }    
    
    tab.lst = list()
    tab = strsplit(u[[1]], k0)[[1]][2]
    tab = gsub('\r', '', tab)
    if(!is.na(tab)){
    
        kilep = 0
        if(length(grep(stop.kod, tab))>0){
            tab = strsplit(tab, stop.kod)[[1]][1]
            kilep = 1   
            if(tab==''){
                break
            }
        }
        
        if(length(grep(stop.kodb, tab))>0){
            tab = strsplit(tab, stop.kodb)[[1]][1]
            kilep = 1   
            if(tab==''){
                break
            }
        }      
    
        tab = .under_line(tab)
        sorok = .sorozo(tab)        
                
        if(length(sorok)>0){            
            hatarok = .hatarozo(sorok)
            wt = paste(sorok, collapse='\n')
            wt = gsub('#', '_', wt)
            wt = gsub('&', '_', wt)          
            res = read.fwf(textConnection(wt), widths=c(hatarok[1], hatarok[2:length(hatarok)]-hatarok[-length(hatarok)]))
            tab.lst[[length(tab.lst)+1]] = res          
        } 
        
        if(kilep!=1){
            for(l in 2:length(u)){
                tab = u[[l]]
                tab = gsub('\r', '', tab)
                kilep = 0

                if(length(grep(stop.kod, tab))>0){
                    tab = strsplit(tab, stop.kod)[[1]][1]
                    kilep = 1   
                    if(tab==''){
                        break
                    }
                }
                
                if(length(grep(stop.kodb, tab))>0){
                    tab = strsplit(tab, stop.kodb)[[1]][1]
                    kilep = 1   
                    if(tab==''){
                        break
                    }
                }            
                
                tab = .under_line(tab)
                sorok = .sorozo(tab)

                if(length(sorok)>0){               
                    hatarok = .hatarozo(sorok)
                    wt = paste(sorok, collapse='\n')
                    wt = gsub('#', '_', wt)
                    wt = gsub('&', '_', wt)
                    res2 = read.fwf(textConnection(wt), widths=c(hatarok[1], hatarok[2:length(hatarok)]-hatarok[-length(hatarok)]))

                    tab.lst[[length(tab.lst)+1]] = res2
                }                
                if(kilep==1){
                    break
                }
            }        
        }
        
        if(length(tab.lst)>0){
          head.dat = rbind(head.dat, data.frame(agent=tmp.agent, disease=tmp.disease, url=urls[ku], rptid=ku))        
          for(i in 1:length(tab.lst)){
            if(dim(tab.lst[[i]])[2]>10){
              rtab = tab.lst[[i]]  
              rtab[is.na(rtab)]=''
              rtab = rtab[, apply(rtab, 2, .oszlop.tart)>1]
              tab.lst[[i]] = rtab
            }
          }            
        }        
        all.tab.lst[[length(all.tab.lst)+1]] = tab.lst  
        kus = c(kus, ku)        
    } 
    ku = ku+1
    pb$tick()
    Sys.sleep(1/no)
}
    return(list(all.tab.lst, head.dat, kus))
}

.under_line <- 
function(tab){
  tab = gsub('Number of outbreaks', 'Number_of_outbreaks', tab) 
  tab = gsub('Unit Type', 'Unit_Type', tab)
  tab = gsub('Measuring units', 'Measuring_units', tab)
  tab = gsub('Start Date', 'Start_Date', tab)
  tab = gsub('End Date', 'End_Date', tab)
  tab = gsub('Affected Population', 'Affected_Population', tab)
  return(tab)
}

.sorozo <-
function(tab){
    k1 = 'Follow-up report No.:'
    k2 = 'Printed on:'
    k3 = 'Outbreak maps'
    k4 = 'Immediate notification report'
    k5 = 'The event is continuing.'
    k6 = 'Future Reporting'
    k7 = 'The report and all its'

    sorok = strsplit(tab, '\n')[[1]]  
    if(sorok[1]==''){
        sorok = sorok[-1]
    }
    
    mk = 'Affected'        
    sorok[which(substr(sorok,1,nchar(mk))==mk)] = 'Affected_Population'
    
    mk2 = 'Population'
    pop.ids = which(substr(sorok,1,nchar(mk2))==mk2)
    if(length(pop.ids)>0){
        sorok = sorok[-which(substr(sorok,1,nchar(mk2))==mk2)]
    }
    
    mk3 = 'Species'        
    sorok[which(substr(sorok,1,nchar(mk3))==mk3)] = mk3        
    
    sorok[grep('Affected_Population', sorok)] = 'Affected_Population'
    sorok = sorok[which(nchar(gsub(' ', '', substr(sorok, 1,10)))!=0)]
    
    if(length(grep(k1, sorok))>0){
        sorok = sorok[-grep(k1, sorok)]
    }

    if(length(grep(k2, sorok))>0){
        sorok = sorok[-grep(k2, sorok)]
    }
    
    if(length(grep(k3, sorok))>0){
        sorok = sorok[-grep(k3, sorok)]
    }        
    
    if(length(grep(k4, sorok))>0){
        sorok = sorok[-grep(k4, sorok)]
    }         

    if(length(grep(k5, sorok))>0){
        sorok = sorok[-grep(k5, sorok)]
    }        

    if(length(grep(k6, sorok))>0){
        sorok = sorok[-grep(k6, sorok)]
    }        

    if(length(grep(k7, sorok))>0){
        sorok = sorok[-grep(k7, sorok)]
    }   
    
    srata = nchar(gsub(' ', '', sorok))/nchar(sorok)
    srids = which(srata>0.7 & srata!=1)
    if(length(srids)!=0){
        sorok = sorok[-srids]
    }
    return(sorok)
}

.hatarozo <-
function(sorok){
    hs = nchar(sorok)
    max.char = max(hs)
    kell = max.char-hs

    for(i in 1:length(sorok)){
        sorok[i]=paste(sorok[i], paste(rep(' ', kell[i]), collapse=''), sep='')
    }

    x = sorok[1]
    m = substring(x, seq(1,nchar(x),1), seq(1,nchar(x),1))
    for(i in 2:length(sorok)){
        x = sorok[i]
        m = rbind(m, substring(x, seq(1,nchar(x),1), seq(1,nchar(x),1)))
    }
            
    tv = colSums(m==' ')==dim(m)[1]
    hatarok = c()
    for(i in 2:length(tv)){
        if(tv[i-1]==F & tv[i]==T){
            hatarok = c(hatarok, i)  
        }
    }

    hatarok = c(hatarok, length(tv))
    hatarok = sort(unique(hatarok))
    return(hatarok)
}

.db_write_step <- 
function(head.dat, all.tab.lst, dbfile, kus){

no = length(all.tab.lst)
pb = progress_bar$new(total=no)

db = dbConnect(RSQLite::SQLite(), dbfile)
head.dat = head.dat[-1,]
head.dat$kid = as.integer(head.dat$kid)

dbWriteTable(db, 'header', head.dat, append=TRUE)

for(q in 1:length(all.tab.lst)){

  rpt = all.tab.lst[[q]]  

  tmdat = data.frame(col1=NA, lat=NA, lon=NA, sdate=NA, edate=NA)

  for(tab in rpt){ 
    sdate = edate = lati = loni = 0
    for(j in 1:dim(tab)[2]){
      if(sum(grepl('Start_Date', tab[,j]))!=0)
        sdate = j
      if(sum(grepl('End_Date', tab[,j]))!=0)
        edate = j        
      if(sum(grepl('Latitude', tab[,j]))!=0)
        lati = j
      if(sum(grepl('Longitude', tab[,j]))!=0)
        loni = j                
    }
    if(lati!=0){
      tmdat = rbind(tmdat, data.frame(col1=tab[,1], lat=tab[,lati], lon=tab[,loni], sdate=tab[,sdate], edate=tab[,edate]))
    }
  }
    
  tmdat = tmdat[-1,]
  if(dim(tmdat)[1]>0){
    tmdat$col1 = str_trim(tmdat$col1)

    tmdat = tmdat[which(!grepl('Province', tmdat$col1)),]

    m = table(c(which(!is.na(as.numeric(tmdat$lon))), which(!is.na(as.numeric(tmdat$lat)))))
    nid = as.numeric(names(m)[which(m==2)])
    
    if(length(nid)>0){
        fajok = c()
        for(i in 1:length(nid)){
            stp = etp = nid[i]+1
            z = 0
            fajokv = c()
            while(tmdat[etp, 1]!='Affected_Population'){
                if(tmdat[etp, 1]=='Species'){
                    z = 1
                }
                if(z>0){
                    fajokv = c(fajokv, tmdat[etp, 1])
                }
                etp = etp+1
            }
            faj = paste(fajokv[fajokv!='Species'], collapse=' ')
            fajok = c(fajok, faj)
        }

        res.tab = data.frame(species=fajok, lat=str_trim(tmdat[nid,'lat']), lon=str_trim(tmdat[nid,'lon']), sdate=str_trim(tmdat[nid,'sdate']), edate=str_trim(tmdat[nid,'edate']), rptid=as.integer(kus[q]))
  
        dbWriteTable(db, 'outbreaks', res.tab, append=TRUE)
        }
  }
  
  pb$tick()
  Sys.sleep(1/no)
    
}
dbDisconnect(db)
}

