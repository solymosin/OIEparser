OIEparser <-
function(ystart, yend, timeout=10000, dbfile){
    Sys.setlocale(locale="C")
    urls = .oielinker(ystart=ystart, yend=yend)
    report.lst = .oiedl(urls, timeout=timeout)
    disease = agent = lats = lons = sdt = edt = rpt.id = c()
    no = length(report.lst)
    pb = progress_bar$new(total=no)
    for(i in 1:no){
        lapok = report.lst[[i]]
        lap = lapok[1]
        sorok = strsplit(lap, '\n')[[1]]
        bsor = sorok[which(substr(sorok, 1, 7)=='Disease')]
        if(length(bsor)>0){
            bet = strsplit(str_trim(gsub('Disease', '', bsor)), '    ')[[1]][1]    
            disease = c(disease, bet)
        } else {
            print(i)
            disease = c(disease, NA)
        }
        csor = sorok[which(tolower(substr(sorok, 1, 12))=='causal agent')]
        if(length(csor)>0){
            ag = strsplit(str_trim(substr(csor,13,nchar(csor))), '    ')[[1]][1]    
            agent = c(agent, ag)
        } else {
            agent = c(agent, NA)
        }  
        txt = ''
        for(lap in lapok){    
            txt = paste(txt, lap, sep='\n')
        }
        sorok = strsplit(txt, '\n')[[1]]
        ids = which(grepl('Latitude', sorok))
        if(length(ids)>0){
            ids = ids+1
            wd = sorok[ids]
            for(j in 1:length(wd)){
                s = wd[j]
                s = unlist(strsplit(s, ' '))
                s = s[s!='']
                nums = as.numeric(s[s!=''])
                nums = nums[!is.na(nums)]
                dts = as.Date(s, "%d/%m/%Y")
                dts = dts[!is.na(dts)]
                if(length(nums)==2 & length(dts)==2){
                    lats = c(lats, nums[1])
                    lons = c(lons, nums[2])
                    sdt = c(sdt, as.character(dts[1]))
                    edt = c(edt, as.character(dts[2]))
                    rpt.id = c(rpt.id, i)
                }
                if(length(nums)==2 & length(dts)==1){
                    lats = c(lats, nums[1])
                    lons = c(lons, nums[2])
                    sdt = c(sdt, as.character(dts[1]))
                    edt = c(edt, NA)
                    rpt.id = c(rpt.id, i)
                }               
#                 print(paste(i, j, sep='/'))
            }
            pb$tick()
            Sys.sleep(1/no)            
        }        
    }
    
    disease = str_trim(disease)
    agent = str_trim(agent)

    rdat = data.frame(id=1:length(disease), disease, agent, url=urls)
    pdat = data.frame(id=rpt.id, lons, lats, sdt, edt)
    pdat = pdat[which(abs(pdat$lons)<=180),]
    pdat = pdat[which(abs(pdat$lats)<=180),]

    db = dbConnect(SQLite(), dbfile)
    dbWriteTable(db, 'rdat', rdat, overwrite=T)
    dbWriteTable(db, 'pdat', pdat, overwrite=T)
    dbDisconnect(db)
}
