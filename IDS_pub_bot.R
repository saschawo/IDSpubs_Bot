library(xml2)
library(rtoot)
library(parallel)

options("rtoot_token" = "IDSpub_token.Rds")

# Load saved data
saved_publications <- readRDS("~/Data/pubs.Rds")

# Get new data
p <- "https://pub.ids-mannheim.de/autoren/ids/"
# parse page
doc <- read_html(p)

# Get all author nodes from display grid
authors <- xml_find_all(doc, "//div[2]/div/div/div/a[not(starts-with(@href, '/')) and
                              not(@href='')]") 

# Get XML text from authors
names <- xml_text(authors)

# Get links from authors and paste them to the base URL
links <- xml_attr(authors, "href")
links <- paste0(p, links)

# Create a data frame with the names and links
df <- data.frame(names, links)

# Function: Extracts all publications from a given author page
get_pub <- function(p) {
  # Parse page
  pub_doc <- read_html(p)
  
  # Get all entries and put them in a dataframe
  dt <- xml_text(xml_find_all(pub_doc, "//dt"))
  dd <- xml_text(xml_find_all(pub_doc, "//dd"))
  # Select everything before \t from dd and trim string
  dd <- gsub("\t.*", "", dd)
  dd <- trimws(dd)
  
  pub_df <- unique(data.frame(aut_yr = dt, title = dd))
  rm(dt, dd)
  
  # Extract year from dt column and save in year column
  pub_df$year <- gsub(".*\\(", "", pub_df$aut_yr)
  pub_df$year <- as.numeric(gsub("\\).*", "", pub_df$year))
  
  # Extract authors only from aut_yr column and save in aut column
  pub_df$aut <- gsub("\\(.*", "", pub_df$aut_yr)
  pub_df$aut <- trimws(pub_df$aut)
  
  return(pub_df)
}

# Get all publications from all authors
pubs <- mclapply(seq_along(df$links), mc.cores = 8, mc.preschedule = F, FUN = function (url_ind) {
    if (url_ind %% 10 == 0) {
      cat(url_ind, "of", length(df$links), "authors\n")
    }
    get_pub(df$links[url_ind])
})
cat("All downloaded.\n")
pubs <- dplyr::bind_rows(pubs)
pubs <- unique(pubs)

saveRDS(pubs, "~/Data/pubs.Rds")

# Get new publications
new_pubs <- pubs[!(pubs$title %in% saved_publications$title), ]
new_pubs <- new_pubs[new_pubs$year >= 2023 & !is.na(new_pubs$year),]
if (nrow(new_pubs) > 0) {
  cat("Tooting", nrow(new_pubs), "new publications.\n")
  new_pubs$toot_text <- paste(new_pubs$aut_yr, new_pubs$title)
  for (pub_i in new_pubs$toot_text) {
    post_toot(pub_i)
    Sys.sleep(10)
  } } else { cat("No new publications.\n") }

