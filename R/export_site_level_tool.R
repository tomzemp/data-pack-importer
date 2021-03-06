#' @export
#' @importFrom dplyr everything
#' @title write_site_level_sheet(wb,schema,df)
#'
#' @description Validates the layout of all relevant sheets in a data pack workbook
#' @param wb Workbook to be written to.
#' @param schema Schema object for this sheet.
#' @param d Data frame object.


write_site_level_sheet <- function(wb, schema, d) {

  # Is this always true??
  fields <- unlist(schema$fields)[-c(1:4)]
  # Create the styling for the main data table
  s <- openxlsx::createStyle(numFmt = "#,##0;-#,##0;;")
  
  # Create the OU level summary
  sums <- d$sums %>%
    dplyr::filter(match_code %in% fields) %>%
    dplyr::mutate(match_code = factor(match_code, levels = fields)) %>%
    tidyr::spread(match_code, value, drop = FALSE)

  all_zeros <- Reduce(`+`, as.matrix(sums)) == 0
  #Only write the summary if we have as single row and they are NOT all zeros.
  if (NROW(sums) == 1 & !all_zeros) {
    openxlsx::writeData(
      wb,
      sheet = schema$sheet_name,
      sums,
      xy = c(5, 4),
      colNames = F,
      keepNA = F
    )

    # Style both of the sums and formula rows and columns
    openxlsx::addStyle(
      wb,
      schema$sheet_name,
      style = s,
      rows = 4:5,
      cols = 5:(length(fields) + 5),
      gridExpand = TRUE
    )

    #Subtotal fomulas
    subtotal_formula_columns <-
      seq(from = 0,
          to = (length(fields) - 1),
          by = 1) + 5
    subtotal_formula_column_letters <-
      openxlsx::int2col(subtotal_formula_columns)
    subtotal_formulas <-
      paste0('=SUBTOTAL(109,INDIRECT($B$1&"["&',
             subtotal_formula_column_letters,
             '6&"]"))')
    
    #Conditional formatting
    #Create the conditional formatting for the subtotals
    cond_format_formula <- paste0(
      'OR(',
      subtotal_formula_column_letters,
      '5<(0.95*',
      subtotal_formula_column_letters,
      '4),',
      subtotal_formula_column_letters,
      '5>(1.05*',
      subtotal_formula_column_letters,
      '4))'
    )
    
    negStyle <-
      openxlsx::createStyle(fontColour = "#000000", bgFill = "#FFFFFF")
    posStyle <-
      openxlsx::createStyle(fontColour = "#000000", bgFill = "#ffc000")
    
    for (i in 1:(length(subtotal_formulas))) {
      openxlsx::writeFormula(wb, schema$sheet_name, subtotal_formulas[i], xy = c(i + 4, 5))
      openxlsx::conditionalFormatting(
        wb,
        sheet = schema$sheet_name,
        cols = i + 4,
        rows = 5,
        rule = cond_format_formula[i],
        style = posStyle
        
      )
    }
    
    
    #Start to prepare the main data table.
    # Filter  out this indicator
    df_indicator <- d$data_prepared %>%
      dplyr::filter(match_code %in% fields)

    if (NROW(df_indicator) == 0) {
      df_indicator <- data.frame(
        Inactive = "",
        Site = d$sites$name[1],
        Mechanism = d$mechanisms$mechanism[1],
        Type = "DSD",
        match_code = fields,
        value = NA
      )
    }

    if (NROW(df_indicator) > 0) {

      # Spread the data, being sure not to drop any levels
      df_indicator <- df_indicator %>%
        dplyr::mutate(match_code = factor(match_code, levels = fields)) %>%
        tidyr::spread(match_code, value, drop = FALSE) %>%
        dplyr::mutate(Inactive = "") %>%
        dplyr::select(Inactive, everything())
      
      #Drop any rows which are completely NA after the spread
      df_indicator <- df_indicator[rowSums(is.na(df_indicator[, -c(1:3)])) < length(fields), ]

      # Dont error even if the table does not exist
      foo <- tryCatch(
        {
          openxlsx::removeTable(wb, schema$sheet_name, schema$sheet_name)
        },
        error = function(err) {},
        finally = {}
      )

      # Write the main data table
      openxlsx::writeDataTable(
        wb,
        sheet = schema$sheet_name,
        df_indicator,
        xy = c(1, 6),
        colNames = TRUE,
        keepNA = FALSE,
        tableName = tolower(schema$sheet_name)
      )

      # Set the number of rows which we should expand styling and formulas to
      max_row_buffer <- 1000
      formula_cell_numbers <- seq(1, NROW(df_indicator) + max_row_buffer) + 6

      # Style the data table
      openxlsx::addStyle(
        wb,
        schema$sheet_name,
        style = s,
        rows = formula_cell_numbers,
        cols = 5:(length(fields) + 4),
        gridExpand = TRUE
      )

      # Inactive / NOT YET DISTRIBUTED formula in column A
      inactiveFormula <-
        paste0(
          "IF(B"
          , formula_cell_numbers
          , '<>"",IF(INDEX(site_list_table[Inactive],MATCH(B'
          , formula_cell_numbers
          , ',site_list_table[siteID],0))=1,"!!",""),"")'
        )
      openxlsx::writeFormula(wb, schema$sheet_name, inactiveFormula, xy = c(1, 7))

      # Conditional formatting for NOT YET DISTIBUTED in Column B
      distrStyle <- openxlsx::createStyle(fontColour = "#000000", bgFill = "#FF8080")
      openxlsx::conditionalFormatting(
        wb, schema$sheet_name, cols = 2,
        rows = formula_cell_numbers,
        type = "contains", rule = "NOT YET DISTRIBUTED",
        style = distrStyle
      )

      openxlsx::dataValidation(wb, schema$sheet_name, cols = 2, rows = formula_cell_numbers, "list", value = 'INDIRECT("site_list_table[siteID]")')
      openxlsx::dataValidation(wb, schema$sheet_name, cols = 3, rows = formula_cell_numbers, "list", value = 'INDIRECT("mech_list[mechID]")')
      openxlsx::dataValidation(wb, schema$sheet_name, cols = 4, rows = formula_cell_numbers, "list", value = 'INDIRECT("dsdta[type]")')
    }
  } else if (NROW(sums) > 1) {
    stop("Unhandled exception in writing column sums to the sheet!")
  } else {
    return(NA)
  }
}

