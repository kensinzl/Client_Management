# https://shiny.rstudio.com/gallery/basic-datatable.html
# https://shiny.rstudio.com/gallery/nhl-play-by-play.html
ui <- dashboardPage(
    skin="blue",
    title = "Client Management",
    dashboardHeader(title=tags$h1("Client Management", style="font-size: 140%; font-weight: bold; color: white; margin-top: 3%;"),
                    titleWidth = 350),
    
    
    dashboardSidebar(
        sidebarMenu(
            menuItem("Users", tabName = "users", icon = icon("user")),
            menuItem("Group Emails", tabName = "group_emails", icon = icon("envelope")),
            menuItem("Certificate Emails", tabName = "certificate", icon = icon("book"))
        )
    ),
    
    
    dashboardBody(
        tabItems(
            # Show the existing users
            tabItem(tabName = "users", 
                    DTOutput("users_table"),
                    tags$br(),tags$br(),tags$br(),tags$br(),
                    fileInput(inputId = "input_csv", label = "Upload Users CSV", accept = c('.csv'), buttonLabel = "Browse..."),
                    downloadButton(outputId = "download_csv", label = "Download CSV", icon = shiny::icon("download"))
            ),
            
            # Group Emails
            tabItem(tabName = "group_emails",
                    fluidRow(
                        tags$style(
                            HTML(".shiny-notification {
                                     position:fixed;
                                     top: calc(50%);
                                     left: calc(50%);
                                     }"
                            )
                        ),
                        DTOutput("group_email_table"),
                        tags$br(),tags$br(),tags$br(),
                        fileInput(inputId = "input_group_email_csv", label = "Upload Group Email CSV", accept = c('.csv'), buttonLabel = "Browse..."),
                        strong(h3("Need to Replace Template and subject", align = "center", style="color:red")),
                        column(width = 4,
                               actionButton(inputId = "send_test_email", label = "Send Test Email")
                        ),
                        column(width = 4,
                               actionButton(inputId = "send_email", label = "Send Email")
                        ),
                        column(width = 3, offset = 2,
                               actionButton(inputId = "save_group_email_to_db", label = "Save DB")
                        )
                    )
            ),
            # Certificate
            tabItem(tabName = "certificate", 
                    DTOutput("certificate_users_table"),
                    tags$br(),tags$br(),tags$br(),tags$br(),
                    fileInput(inputId = "certificate_input_csv", label = "Upload Users Certificate CSV", accept = c('.csv'), buttonLabel = "Browse..."),
                    strong(h3("Review Certificates first(Click Certificate Browse Button), then send them to users(Send Certificate)", align = "center", style="color:red")),
                    column(width = 4,
                           actionButton(inputId = "certificate_test", label = "Certificate Browse")
                    ),
                    column(width = 4,
                           actionButton(inputId = "send_certificate", label = "Send Certificate")
                    )
            )
        )
    )
)


