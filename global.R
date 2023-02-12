library(shiny)
library(shinydashboard)
library(DT)
library(tidyverse)
library(DBI)
library(RSQLite)
library(stringr)
library(pagedown)
library(mailR)
library(zip)
library(googledrive)



# https://datacarpentry.org/R-ecology-lesson/05-r-and-databases.html
# when you upload the csv, its layout have to match the table column(no case senstive)
# user_table_sql = "
# CREATE TABLE USERS
# (
#   NAME TEXT,
#   STREET TEXT,
#   SUBURB TEXT,
#   CITY TEXT,
#   INSTITUTION_TYPE TEXT,
#   REGION TEXT,
#   PHONE TEXT,
#   EMAIL TEXT
# )"
  
# transaction_table_sql = "
# CREATE TABLE TRANSACTIONS
# (
#   NAME TEXT,
#   STREET TEXT,
#   SUBURB TEXT,
#   CITY TEXT,
#   INSTITUTION_TYPE TEXT,
#   REGION TEXT,
#   PHONE TEXT,
#   EMAIL TEXT,
#   EVENT_DATE
# )"
  

# print login user
print(paste("No user login", drive_user()$emailAddress))
# first time to login to get the token at local, interactive way
# copy the secret from ~/Library/Caches/gargle into project folder
# remember you cant change the name, how stupid
#drive_auth()
options(gargle_oauth_email = "zlchldjyy@gmail.com")
options(gargle_oauth_cache = "./secret")
drive_auth(email = gargle::gargle_oauth_email(), cache = gargle::gargle_oauth_cache())
# print login user
print(paste("User login", drive_user()$emailAddress))
# Find RSQLite DB on Google Drive
db = drive_get("USER_INFO.db")
# Download from Google Drive
drive_download(as_id(db$id), overwrite = TRUE)


# create the connect, if db not exist, then create it
conn = dbConnect(RSQLite::SQLite(), "USER_INFO.db")

# Google cert
google_pwd = ""


# create related tables if not exist
# does_exist_users = dbGetQuery(conn, "SELECT count(name) FROM sqlite_master WHERE type='table' AND name='USERS'")
# if(does_exist_users == 0) {
#   dbExecute(conn, user_table_sql)
#   print("----- create USERS table")
#   # insert the test data
#   # dbExecute(conn,"INSERT INTO USERS (NAME, EMAIL, PHONE, ACTIVE) VALUES ('liang', '851561330@qq.com', '0221001850', 'TRUE')")
# }
# does_exist_transactions = dbGetQuery(conn, "SELECT count(name) FROM sqlite_master WHERE type='table' AND name='TRANSACTIONS'")
# if(does_exist_transactions == 0) {
#   dbExecute(conn, transaction_table_sql)
#   dbExecute(conn, "INSERT INTO TRANSACTIONS (USER_ID, USER_NAME, DATE, AMOUNT) VALUES (1, 'liang', datetime('now', 'localtime'), 100.01)")
# }

#dbGetQuery(conn, 'SELECT * FROM USERS WHERE "NAME" = :name', params = list(name = "liang"))
#users = dbGetQuery(conn, 'SELECT * FROM USERS')
#transactions = dbGetQuery(conn, 'SELECT * FROM TRANSACTIONS')





# # Okay, the R shiny package is so bad, it will change the layout during convert HTML into JPEG
# # Now only change the Client Name
# certificate_template = readLines("./www/certificate_name.html") %>%
#                           str_replace(pattern = "CLIENT_NAME", replacement = "Liang ZHAO") 
#                           #%>% str_replace(pattern = "EVENT", replacement = "Super Yue Event") %>%
#                           #str_replace(pattern = "PRESENTER_NAME", replacement = "Helen Armstrong") %>%
#                           #str_replace(pattern = "DATE", replacement = as.character(Sys.Date()))
# # save into final certificate
# writeLines(text = certificate_template, con = "./www/final_certificate.html")
# 
# 
# # https://community.rstudio.com/t/error-when-using-pagedown-chrome-print-in-shinyapps-io/102027/9
# # https://github.com/RLesur/chrome_print_shiny/blob/master/app.R
# # https://community.rstudio.com/t/how-to-properly-configure-google-chrome-on-shinyapps-io-because-of-webshot2/109020/5
chrome_extra_args <- function(default_args = c("--disable-gpu")) {
  args <- default_args
  # Test whether we are in a shinyapps container
  if (identical(Sys.getenv("R_CONFIG_ACTIVE"), "shinyapps")) {
    args <- c(args,
              "--no-sandbox", # required because we are in a container
              "--disable-dev-shm-usage") # in case of low available memory
  }
  args
}
# 
# # need change the size
# pagedown::chrome_print(input = "./www/final_certificate.html",
#                        output = "./www/Certificate.jpeg",
#                        extra_args = chrome_extra_args(),
#                        wait = 1,
#                        format = "jpeg",
#                        verbose = 0,
#                        async = FALSE)



##################################################################
##                  Html Email Part
##################################################################
# https://west2.cn/2315.html
# I store the image at the Google Drive
# send.mail(from = "Nurture Heart NZ <nurtureheartnz@gmail.com>", # using this email as the smtp server
#           to = c("zlchldjyy@gmail.com", "superyue0401@gmail.com"),
#           subject = " My Test Email ",
#           body = read_file("html_email.html"),
#           attach.files = c("./www/presenter_sign.png", "./www/final_certificate.pdf"),
#           html = TRUE,
#           encoding = "utf-8",
#           smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "nurtureheartnz@gmail.com", passwd = "", ssl = TRUE),
#           authenticate = TRUE,
#           send = TRUE
#         )



