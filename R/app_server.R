#' The application server logic optimisée
#'
#' @import shiny data.table vroom readxl arrow haven jsonlite xml2 readODS DT
#' @noRd
app_server <- function(input, output, session) {

  options(shiny.maxRequestSize = 1000 * 1024^2)

  # Lecture du fichier uploadé
  data <- reactive({
    req(input$file_upload)
    file <- input$file_upload$datapath
    ext <- tools::file_ext(file)

    switch(ext,
           csv = data.table::fread(file, sep = input$separator),  # Lecture rapide des CSV avec data.table
           tsv = data.table::fread(file, sep = "\t"),  # TSV traité comme un CSV avec séparateur tabulation
           xlsx = readxl::read_xlsx(file),
           rds = readRDS(file),
           sav = haven::read_sav(file),
           dta = haven::read_dta(file),
           sas7bdat = haven::read_sas(file),
           feather = arrow::read_feather(file),
           parquet = arrow::read_parquet(file),
           json = jsonlite::fromJSON(file),
           txt = vroom::vroom(file, delim = input$separator),  # Utilisation de vroom pour les fichiers texte volumineux
           xml = xml2::read_xml(file),
           ods = readODS::read_ods(file),
           rdata = {
             load(file)
             get(ls()[1])
           },
           stop("Format de fichier non supporté.")
    )
  })

  # Affichage des variables disponibles pour le group by
  output$select_vars <- renderUI({
    req(data())
    selectInput("group_var", "Sélectionner une variable pour le group by",
                choices = names(data()), multiple = TRUE)
  })

  # Affichage des données importées avec DT (pagination côté serveur)
  output$data_preview <- renderDT({
    req(data())
    datatable(head(data(), input$n_rows), options = list(pageLength = input$n_rows, server = TRUE))
  })

  # Calcul du group by avec data.table pour une performance accrue
  grouped_data <- reactive({
    req(input$group_var)
    dt <- as.data.table(data())

    # Utilisation de list() pour permettre un group by dynamique avec data.table
    dt[, lapply(.SD, sum, na.rm = TRUE), by = c(input$group_var), .SDcols = sapply(dt, is.numeric)]
  })

  # Affichage des résultats du group by avec DT (pagination côté serveur)
  output$grouped_data <- renderDT({
    req(grouped_data())
    datatable(grouped_data(), options = list(pageLength = 10, server = TRUE))
  })

  # Télécharger les résultats
  output$download_data <- downloadHandler(
    filename = function() {
      paste("grouped_data_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      fwrite(grouped_data(), file)  # Utilisation de fwrite de data.table pour un export rapide
    }
  )
}
