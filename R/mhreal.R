#' Print function for mhreal
#'
#' Print the summary of the realization of the Haweks model.
#'
#' @param res S3-object of mhreal
#' @param n number of rows to diplay
print.mhreal <- function(res, n=20, ...){
  options(digits=4)
  cat("------------------------------------------\n")
  cat("Simulation result of marked Hawkes model.\n")
  print(res$mhspec)

  cat("Realized path (with right continuous representation):\n")
  mtrx <- as.matrix(res)
  dimens <- length(res$mhspec@MU)
  name_N  <- paste0("N", 1:dimens)
  name_lambda  <- paste0("lambda", 1:dimens)
  name_lambda_component <- colnames(res$lambda_component)

  len <- min(n, length(mtrx[,"arrival"]))

  print(mtrx[1:len, c("arrival", name_N, name_lambda, name_lambda_component)])
  if ( length(mtrx[,"arrival"]) > len){

    remaning <- length(mtrx[,"arrival"]) - len

    cat("... with ")
    cat(remaning)
    cat(" more rows \n")
  }

  cat("------------------------------------------\n")
  options(digits=7)
}

#' Matrix represetation of mhreal
#'
#' The realization of Hawkes model is represented by matrix like ouput.
#'
#' @param res S3-object of mhreal
as.matrix.mhreal <- function(res){

  mtrx <- numeric()
  for (i in 2:length(res)){
    mtrx <- cbind(mtrx, res[[i]])
    if(is.vector(res[[i]])){
      colnames(mtrx)[i-1] <- names(res)[i]
    }
  }
  mtrx
}

#' Dataframe represetation of mhreal
#'
#' The realization of Hawkes model is represented by dataframe like ouput.
#'
#' @param res S3-object of mhreal
as.data.frame.mhreal <- function(res){
  as.data.frame(as.matrix(res))
}

#' Summary function fo mhreal
#'
#' This function presents the summary of the Hawkes realization.
#'
#' @param res S3-object of mhreal
#' @param n number of rows to diplay
summary.mhreal <- function(res, n=20){

  options(digits=5)
  cat("------------------------------------------\n")
  cat("Simulation result of marked Hawkes model.\n")
  cat("Realized path (with right continuous representation):\n")
  mtrx <- as.matrix(res)
  dimens <- length(res$mhspec@MU)
  name_N  <- paste0("N", 1:dimens)
  name_lambda  <- paste0("lambda", 1:dimens)

  len <- min(n, length(mtrx[,"arrival"]))

  print(mtrx[1:len, c("arrival", name_N, name_lambda)])
  if ( length(mtrx[,"arrival"]) > len){

    remaning <- length(mtrx[,"arrival"]) - len

    cat("... with ")
    cat(remaning)
    cat(" more rows \n")
  }

  cat("------------------------------------------\n")
  options(digits=7)
}

#' Get left continuous version of lambda process
#'
#' The realized version of the lambda process in \code{mhreal} is right continuous version.
#' If the left continuous version is needed, this function is applied.
#'
#' @param res \code{mhreal} an S3 class contains the realized lambda processes.
#' @return The left continuous version of lambda components as a matrix.
#'
#' @examples
#' # Define the model.
#' MU1 <- 0.3; ALPHA1 <- 1.5; BETA1 <- 2
#' mhspec1 <- new("mhspec", MU=MU1, ALPHA=ALPHA1, BETA=BETA1)
#' # Simulate with mhsim funciton.
#' res1 <- mhsim(mhspec1,  n=100)
#' get_lc_lambda(res1)
#'
#' @export
get_lc_lambda <- function(res){

  dimens <- length(res$mhspec@MU)
  lc_lambda_component <- res$lambda_component

  for (i in 2:nrow(lc_lambda_component)) {

    if (dimens == 1) {
      impact <- res$mhspec@ALPHA * ( 1 + (res$mark[i] - 1 ) * res$mhspec@ETA )
      print(impact)
      lc_lambda_component[i] <- lc_lambda_component[i] - impact

    } else {

      col_indx <- seq(res$mark_type[i], dimens^2, dimens)
      lc_lambda_component[i, col_indx] <- lc_lambda_component[i, col_indx] -
        res$mhspec@ALPHA[, res$mark_type[i]] * ( 1 + (res$mark[i] - 1 ) * res$mhspec@ETA[, res$mark_type[i]])

    }

  }


  lc_lambda_component
}

