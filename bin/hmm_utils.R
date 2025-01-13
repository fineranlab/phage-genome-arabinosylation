################################################################################

                    #   #     #####     #     #          #####
                    #   #       #       #     #         #
                    #   #       #       #     #         #####
                    #   #       #       #     #             # 
                     ###        #       #     ####     #####

################################################################################

#' Read summary table from HMMsearch output
#' 
#' Read plain text formatted output of HMMER 3.4 hmmsearch
#' Detect query scores in output and convert them into a data.frame
#' 
#' @returns data.frame
#' 
#' @export
read_HMMsearch <- function(file=NULL) {

    stopifnot(
        !is.null(file)
    )

    # Read file -----
    result <- readLines(file)

    # Subset result -----
    
    ## Top
    tbl_top <- which(str_detect(result, 'Query:')) +2
    ## Bottom
    tbl_bottom <- which(result == "")
    tbl_bottom <- tbl_bottom[which(tbl_bottom > tbl_top)[1]] -1
    ## Subset
    index <- seq(tbl_top, tbl_bottom, by = 1)
    table <- result[index]
    
    # Format table -----
    
    ## Trim whitespace
    table <- str_trim(table) # from start/end
    table <- str_squish(table) # from middle (multiple > one)
    
    ## Split by whitespace
    table <- str_split(table,' ',n=10)

    ## Remove first line
    x <- table[1] # !!! NOT USED, possible use case in: Adjust header names !!!
    table <- table[-1]

    ## Remove '---' aesthetics
    table <- table[-2]

    ## Convert to data.frame
    table <- do.call(rbind.data.frame, table)

    ## Make first line to header
    names(table) <- table[1, ]
    table <- table[-1, ]

    ## Adjust header names
    names(table) <- paste0(c(rep('full_sequence_',3), rep('best_domain_',3), rep('dom_',2), '',''), names(table))
    names(table) <- str_replace(names(table),'-','_')

    # Convert numeric values -----

    ## First 8 columns
    for (n in 1:8) {
        table[[n]] <- as.numeric(table[[n]])
    }

    return(table)
}

#' Clean phage annotations using HMM profiles
#'
#' @param
#' @param
#' @param
#'
#' @export
annotate_gene_by_hmm_profile <- function(object=NULL, gene=NULL, annotation='annotation', 
                                         search_db=NULL, e_value_treshold = 1e-20,
                                         dir=tempdir()
                                        ) {

    # Check input
    stopifnot(
        !is.null(object),
        !is.null(gene),
        annotation %in% names(object),
        !is.null(search_db)
    )

    # Create output directory
    if (endsWith(dir,'/')) {
        # Fine
    } else {
        dir <- paste0(dir,'/')
    }
    out_ann <- paste0(dir, 'annotation/')
    dir.create(out_ann)

    # Filter
    subset <- object[object[[annotation]] == gene,]
    
    # Set variables
    gene_no_whitespace <- str_remove(gene, " ")
    fn.faa <- paste0(out_ann,gene_no_whitespace,'.faa')
    fn.ali <- paste0(out_ann,gene_no_whitespace,'_aligned.fasta')
    fn.hmm <- paste0(out_ann,gene_no_whitespace,'_profile.hmm')
    fn.result <- paste0(out_ann,gene_no_whitespace,'_hmmsearch.result')

    # Export protein sequence
    aa <- subset$protein_seq
    names(aa) <- subset$Name
    aa <- AAStringSet(aa)
    writeXStringSet(aa, fn.faa)

    ## Run MSA
    msa_call <- paste0('muscle -align ',fn.faa,' -output ',fn.ali)
    system(msa_call, intern=TRUE)
    
    ## Build profile HMM
    hmmbuild <- paste0('hmmbuild ',fn.hmm,' ',fn.ali)
    system(hmmbuild, intern=TRUE)
    
    ## HMM search
    hmmsearch <- paste0('hmmsearch -o ',fn.result,' ',fn.hmm,' ',search_db)
    system(hmmsearch, intern=TRUE)
    
    ## Read output
    result <- read_HMMsearch(fn.result)

    ## Get significant results
    index <- which(result$full_sequence_E_value < e_value_treshold)
    
    ## Investigate hit distribution
    n_hits <- length(index)
    plot <- ggplot(result, aes(-log10(full_sequence_E_value))) +
      geom_histogram(bins = 100, col = 'black', fill = 'grey90') +
      scale_x_continuous(limits = c(0, NA)) +
      geom_vline(xintercept = -log10(1e-20), col = 'darkorange', size = 1) +
      theme_classic(20) +
      theme(
          panel.grid.major.y = element_line()
      ) +
      labs(y = 'Number of proteins', title = 'E value distribution of HMMsearch', subtitle = paste0('Gene "',gene,'" gave ',n_hits,' significant hits'))
    print(plot)
    
    ## Filter result
    result <- result[index, ]
    
    return(result)
}