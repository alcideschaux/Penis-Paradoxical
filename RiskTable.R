risk.table <- function(x, fu, outcome, by = 50, ...) {
  outcome <- as.numeric(outcome)
  survival.obj <- survival::Surv(fu, outcome)
  survival.x <- survival::survfit(survival.obj ~ x)
  # Determining which fu length by levels of x has the minimum value
  # This minimum value would be the maximum value of the sequence of time vector
  # This is to avoid reseting the vector of n.risk
  max.fu <- numeric()
  max.fu.split <- split(fu, x)
  for (i in 1:nlevels(x)) max.fu[i] <- max(max.fu.split[[i]])
  survival.time <- seq(0, min(max.fu), by)
  # Begining of the calculations for the risk table
  time.length <- length(survival.time)
  survfit.summary <- summary(survival.x, time = survival.time)
  n.risk <- survfit.summary$n.risk
  # This is to split the n.risk vector in lists taking into account the length of time vector
  n.risk.split <- split(n.risk, ceiling(seq_along(n.risk)/time.length))
  # Here we create the risk table with the splitted values of n.risk
  n.risk.table <- data.frame()
  n.risk.table <- do.call(rbind, c(n.risk.split, list(n.risk.table)))
  # Adding rownames and colnames
  rownames(n.risk.table) <- levels(x)
  colnames(n.risk.table) <- survival.time
  # Printing the final table
  kable(n.risk.table, align = c("c"), caption = "Individuals at risk")
}