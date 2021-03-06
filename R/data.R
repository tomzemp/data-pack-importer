#' @export
#' @title hts_schema
#'
#' @description Returns the HTS Schema
#' @return Returns a list which defines the schema for the HTS Disagg tool
#'
#' HTS Schemas of the Data Pack Excel sheets
"hts_schema"

#' @export
#' @title main_schema
#'
#' @description Normal Schemas of the Data Pack Excel sheets
#' @return Returns a list which defines the schema for the  Disagg tool
#'
"main_schema"

#' @export
#' @title mechs
#'
#' @description List of mechanisms and codes
#' @return Returns a two column data frame with mechanisms and codes
#'
"mechs"

#' @export
#' @title impatt
#'
#' @description List of option codes for PSNU prioritization
#' @return Returns a three column data frame with code,name and Data Pack code (dp_code)
#'
"impatt"

#' @export
#' @title support_files_md5
#'
#' @description Object used for validation of support files
#' @return Returns an object with the following columns
"support_files_md5"

#' @export
#' @title rCOP18deMapT
#'
#' @description Object used for mapping indicators and disaggs across time, including from FY19 PSNU level to FY19 Site level. Does not translate new indicators/disaggs
#' @return Returns an object with the following columns
"rCOP18deMapT"

#' @export
#' @title clusters
#'
#' @description Object used dealing with distribution of values from clusters to PSNUs
#' @return Returns an object with the following columns
"clusters"


#' @export
#' @title sites_exclude
#'
#' @description Vector of sites to exlcude
#' @return Returns a character vector of UIDs
"sites_exclude"

#' @export
#' @title psnus
#'
#' @description PSNU UIDs and names
#' @return Returns a list of data frames
"psnus"

#' @export
#' @title militaryUnits
#'
#' @description PSNU UIDs and names
#' @return Returns a data frame of military units which shold be exlcuded
"militaryUnits"

#' @export
#' @title hts_site_schema
#'
#' @description Schema of the HTS site level tool
#' @return A list of column and row positions
"hts_site_schema"

#' @export
#' @title main_site_schema
#'
#' @description Schema of the Normal site level tool
#' @return  A list of column and row positions
"main_site_schema"