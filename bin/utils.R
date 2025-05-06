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

#' Extract attributes from GFF3
#'
#' Extract values from GFF3 attributes and add columns to object
#'
#' @param object Data.frame formatted as GFF3
#' @param attribute_key String appended to columns to indicate they are extracted from 'attributes'
#'
#' @returns data.frame
#'
#' @export
extract_gff3_attributes <- function(object=NULL, attribute_key='attribute_') {

    stopifnot(
        !is.null(object),
        class(object) == 'data.frame'
    )

    # Checks
    if (!'attributes' %in% names(object)) {
        msg <- 'Column attributes not present in GFF3 file. Aborting.'
        stop(msg)
    }

    # Extract attributes
    x <- str_split(object[['attributes']], ';')

    # Format attributes
    ## For each list entry
    attr_names <- c()
    for (i in 1:length(x)) {
        v <- x[[i]]
        n <- length(v)
        v_values <- character(length = n)
        v_names <- character(length = n)
        # For each vector item
        for (j in 1:length(v)) {
            vj <- v[[j]]
            ss <- str_split(vj,'=')
            v_values[[j]] <- ss[[1]][[2]] # Righthand side becomes value
            v_names[[j]] <- ss[[1]][[1]] # Lefthand side becomes name
        }
        v <- v_values
        names(v) <- v_names
    
        # Store unique entry names
        ind <- which(!v_names %in% attr_names)
        attr_names <- c(attr_names, v_names[ind])
    
        # Return formatted vector
        x[[i]] <- v
    }

    # Check for duplicated column names
    if (any(attr_names %in% names(object))) {
        msg <- 'Conflicting attribute names. Appending attribute_ to each new column'
        warning(msg)
        stop('Not yet implemented.')
    }

    # Return attributes to object
    ## For each attribute
    for (i in attr_names) {
        key <- paste0(attribute_key,i)
        object[[key]] <- NA
        # For each row
        for (j in 1:length(x)) {
            if (i %in% names(x[[j]])) {
                object[j,key] <- x[[j]][[i]]
            }
        }
    }

    return(object)
}

#' Read GFF3 file
#'
#' Read file formatted as GFF3 (https://gmod.org/wiki/GFF3#GFF3_Annotation_Section)
#'
#' @param file Path to file
#' @param keep_fasta_sequence_as_attributes Boolean value to indicate whether to keep
#' appended FASTA sequences as attributes to the returned data.frame
#'
#' @returns data.frame
#'
#' @export
read_gff3 <- function(file=NULL, keep_fasta_sequences_as_attributes=FALSE) {

    stopifnot(
        !is.null(file),
        file.exists(file)
    )

    # Variables
    gff3_column_names <- c('seqid','source','type','start','end','score','strand','phase','attributes')

    # Read flat file
    flat <- readLines(file)

    ## Check for version
    version <- flat[[1]]
    if (version == '##gff-version 3') {
        message('Reading gff-version 3.')
    } else {
        msg <- paste0('Unknown header: ', print(version),'. Aborting.')
        stop(msg)
    }
    
    # Detect FASTA sequences
    fasta <- stringr::str_detect(flat, '^##FASTA')
    if (any(fasta)) {
        if (keep_fasta_sequences_as_attributes) {
            msg <- 'FASTA sequences present. Will be returned as attributes.'
            warning(msg)
        } else {
            msg <- 'FASTA sequences present. Will be removed.'
            warning(msg)
        }
        fa_start <- which(fasta)
        gff_start <- 1
        gff_stop <- fa_start-1
        flat <- flat[gff_start:gff_stop]
    }

    # Remove sequence regions
    seq_region <- stringr::str_which(flat, '^##sequence-region')
    flat <- flat[-seq_region]
    
    # Extract and print header
    header_region <- stringr::str_which(flat, '^#')
    header <- flat[header_region]
    header <- paste(header, collapse='\n')
    cat('\n', header, '\n\n')
    
    # Create object
    object <- read.table(text=flat, header = FALSE, sep = '\t', comment.char = '#', col.names = gff3_column_names)
    if (any(fasta) & keep_fasta_sequences_as_attributes) {
        attr(object, 'fasta') <- Biostrings::readDNAStringSet(file, seek.first.rec = TRUE)
    }

    # Extract attributes
    object <- extract_gff3_attributes(object)

    # View
    str(object, max.level = 1)

    return(object)
}