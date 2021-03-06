\name{OIEparser}
\alias{OIEparser}
\title{
OIE report parser function
}
\description{
This function downloads the OIE pdf reports and parses the mostly used data for epidemiology studies.
}
\usage{
OIEparser(ystart, yend, timeout = 10000, dbfile)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{ystart}{the starting year of the query}
  \item{yend}{the ending year of the query}
  \item{timeout}{internet connection timeout in ms}
  \item{dbfile}{the name of the target SQLite database}
}
\details{
}
\value{
}
\references{
}
\author{
}
\note{
}

\seealso{

}
\examples{
\dontrun{
OIEparser(ystart=2018, yend=2018, timeout=10000, dbfile='OIEdb.sqlite')
}
}