#' @export
#' @importFrom utils packageVersion
#' @title export_site_level_tool(d)
#'
#' @description Validates the layout of all relevant sheets in a data pack workbook
#' @param d Object returned from the site level distribution function

export_site_level_tool <- function(d) {
  if (d$wb_info$wb_type == "NORMAL_SITE") {
    template_name <- "SiteLevelReview_TEMPLATE.xlsx"
  } else if (d$wb_info$wb_type == "HTS_SITE") {
    template_name <- "SiteLevelReview_HTS_TEMPLATE.xlsx"
  }

  template_path <- paste0(d$wb_info$support_files_path, template_name)

  output_file_path <- paste0(
    dirname(d$wb_info$wb_path),
    "/SiteLevelReview_",
    d$wb_info$wb_type,
    "_",
    d$wb_info$ou_name,
    "_",
    format(Sys.time(), "%Y%m%d%H%M%S"),
    ".xlsx"
  )

  wb <- openxlsx::loadWorkbook(file = template_path)
  sheets <- openxlsx::getSheetNames(template_path)
  openxlsx::sheetVisibility(wb)[which(sheets == "Mechs")] <- "veryHidden"

  # Fill in the Homepage details

  # OU Hidden
  openxlsx::writeData(
    wb,
    "Home",
    d$wb_info$ou_name,
    xy = c(15, 1),
    colNames = F,
    keepNA = F
  )
  # OU Name Upper case for the text box formula.
  openxlsx::writeFormula(
    wb,
    "Home",
    x = "UPPER(O1)",
    d$wb_info$ou_name,
    xy = c(15, 2)
  )

  # Workbook Type
  openxlsx::writeData(
    wb,
    "Home",
    d$wb_info$wb_type,
    xy = c(15, 3),
    colNames = F,
    keepNA = F
  )


  # OU UID
  openxlsx::writeData(
    wb,
    "Home",
    d$wb_info$ou_uid,
    xy = c(15, 4),
    colNames = F,
    keepNA = F
  )
  
  # Distribution method
  openxlsx::writeData(
    wb,
    "Home",
    d$wb_info$distribution_method,
    xy = c(15, 5),
    colNames = F,
    keepNA = F
  )
  
  # Generation timestamp
  openxlsx::writeData(
    wb,
    "Home",
    paste("Generated on:", Sys.time(), "by", rlist::list.extract(as.list(Sys.info()), "user")),
    xy = c(15, 6),
    colNames = F,
    keepNA = F
  )

  # DSD, TA options for validation
  openxlsx::writeDataTable(
    wb,
    "Home",
    data.frame(type = c("DSD", "TA")),
    xy = c(100, 1),
    colNames = T,
    keepNA = F,
    tableName = "dsdta"
  )

  # Inactive options for validation
  openxlsx::writeDataTable(
    wb,
    "Home",
    data.frame(choices = c(0, 1)),
    xy = c(101, 1),
    colNames = T,
    keepNA = F,
    tableName = "inactive_options"
  )

  # Package version
  openxlsx::writeData(
    wb,
    "Home",
    as.character(packageVersion("datapackimporter")),
    xy = c(15, 7),
    colNames = F,
    keepNA = F
  )
  
  openxlsx::showGridLines(wb, "Home", showGridLines = FALSE)

  # SiteList sheet
  site_list <- data.frame(siteID = d$sites$name, Inactive = 0) %>%
    dplyr::mutate(Inactive = dplyr::case_when(
      stringr::str_detect(siteID, "> NOT YET DISTRIBUTED")~1
      , TRUE~Inactive
    )) %>%
    dplyr::arrange(siteID)
  
  openxlsx::writeDataTable(
    wb,
    "SiteList",
    site_list,
    xy = c(1, 1),
    colNames = TRUE,
    keepNA = F,
    tableName = "site_list_table"
  )

  openxlsx::dataValidation(
    wb,
    "SiteList",
    col = 2,
    rows = 2:(NROW(site_list)+1),
    type = "list",
    value = 'INDIRECT("inactive_options[choices]")'
  )

  openxlsx::writeDataTable(
    wb,
    "Mechs",
    data.frame(mechID = d$mechanisms$mechanism),
    xy = c(1, 1),
    colNames = T,
    keepNA = F,
    tableName = "mech_list"
  )

  # Munge the data a bit to get it into shape
  d$data_prepared <- d$data %>%
    dplyr::mutate(match_code = gsub("_dsd$", "", DataPackCode)) %>%
    dplyr::mutate(match_code = gsub("_ta$", "", match_code)) %>%
    dplyr::left_join(d$mechanisms, by = "attributeoptioncombo") %>%
    dplyr::left_join(d$sites, by = c("orgunit" = "organisationunituid", "distributed" = "distributed")) %>%
    dplyr::select(name, mechanism, supportType, match_code, value) %>%
    dplyr::group_by(Site = name, Mechanism = mechanism, Type = supportType, match_code) %>%
    dplyr::summarise(value = sum(value, na.rm = TRUE))
  # Duplicates were noted here, but I think this should not have to be done.

  write_all_sheets<-function(x) {write_site_level_sheet(wb=wb,schema = x, d = d)}
  sapply(d$schemas$schema,write_all_sheets)

  openxlsx::saveWorkbook(
    wb = wb,
    file = output_file_path,
    overwrite = TRUE
  )
  print(paste0("Successfully saved output to ", output_file_path))
}