#' Plot function for mhreal
#'
#'
#' @param x a mhreal object
#' @param
#'
#' @export
plot.mhreal <- function(x, y, ...){

  res <- x
  dimens <- ncol(res$N)
  graphics::par(mfrow=c(dimens, 1))

  n <- length(res$arrival)

  for (i in 1:dimens) {
    graphics::plot(res$arrival[1:n], res$N[ ,i][1:n], 's', xlab='t', ylab=colnames(res$N)[i])
    #points(res$arrival[1:n], res$N[ ,i][1:n])
  }

}

#' Get a lambda process with more dense time step
#'
#' Since the intenisty process is exponencially decaying, to fully describe the intensity processs,
#' we need more dense time line.
#' This function gives a lambda process with more dense time line.
#'
#' @param arrival a vector of arrival times.
#' @param lambda a vector of lambda processs. It should be a right continuous version.
#' @param beta a decaying parameter lambda.
#' @param dt a small step size on time horizon.
#'
#'
#' @examples
#' MU1 <- 0.3; ALPHA1 <- 1.5; BETA1 <- 2
#' mhspec1 <- new("mhspec", MU=MU1, ALPHA=ALPHA1, BETA=BETA1)
#' # Simulate with mhsim funciton.
#' res1 <- mhsim(mhspec1,  n=100)
#' dl <- dense_lambda(res1$arrival, res1$lambda, BETA1)
#'
#' @export
dense_lambda <- function(arrival, lambda, beta, dt = NULL, ...){
  maxT <- utils::tail(arrival, n=1)

  if (is.null(dt)){
    inter_arrival <- arrival[-1] - arrival[-length(arrival)]
    dt <- mean(inter_arrival)/100
  }

  time_vector <- seq(0, maxT, dt)

  lambda_vector <- numeric(length=length(time_vector))

  lambda_vector[1] <- lambda[1]
  j <- 2
  for (i in 2:length(time_vector)){
    next_arrival <- arrival[j]
    next_lambda <- lambda[j]
    if (time_vector[i] <  next_arrival){
      lambda_vector[i] <- lambda_vector[i-1]*exp(-beta*dt)
    } else{
      lambda_vector[i] <- next_lambda*exp(-beta * (time_vector[i] - next_arrival))
      j <- j + 1
    }
  }

  output <- cbind(time_vector, lambda_vector)
  colnames(output) <- c("arrival", "lambda")

  output
}

#' Plot exponentially decaying lambda process
#'
#' This plot method describes the exponentially decaying lambda (intensity) process.
#'
#'
#' @param arrival a vector of arrival times.
#' @param lambda a vector of lambda processs.
#' @param beta a decaying parameter lambda.
#' @param dt a small step size on time horizon.
#' @param xlab x-lable
#' @param ylab y-lable
#'
#' @examples
#' MU1 <- 0.3; ALPHA1 <- 1.5; BETA1 <- 2
#' mhspec1 <- new("mhspec", MU=MU1, ALPHA=ALPHA1, BETA=BETA1)
#' # Simulate with mhsim funciton.
#' res1 <- mhsim(mhspec1,  n=100)
#' plot_lambda(res1$arrival, res1$lambda, BETA1)
#'
#' @export
plot_lambda <- function(arrival, lambda, beta, dt = NULL, xlab='t', ylab='lambda'){

  result <- dense_lambda(arrival, lambda, beta, dt)
  graphics::plot(result[, "arrival"], result[, "lambda"], 'l', xlab = xlab, ylab = ylab)

}

