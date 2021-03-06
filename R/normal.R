
#'Confident effect sizes from from normal or t distributions
#'
#'A general purpose confident effect size function for where a normal or t
#'distribution of errors can be assumed. Calculates confident effect sizes based
#'on an estimated effect and standard deviation (normal distribution), or mean
#'and scale (t distribution).
#'
#'@param effect A vector of estimated effects.
#'
#'@param se A single number or vector of standard errors (or if t distribution,
#'  scales).
#'
#'@param df A single number or vector of degrees of freedom, for t-distribution.
#'  Inf for normal distribution.
#'
#'@param signed If TRUE effects are signed, use TREAT test. If FALSE effects are
#'  all positive, use one sided t-test.
#'
#'@param fdr False Discovery Rate to control for.
#'
#'@param step Granularity of effect sizes to test.
#'
#'@param full Include some further statistics used to calculate confects in the
#'  output, and also include FDR-adjusted p-values that effect size is non-zero
#'  (note that this is against the spirit of the topconfects approach).
#'
#'@return
#'
#'See \code{\link{nest_confects}} for details of how to interpret the result.
#'
#' @examples
#'
#' # Find largest positive or negative z-scores in a collection,
#' # and place confidence bounds on them that maintain FDR 0.05.
#' z <- c(1,-2,3,-4,5)
#' normal_confects(z, se=1, fdr=0.05, full=TRUE)
#'
#'@export
normal_confects <- function(
        effect, se, df=Inf, signed=TRUE,
        fdr=0.05, step=0.001, full=FALSE) {
    n <- max(length(effect), length(se), length(df))
    effect <- broadcast(effect, n)
    se <- broadcast(se, n)
    df <- broadcast(df, n)

    if (signed) {
        abs_effect <- abs(effect)

        pfunc <- function(indices, mag) {
            abs_effect_i <- abs_effect[indices]
            se_i <- se[indices]
            df_i <- df[indices]

            tstat_right <- (abs_effect_i-mag)/se_i
            tstat_left <- (abs_effect_i+mag)/se_i

            pt(tstat_right, df=df_i, lower.tail=FALSE) +
                pt(tstat_left,df=df_i, lower.tail=FALSE)
        }
    } else {
        assert_that(all(effect >= 0.0))

        pfunc <- function(indices, mag) {
            tstat <- (effect[indices]-mag)/se[indices]
            pt(tstat, df=df[indices], lower.tail=FALSE)
        }
    }

    confects <- nest_confects(n, pfunc, fdr=fdr, step=step, full=full)
    ranked_effect <- effect[confects$table$index]
    confects$table$confect <- sign(ranked_effect) * confects$table$confect
    confects$table$effect <- ranked_effect

    if (full) {
        fdr_zero <- confects$table$fdr_zero
        confects$table$fdr_zero <- NULL
        confects$table$se <- se[confects$table$index]
        confects$table$df <- df[confects$table$index]
        confects$table$fdr_zero <- fdr_zero
    }

    if (!signed)
        confects$limits <- c(0,NA)

    confects
}





