#' @include utils.R
NULL
#> NULL


.jd2r_test <- function(jtest) {
    if (is.jnull(jtest)) {
        return(NULL)
    } else {
        desc <- .jcall(jtest, "S", "getDescription")
        val <- .jcall(jtest, "D", "getValue")
        pval <- .jcall(jtest, "D", "getPvalue")
        return(statisticaltest(val, pval, desc))
    }
}


.jd2r_regression_item <- function(s) {
    desc <- .jcall(s, "S", "getDescription")
    val <- .jcall(s, "D", "getCoefficient")
    stderr <- .jcall(s, "D", "getStdError")
    pval <- .jcall(s, "D", "getPvalue")
    res <- matrix(c(val, stderr, val / stderr, pval), nrow = 1)
    colnames(res) <- c("Estimate", "Std. Error", "T-stat", "Pr(>|t|)")
    rownames(res) <- desc
    res
}
#' @export
#' @rdname jd3_utilities
.r2jd_tsdata <- function(s) {
    if (is.null(s)) {
        return(NULL)
    }
    freq <- frequency(s)
    start <- start(s)
    .jcall(
        "jdplus/toolkit/base/r/timeseries/TsUtility", "Ljdplus/toolkit/base/api/timeseries/TsData;", "of",
        as.integer(freq), as.integer(start[1]), as.integer(start[2]), as.double(s)
    )
}

#' @export
#' @rdname jd3_utilities
.r2jd_tsdomain <- function(period, startYear, startPeriod, length) {
    .jcall(
        "jdplus/toolkit/base/r/timeseries/TsUtility", "Ljdplus/toolkit/base/api/timeseries/TsDomain;", "of",
        as.integer(period), as.integer(startYear), as.integer(startPeriod), as.integer(length)
    )
}

#' @export
#' @rdname jd3_utilities
.jd2r_tsdata <- function(s) {
    if (is.jnull(s)) {
        return(NULL)
    }
    jx <- .jcall(s, "Ljdplus/toolkit/base/api/data/DoubleSeq;", "getValues")
    x <- .jcall(jx, "[D", "toArray")
    if (is.null(x)) {
        return(NULL)
    }
    if (length(x) == 0) {
        return(NULL)
    }
    pstart <- .jcall("jdplus/toolkit/base/r/timeseries/TsUtility", "[I", "startPeriod", s)
    ts(x, start = pstart[2:3], frequency = pstart[1])
}

#' @export
#' @rdname jd3_utilities
.jd2r_mts <- function(s) {
    if (is.jnull(s)) {
        return(NULL)
    }
    jx <- .jcall(s, "Ljdplus/toolkit/base/api/math/matrices/Matrix;", "toMatrix")
    x <- .jd2r_matrix(jx)
    if (is.jnull(x)) {
        return(NULL)
    }
    pstart <- .jcall("jdplus/toolkit/base/r/timeseries/TsUtility", "[I", "startPeriod", s)
    ts(x, start = pstart[2:3], frequency = pstart[1])
}

.extract_jts <- function(collection, index) {
    js <- .jcall(collection, "Ljdplus/toolkit/base/api/timeseries/Ts;", "get", as.integer(index - 1))
    return(js)
}

#' @export
#' @rdname jd3_utilities
.jd2r_lts <- function(s) {
    if (is.jnull(s)) {
        return(NULL)
    }
    size <- .jcall(s, "I", "length")
    if (size == 0) {
        return(NULL)
    }
    all <- lapply(
        X = 1:size,
        FUN = function(idx) {
            return(.jd2r_ts(.extract_jts(s, idx)))
        }
    )
    return(all)
}

#' @export
#' @rdname jd3_utilities
.jd2r_matrix <- function(s) {
    if (is.jnull(s)) {
        return(NULL)
    }
    nr <- .jcall(s, "I", "getRowsCount")
    nc <- .jcall(s, "I", "getColumnsCount")
    d <- .jcall(s, "[D", "toArray")
    return(array(d, dim = c(nr, nc)))
}

#' @export
#' @rdname jd3_utilities
.r2jd_matrix <- function(s) {
    if (is.null(s)) {
        return(.jnull("jdplus/toolkit/base/api/math/matrices/Matrix"))
    }
    if (!is.matrix(s)) {
        s <- matrix(s, nrow = length(s), ncol = 1)
    }
    sdim <- dim(s)
    return(.jcall("jdplus/toolkit/base/api/math/matrices/Matrix", "Ljdplus/toolkit/base/api/math/matrices/Matrix;", "of", .jarray(as.double(s)), as.integer(sdim[1]), as.integer(sdim[2])))
}

.j2r_ldt <- function(ldt) {
    if (is.jnull(ldt)) {
        return(NULL)
    }
    dt <- .jcall(ldt, "Ljava/time/LocalDate;", "toLocalDate")
    return(as.Date(.jcall(dt, "S", "toString")))
}

.j2r_dt <- function(dt) {
    if (is.jnull(dt)) {
        return(NULL)
    }
    return(as.Date(.jcall(dt, "S", "toString")))
}

.r2j_dt <- function(dt) {
    jdt <- .jnew("java/lang/String", as.character(dt))
    return(.jcall("java/time/LocalDate", "Ljava/time/LocalDate;", "parse", .jcast(jdt, "java/lang/CharSequence")))
}

.r2j_ldt <- function(dt) {
    jdt <- .r2j_dt(dt)
    return(.jcall(jdt, "Ljava/time/LocalDateTime;", "atStartOfDay"))
}

.jd2r_parameters <- function(jparams) {
    if (is.jnull(jparams)) {
        return(NULL)
    }
    param <- .jcastToArray(jparams)
    len <- length(param)
    if (len == 0) {
        return(NULL)
    }
    param_name <- deparse(substitute(jparams))
    Type <- sapply(param, function(x) .jcall(.jcall(x, "Ljdplus/toolkit/base/api/data/ParameterType;", "getType"), "S", "name"))
    Value <- sapply(param, function(x) .jcall(x, "D", "getValue"))
    data_param <- data.frame(Type = Type, Value = Value)
    rownames(data_param) <- sprintf(
        "%s(%i)",
        param_name,
        1:len
    )
    data_param
}

#' @export
#' @rdname jd3_utilities
.jdomain <- function(period, start, end) {
    if (period == 0) {
        return(.jnull("jdplus/toolkit/base/api/timeseries/TsDomain"))
    }
    if (is.null(start)) {
        start <- c(1900, 1)
    }
    if (is.null(end)) {
        end <- c(2100, 1)
    }
    n <- period * (end[1] - start[1]) + end[2] - start[2]
    jdom <- .jcall(
        "jdplus/toolkit/base/r/timeseries/TsUtility", "Ljdplus/toolkit/base/api/timeseries/TsDomain;", "of",
        as.integer(period), as.integer(start[1]), as.integer(start[2]), as.integer(n)
    )
    return(jdom)
}
