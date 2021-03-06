# DATASET #
# Loading the full dataset with 333 patients
# The full dataset is available at http://files.figshare.com/1868801/PenisSCC_333.csv
        Data_Full <- read.csv("PenisSCC_333.csv")
# Excluding cases lost at follow-up
        Data <- subset(Data_Full, Outcome != "Lost at follow-up")

# RECODING NEW VARIABLES #
# Creating a new variable for cancer-related death
        Data$DOD <- ifelse(Data$Outcome == "Died of cancer", c("Yes"), c("No"))
        Data$DOD <- factor(Data$DOD)
# Creating a new variable for the final nodal status. Positive cases where those with:
        # Nodal metastasis in lymphadenectomy
                Data$Final_Nodal <- ifelse(Data$Mets == "Yes", c("Positive"), c("Negative"))
        # Local relapse during follow-up
                Data$Final_Nodal[Data$Local == "Yes"] <- "Positive"
        # Unfavorable outcome, including alive with disease and death by cancer
                Data$Final_Nodal[Data$Outcome == "Alive with disease"] <- "Positive"
                Data$Final_Nodal[Data$Outcome == "Died of cancer"] <- "Positive"
                Data$Final_Nodal <- factor(Data$Final_Nodal)
# Creating a new variable for anatomical location
Data$Anatomical[Data$Glans == "Yes" & Data$Sulcus == "No" & Data$Foreskin == "No"] <- "Glans alone"
Data$Anatomical[Data$Glans == "Yes" & Data$Sulcus == "Yes" & Data$Foreskin == "No"] <- "Glans + Coronal sulcus"
Data$Anatomical[Data$Glans == "Yes" & Data$Sulcus == "Yes" & Data$Foreskin == "Yes"] <- "Glans + Coronal sulcus + Foreskin"
Data$Anatomical <- factor(Data$Anatomical, levels = c("Glans alone", "Glans + Coronal sulcus", "Glans + Coronal sulcus + Foreskin"))
        
# PARADOXICAL TUMORS #
## Superficial High-Grade
Data$Paradoxical[Data$Grade == "Grade 3" & Data$Level == "Lamina propria"] <- "Superficial High-Grade"
Data$Paradoxical[Data$Grade == "Grade 3" & Data$Level == "Corpus spongiosum" & Data$Thickness <= 5] <- "Superficial High-Grade"
## Deep Low-Grade
Data$Paradoxical[Data$Grade == "Grade 1" & Data$Level == "Corpus cavernosum"] <- "Deep Low-Grade"
Data$Paradoxical[Data$Grade == "Grade 1" & Data$Level == "Corpus spongiosum" & Data$Thickness >= 10] <- "Deep Low-Grade"
# Converting to Factor
Data$Paradoxical <- factor(Data$Paradoxical, levels = c("Superficial High-Grade", "Deep Low-Grade"))
# Excluding missing cases
Data <- Data[complete.cases(Data$Paradoxical), ]

# Dropping unused levels
Data <- droplevels(Data)

# Releveling variables
Data$Subtype <- factor(Data$Subtype, levels = c("Usual", "Verrucous", "Papillary", "Warty", "Mixed"))

# RESULTS #
# Function for univariate tables
        # Table sould be table(var), x refers to var level
        T1 <- function(Table, x){
                Count <- Table[x]
                Percentage <- round(100*prop.table(Table))
                paste(Count, " (", Percentage[x], "\\%)", sep = "")
        }
# Function for bivariate tables
        # Table should be table(var_x, var_y), x refers to var_x level, y refers to var_y level
        T2 <- function(Table, x, y){
                Percentage <- round(100*(prop.table(Table, 1)))
                paste(Table[x, y], "/", sum(Table[x, ]), " (", Percentage[x, y], "\\%", ")", sep = "")
        }
# Defining the survival.plot function for plotting survival curves
library(survival)
survival.plot <- function(x, fu, outcome, title, position = "topright", logrank = "bottomleft", ...){
        outcome <- as.numeric(outcome)
        survival.obj <- Surv(fu, outcome)
        survival.lr <- survdiff(survival.obj ~ x)
        survival.p <- pchisq(survival.lr$chisq, df = 1, lower = FALSE)
        survival.x <- survfit(survival.obj ~ x)
        plot(survival.x, main = title,
                col =c(1,2,4), mark = c(2,0,5), lty = c(2,1,3), ...)
        legend(x = position, legend = levels(x), pch = c(2,0,5), lty = c(2,1,3),
                col = c(1,2,4), bty = "n")
        legend(x = logrank, bty = "n", 
                paste("P value (log-rank test) =", format(survival.p, digits = 2, width = 6)))
}
survival.p <- function(x, fu, outcome){
        outcome <- as.numeric(outcome)
        survival.obj <- Surv(fu, outcome)
        survival.lr <- survdiff(survival.obj ~ x)
        survival.p <- pchisq(survival.lr$chisq, df = 1, lower = FALSE)
        format(survival.p, digits = 2)
}
# Tables of clinicopathological and outcome features
## Patients' age
T_Age <- with(Data, rbind("Median" = tapply(Age, Paradoxical, FUN = median),
                          "IQR" = tapply(Age, Paradoxical, FUN = IQR)))
P_Age <- format(with(Data, wilcox.test(Age ~ Paradoxical)$p.value), digits = 2)
## Tumor size
T_Size <- with(Data[complete.cases(Data$Size), ],
               rbind("Median" = tapply(Size, Paradoxical, FUN = median),
                     "IQR" = tapply(Size, Paradoxical, FUN = IQR)))
