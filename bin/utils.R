################################################################################

                    #   #     #####     #     #          #####
                    #   #       #       #     #         #
                    #   #       #       #     #         #####
                    #   #       #       #     #             # 
                     ###        #       #     ####     #####

################################################################################

#' Minmax scaling
#' 
#' Rescales numeric vector to range a-b (default: 0-1)
#' Based on the formula {\displaystyle x'=a+{\frac {(x-{\text{min}}(x))(b-a)}{{\text{max}}(x)-{\text{min}}(x)}}}
#' 
#' @param x Numeric vector
#' @param a Lower limit
#' @param b Upper limit
#' 
#' @export
minmax <- function(x, a=0, b=1) {

  stopifnot(is.numeric(x))

  y <- a + ( (x-min(x)*(b-a) ) / (max(x) - min(x)) )

  return(y)
}

#' Get list entry and use NA for missing information
#'
#' Get entries from list entries and ignore missing information (e.g. NULL)
#' as well as errors (e.g. missing columns in data.frame)
#' 
get_list_entry <- function(x) {

    x <- tryCatch(
        error = function(cnd) NA, x
    )

    if (is.null(x)) {x <- NA}

    return(x)
}

#' Wrapper for NCBI datasets CLI
#'
#' @param inputfile File of accession numbers
#' @param type Dataset type (genome or virus genome)
#' @param virus Specify whether genomes are of viral origin
#' @param include Specify genome sequence types to download
#' @param overwrite Boolean whether to overwrite existing output (default: FALSE)
#' @param outputdir Directory name for file archive (internal, use with care!)
#'
#' @export
download_ncbi_genomes <- function(inputfile=NULL,
                                  type='virus genome',
                                  include=NULL,
                                  overwrite=FALSE
                                 ) {

    # Check input

    ## Accession numbers & input formats
    stopifnot(
        !is.null(inputfile),
        file.exists(inputfile),
        type %in% c('genome','virus genome'),
        class(include) %in% c('NULL','character')
    )

    ## Dataset command level 1: download OR summary
    # Not available at the moment.

    ## Sequence types to include
    include_categories_virus_genome <- c('genome','cds','protein','annotation','biosample','none')
    include_categories_genome <- c('genome','rna','protein','cds','gff3','gtf','gbff','seq-report','none')
    if (is.null(include) & type == 'virus genome') {
        include <- c('genome','cds','protein','annotation','biosample')
    } else if (is.null(include) & type == 'genome') {
        include <- c('genome','rna','protein','cds','gff3','gtf','gbff','seq-report')
    } else if (type == 'virus genome' & all(include %in% include_categories_virus_genome)) {
        # Fine
    } else if (type == 'genome' & all(include %in% include_categories_genome)) {
        # Fine
    } else {
        stop('Sequence types to include were specified wrong. Aborting.')
    }

    # Check for dependencies (NOT TESTED !!!)
    programs_to_check <- c('datasets','unzip','dataformat')
    missing_programs <- c()
    for (i in programs_to_check) {
        detect <- !Sys.which(i) == ''
        if (!detect) {
            missing_programs <- c(missing_programs, i)
        }
    }
    if (length(missing_programs) > 0) {
        stop(paste('Not all dependencies met. Missing:', missing_programs))
    }
    
    # Direct output
    outputdir <- 'ncbi_dataset'
    PATH <- dirname(inputfile)
    logfile <- paste0(PATH,'/download.log')
    zipfile <- paste0(PATH,'/',outputdir,'.zip')
    archive <- paste0(PATH,'/',outputdir,'/')
    datapath <- paste0(archive,'data/')
    fetchfile <- paste0(archive,'fetch.txt')
    metafile <- paste0(datapath,'metadata.tsv')
    missing_id_file <- paste0(PATH,'/missing_accessions.txt')
    md5file <- paste0(PATH,'/md5sum.txt')

    # Check if output present
    if (dir.exists(archive) & !overwrite) {
        stop('Output directory already exists. Set overwrite flag to replace.')
    } else if (dir.exists(archive) & overwrite) {
        warning('Overwrite flag set. Removing output.')
        file.remove(zipfile)
        unlink(archive, recursive = TRUE)
    }

    # Call datasets
    call_datasets <- paste0(
        'datasets download ',type,' accession --inputfile ',inputfile,' --filename ',zipfile,
        ' --include ',paste0(include,collapse = ','),' > ',logfile,' 2>&1'
    )
    cat(call_datasets,'\n\n')
    system(call_datasets, intern=TRUE)

    # Extract archive
    cat('Unzip\n\n')
    unzip(zipfile, exdir = PATH)

    ## Check file integrity
    checksum <- utils::read.table(md5file, col.names = c('old','path'))
    checksum$path <- paste0(PATH,'/',checksum$path)
    checksum$new <- tools::md5sum(checksum$path)
    if (!all(checksum$new == checksum$old)) {
        warning('Checksums differ. Data integrity is compromised.') ### WARNING BUT NOT ERROR !!!
    } else {
        message('Checksums identical. Files were downloaded without problems.')
    }

    # Remove ZIP archive
    file.remove(zipfile)
    
    # Rehydrate
    if (file.exists(fetchfile)) {
        sys_call <- paste0('datasets rehydrate --directory ',archive,' >> logfile 2>&1')
        system(sys_call, intern=TRUE)
    }
    
    # Format output (via dataformat)

    ## Annotation report
    fromfile <- paste0(datapath,'annotation_report.jsonl')
    tofile <- paste0(datapath,'features.gtf')
    if (file.exists(fromfile)) {
        sys_call <- paste0('dataformat tsv virus-annotation --inputfile ',fromfile,' > ',tofile)
        cat(sys_call,'\n\n')
        system(sys_call, intern=TRUE)
    }
    
    ## Data report
    fromfile <- paste0(datapath,'data_report.jsonl')
    tofile <- paste0(datapath,'metadata.tsv')
    if (file.exists(fromfile)) {
        sys_call <- paste0('dataformat tsv virus-genome --inputfile ',fromfile,' > ',tofile)
        cat(sys_call,'\n\n')
        system(sys_call, intern=TRUE)
    }

    # Check output
    
    ## Compare accession input vs. output
    acc_in <- readLines(inputfile)
    acc_out <- utils::read.delim(metafile)$Accession
    if (all(acc_in %in% acc_out)) {
        message('All accession IDs retrieved successfully')
    } else {
        warning('Not all accession IDs retrieved. Exporting missing IDs...')
        index <- acc_in %in% acc_out
        cat('Entries retrieved:',table(index)[2],'of',length(index),'\n\n')
        missing_ids <- acc_in[!index]
        writeLines(missing_ids, missing_id_file)
    }    
    
    ## Test, test, test, ...
    
    cat('Done.')
}