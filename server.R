server = function(input, output, session) {
    
    ##################################################################
    ##                  Output All Users
    ##################################################################
    output$users_table = renderDT({
        
            inFile = input$input_csv
            
            if(!is.null(inFile)) {
                csv_users = read.csv(inFile$datapath, header = TRUE, sep =",") %>% filter(!is.na(Email) & trimws(Email) != "")
                csv_users$Email = trimws(csv_users$Email)
                # remove the duplicate user based at the email column
                csv_users = csv_users[!duplicated(csv_users$Email), ]
                # remove the user whose email has already in the db
                new_users = do.call(rbind, lapply(c(1: nrow(csv_users)), function(index) {
                    user = csv_users[index, ]
                    existing_user = dbGetQuery(conn, 'SELECT * FROM USERS WHERE "EMAIL" = :email', params = list(email = user$Email))
                    if(nrow(existing_user) == 0) {
                        user
                    }
                }))
                if(!is.null(new_users)) {
                    #dbWriteTable(conn, "USERS", new_users, overwrite = TRUE)
                    dbAppendTable(conn, "USERS", new_users)  
                    # Upload the new USER_INFO.db
                    drive_upload("USER_INFO.db", overwrite = TRUE)
                }
            } 
            
            all_users = dbGetQuery(conn, 'SELECT * FROM USERS')

            datatable(all_users, options = list(autoWidth = TRUE))
        })
    
    ##################################################################
    ##                  Download All Users As CSV
    ##################################################################
    output$download_csv = downloadHandler(
        filename = function() { 
            paste("All_User-", Sys.Date(), ".csv", sep="")
        },
        content = function(file) {
            all_users = dbGetQuery(conn, 'SELECT * FROM USERS')
            write.csv(all_users, file)
        })
    
 
    ##################################################################
    ##                  Output Group Email Table and Send Email
    ##################################################################
    reactive_group_users_email = reactive({ # save the group user email as the global var
        
        inFile = input$input_group_email_csv
        
        group_users_email = read.csv(inFile$datapath, header = TRUE, sep =",") %>% filter(!is.na(Email) & trimws(Email) != "")
        group_users_email$Email = trimws(group_users_email$Email)
        # remove the duplicate user based at the email column
        group_users_email = group_users_email[!duplicated(group_users_email$Email), ]
        group_users_email
    })
    
    output$group_email_table = renderDT({
        inFile = input$input_group_email_csv
        if(!is.null(inFile)) {
            group_users_email = reactive_group_users_email()
            datatable(group_users_email, options = list(autoWidth = TRUE))
        } 
    })
    
    ##################################################################
    ##                  Test Email To Check Layout
    ##################################################################
    # https://productivity.godaddy.com/#/mailbox/28184832
    # https://sg.godaddy.com/help/enable-smtp-authentication-40981
    # https://productivity.godaddy.com/#/ => Users => Manage => Advanced Settings => SMTP => ON
    observeEvent(input$send_test_email, {
        send.mail(from = sender,
                  to = c("superyue0401@gmail.com", "zlchldjyy@gmail.com"),
                  subject = " This is a Test Email ",
                  body = read_file("./www/html_email.html"),
                  #attach.files = c("./www/presenter_sign.png", "./www/final_certificate.pdf"),
                  html = TRUE,
                  encoding = "utf-8",
                  smtp = list(host.name = smtp_server, port = smtp_port, user.name = email, passwd = email_password, tls = TRUE),
                  authenticate = TRUE,
                  send = TRUE
                )
        showNotification("Test Email Has Send Out!")
    })
    
    ##################################################################
    ##                  Group Email
    ##################################################################
    observeEvent(input$send_email, {
        
        send.mail(from = sender, 
                  to = reactive_group_users_email()$Email,
                  subject = " Test Email ",
                  body = read_file("./www/html_email.html"),
                  #attach.files = c("./www/presenter_sign.png", "./www/final_certificate.pdf"),
                  html = TRUE,
                  encoding = "utf-8",
                  smtp = list(host.name = smtp_server, port = smtp_port, user.name = email, passwd = email_password, tls = TRUE),
                  authenticate = TRUE,
                  send = TRUE
        )
        showNotification("Group Email All Send Out!!!")
    })
    
    ##################################################################
    ##                  Save Group Email Into DB
    ##################################################################
    observeEvent(input$save_group_email_to_db, {
        
        inFile = input$input_group_email_csv
        
        if(!is.null(inFile)) {
            group_users_email = reactive_group_users_email()
            # new user from group email users
            new_users = do.call(rbind, lapply(c(1: nrow(group_users_email)), function(index) {
                user = group_users_email[index, ]
                existing_user = dbGetQuery(conn, 'SELECT * FROM USERS WHERE "EMAIL" = :email', params = list(email = user$Email))
                if(nrow(existing_user) == 0) {
                    user
                }
            }))
            if(!is.null(new_users)) {
                dbAppendTable(conn, "USERS", new_users)  
                # Upload the new USER_INFO.db
                drive_upload("USER_INFO.db", overwrite = TRUE)
                showNotification("Save Into DB !!!")
            }
        } 
    })
    
    ##################################################################
    ##       Generate All Certificates Among Folder and Send
    ##################################################################
    reactive_all_certificate_users = reactive({ # save the group certificate user email as the global var
        inFile = input$certificate_input_csv
        all_certificate_users = read.csv(inFile$datapath, header = TRUE, sep =",") %>% filter(!is.na(Email) & trimws(Email) != "")
        all_certificate_users$Email = trimws(all_certificate_users$Email)
        # remove the duplicate user based at the email column
        all_certificate_users = all_certificate_users[!duplicated(all_certificate_users$Email), ]
        all_certificate_users
    })
    
    observeEvent(input$certificate_test, {
        # Generate all certificate jpeg
        lapply(c(1: nrow(reactive_all_certificate_users())), function(index) {
            user = reactive_all_certificate_users()[index, ]
            # Okay, the R shiny package is so bad, it will change the layout during convert HTML into JPEG
            # Now only change the Client Name
            certificate_template = readLines("./www/certificate_name.html") %>%
                str_replace(pattern = "CLIENT_NAME", replacement = user$Name) 
            # save into final certificate
            generate_html_path = paste0("./cert/Certificate_", user$Name,".html")
            
            writeLines(text = certificate_template, con = generate_html_path)
            
            # html -> jpeg
            pagedown::chrome_print(input = generate_html_path,
                                   output = paste0("./cert/Certificate_", user$Name,".jpeg"),
                                   extra_args = chrome_extra_args(),
                                   wait = 1,
                                   format = "jpeg",
                                   verbose = 0,
                                   async = FALSE)
        })
        
        # compress all certificates into a zip folder
        zip(zipfile = "Certificate.zip", files = "cert", recurse = TRUE)
        # Send all certificate as a zip to review fist
        send.mail(from = sender,
                  to = c("superyue0401@gmail.com", "zlchldjyy@gmail.com"),
                  subject = " Certificates For Users ",
                  body = '<HTML><body><h1 style = "color: red; ">Please review the layout of the certificates first</h1></body></HTML>',
                  attach.files = "Certificate.zip",
                  html = TRUE,
                  encoding = "utf-8",
                  smtp = list(host.name = smtp_server, port = smtp_port, user.name = email, passwd = email_password, tls = TRUE),
                  authenticate = TRUE,
                  send = TRUE
        )
        showNotification("Certificate Email Has Send Out!")
    })
    
    # save the users who already bought event into transactions table
    observeEvent(input$save_user_transactions_to_db, {
        transactions_users = reactive_all_certificate_users()
        transactions_users$Event_Date = Sys.Date()
        # new user from group email users
        new_transactions_users = do.call(rbind, lapply(c(1: nrow(transactions_users)), function(index) {
            user = transactions_users[index, ]
            existing_user = dbGetQuery(conn, 'SELECT * FROM TRANSACTIONS WHERE "EMAIL" = :email', params = list(email = user$Email))
            if(nrow(existing_user) == 0) {
                user
            }
        }))
        if(!is.null(new_transactions_users)) {
            dbAppendTable(conn, "TRANSACTIONS", new_transactions_users)  
            # Upload the new USER_INFO.db
            drive_upload("USER_INFO.db", overwrite = TRUE)
            showNotification("Save Into DB !!!")
        }
    })
    
    # send the generated Certificate to each users
    observeEvent(input$send_certificate, {
        lapply(c(1: nrow(reactive_all_certificate_users())), function(index) {
            user = reactive_all_certificate_users()[index, ]
            # send the certficate to each user
            send.mail(from = sender,
                      to = c(user$Email),
                      subject = "Congratulations on joining your event!",
                      body = paste0("<HTML>
                                        <body>
                                            <p>Hi ",user$Name,"</p>
                                            <p>Congratulations! You have earned the certificate. </p>
                                            <p>Best regards, </p>
                                            <p>Nurture Heart NZ </p>
                                        </body>
                                        </HTML>"
                                    ),
                      attach.files = paste0("./cert/Certificate_", user$Name,".jpeg"),
                      html = TRUE,
                      encoding = "utf-8",
                      #smtp = list(host.name = "smtp.gmail.com", port = 465, user.name = "nurtureheartnz@gmail.com", passwd = google_pwd, ssl = TRUE),
                      smtp = list(host.name = smtp_server, port = smtp_port, user.name = email, passwd = email_password, tls = TRUE),
                      authenticate = TRUE,
                      send = TRUE
            )
        })
        
        # Delete the generated html and certficate of cert folder
        unlink("Certificate.zip")
        unlink("./cert/*.jpeg")
        unlink("./cert/*.html")
        
        showNotification("Certificate Email Has Send Out!")
    })
    
    output$certificate_users_table = renderDT({
        
        inFile = input$certificate_input_csv
        
        if(!is.null(inFile)) {
            all_certificate_users = reactive_all_certificate_users()
            datatable(all_certificate_users, options = list(autoWidth = TRUE))
        } 
        
    })
    #https://www.jdtrat.com/blog/connect-shiny-google/
    #https://debruine.github.io/shinyintro/data.html
    
    ##################################################################
    ##       Show transaction into UI
    ##################################################################
    output$users_transactions_table = renderDT({
        all_transaction_users = dbGetQuery(conn, 'SELECT * FROM TRANSACTIONS')
        datatable(all_transaction_users, options = list(autoWidth = TRUE))
    })
}