P_Size <- format(with(Data, wilcox.test(Size ~ Paradoxical)$p.value), digits = 2)
## Anatomical location
T_Anatomical <- with(Data, table(Anatomical, Paradoxical))
P_Anatomical <- format(fisher.test(T_Anatomical)$p.value, digits = 2)
## Histologic subtype
T_Subtype <- with(Data, table(Subtype, Paradoxical))
P_Subtype <- format(fisher.test(T_Subtype)$p.value, digits = 2)
## Urethral invasion
T_Urethra <- with(Data, table(Urethra, Paradoxical))
P_Urethra <- format(fisher.test(T_Urethra)$p.value, digits = 2)
## Perineural invasion
T_Perineural <- with(Data, table(Perineural, Paradoxical))
P_Perineural <- format(fisher.test(T_Perineural)$p.value, digits = 2)
## Vascular invasion
T_Vascular <- with(Data, table(Vascular, Paradoxical))
P_Vascular <- format(fisher.test(T_Vascular)$p.value, digits = 2)
## Inguinal lymph node metastasis
T_Mets <- with(Data, table(Mets, Paradoxical))
P_Mets <- format(fisher.test(T_Mets)$p.value, digits = 2)
## Tumor relapse
T_Relapse <- with(Data, table(Relapse, Paradoxical))
P_Relapse <- format(fisher.test(T_Relapse)$p.value, digits = 2)
## Final nodal status
T_FN <- with(Data, table(Final_Nodal, Paradoxical))
P_FN <- format(fisher.test(T_FN)$p.value, digits = 2)
## DOD
T_DOD <- with(Data, table(DOD, Paradoxical))
P_DOD <- format(fisher.test(T_DOD)$p.value, digits = 2)

# Logistic regression analysis
Paradoxical_Inv <- factor(Data$Paradoxical, levels = c("Deep Low-Grade", "Superficial High-Grade"))
## Inguinal lymph node metastasis
GLM_Mets <- glm(Mets ~ Paradoxical_Inv, data = Data, family = binomial)
GLM_Mets_OR <- format(exp(coef(GLM_Mets))[2], digits = 2)
GLM_Mets_CI <- format(exp(confint(GLM_Mets))[2,], digits = 2)
GLM_Mets_P <- format(summary(GLM_Mets)$coef[2,4], digits = 2)
## Tumor relapse
GLM_Relapse <- glm(Relapse ~ Paradoxical_Inv, data = Data, family = binomial)
GLM_Relapse_OR <- format(exp(coef(GLM_Relapse))[2], digits = 2)
GLM_Relapse_CI <- format(exp(confint(GLM_Relapse))[2,], digits = 1)
GLM_Relapse_P <- format(summary(GLM_Relapse)$coef[2,4], digits = 2)
## Final nodal status
GLM_FN <- glm(Final_Nodal ~ Paradoxical_Inv, data = Data, family = binomial)
GLM_FN_OR <- format(exp(coef(GLM_FN))[2], digits = 2)
GLM_FN_CI <- format(exp(confint(GLM_FN))[2,], digits = 2)
GLM_FN_P <- format(summary(GLM_FN)$coef[2,4], digits = 2)
## DOD
GLM_DOD <- glm(DOD ~ Paradoxical_Inv, data = Data, family = binomial)
GLM_DOD_OR <- format(exp(coef(GLM_DOD))[2], digits = 2)
GLM_DOD_CI <- format(exp(confint(GLM_DOD))[2,], digits = 2)
GLM_DOD_P <- format(summary(GLM_DOD)$coef[2,4], digits = 2)

# Cox regression analysis
## Inguinal lymph node metastasis
Response <- with(Data, Surv(FollowUp, as.numeric(Mets)))
COX_Mets <- coxph(Response ~ Paradoxical_Inv)
COX_Mets_HR <- format(summary(COX_Mets)$conf.int[1], digits = 2, nsmall = 2)
COX_Mets_CI <- format(summary(COX_Mets)$conf.int[3:4], digits = 2, nsmall = 2)
COX_Mets_P <- format(summary(COX_Mets)$logtest[3], digits = 2, nsmall = 2)
## Tumor relapse
Response <- with(Data, Surv(FollowUp, as.numeric(Relapse)))
COX_Relapse <- coxph(Response ~ Paradoxical_Inv)
COX_Relapse_HR <- format(summary(COX_Relapse)$conf.int[1], digits = 2, nsmall = 2)
COX_Relapse_CI <- format(summary(COX_Relapse)$conf.int[3:4], digits = 2, nsmall = 2)
COX_Relapse_P <- format(summary(COX_Relapse)$logtest[3], digits = 2, nsmall = 2)
## Final nodal status
Response <- with(Data, Surv(FollowUp, as.numeric(Final_Nodal)))
COX_FN <- coxph(Response ~ Paradoxical_Inv)
COX_FN_HR <- format(summary(COX_FN)$conf.int[1], digits = 2, nsmall = 2)
COX_FN_CI <- format(summary(COX_FN)$conf.int[3:4], digits = 2, nsmall = 2)
COX_FN_P <- format(summary(COX_FN)$logtest[3], digits = 2, nsmall = 2)
## DOD
Response <- with(Data, Surv(FollowUp, as.numeric(DOD)))
COX_DOD <- coxph(Response ~ Paradoxical_Inv)
COX_DOD_HR <- format(summary(COX_DOD)$conf.int[1], digits = 2, nsmall = 2)
COX_DOD_CI <- format(summary(COX_DOD)$conf.int[3:4], digits = 2, nsmall = 2)
COX_DOD_P <- format(summary(COX_DOD)$logtest[3], digits = 2, nsmall = 2)
