OIEparser <-
function(ystart, yend, timeout=10000, dbfile){
  oldw = getOption("warn")
  options(warn = -1)
  urls = .oielinker(ystart=ystart, yend=yend)
  report.lst = .oiedl(urls, timeout=timeout)
  gg = .parse_step(urls, report.lst)
  .db_write_step(gg[[2]], gg[[1]], dbfile, gg[[3]])
  options(warn = oldw)
}
