#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny bslib DT
#' @noRd
app_ui <- function(request) {
  fluidPage(
    theme = bs_theme(version = 5, bootswatch = "minty"),
    titlePanel("Analyse de données - Upload et Group By"),

    sidebarLayout(
      sidebarPanel(
        fileInput("file_upload", "Uploader un fichier",
                  accept = c(".csv", ".tsv", ".xlsx", ".rds", ".sav", ".dta", ".sas7bdat",
                             ".feather", ".parquet", ".json", ".txt", ".xml", ".ods", ".rdata")),
        # Sélection du séparateur pour les fichiers CSV
        radioButtons("separator", "Séparateur",
                     choices = c("Virgule" = ",", "Point-virgule" = ";", "Tabulation" = "\t", "Barre" = "|"),
                     selected = ","),
        # Sélecteur pour le nombre de lignes à afficher
        numericInput("n_rows", "Nombre de lignes à afficher :", value = 10, min = 1, step = 1),

        uiOutput("select_vars"),  # Sélection des variables pour le group by
        actionButton("run_groupby", "Appliquer Group By"),
        downloadButton("download_data", "Télécharger les résultats")
      ),

      mainPanel(
        DTOutput("data_preview"),     # Affichage des données avec DT
        DTOutput("grouped_data")      # Affichage des résultats groupés avec DT
      )
    )
  )
}
