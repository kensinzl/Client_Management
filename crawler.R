#install.packages("rvest")
library(rvest)
library(tidyverse)

targets = do.call("rbind", lapply(c(0: 47), function(page) {
  prfix = 'https://gazette.education.govt.nz/vacancies?Regions=new-zealand-nation-wide&SectorsAndRoles=early-learniong-kohanga-reo&start='
  startIndex = page * 10
  suffix = '#results'
  page_url = paste0(prfix, startIndex, suffix)
  site = read_html(page_url)
  kindergarten_names = site %>% html_elements("article a h3") %>% html_text()
  
  kindergarten_url_prefix = "https://gazette.education.govt.nz"
  part_urls <- (site %>% html_elements("article a") %>% html_attr("href"))[1:10]
  kindergarten_urls = paste0(kindergarten_url_prefix, part_urls)
  
  data.frame(name = kindergarten_names, url = kindergarten_urls)

}))


final = do.call("rbind", lapply(c(1: nrow(targets)), function(index) {
  one_kindergarten_name = targets[index, ][1]
  one_kindergarten_url = targets[index, ][2]
  site = read_html(as.character(one_kindergarten_url))
  email = (site %>% html_nodes(".block-vacancy-apply p a"))[1] %>% html_text()
  user_name = strsplit((site %>% html_nodes(".block-vacancy-apply p"))[2] %>% html_text(), "\n")[[1]][1]
  #print(email)
  #print(user_name)
  #print(one_kindergarten_name)
  #user_name
  
  data.frame(kindergarten = one_kindergarten_name, email = email, user = user_name, url = one_kindergarten_url)
}))

write.csv(final, file = "kindergarten.csv", row.names = TRUE)





