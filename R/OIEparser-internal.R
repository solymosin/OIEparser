.oielinker <-
function(ystart, yend){
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
