## MODEL VARIABLES
##------------------------------------------------------------------------------

na <- user() # number of age categories
nh <- user() # number of biting heterogeneity categories
ft <- user() # proportion of cases treated

##------------------------------------------------------------------------------
##################
## HUMAN STATES ##
##################
##------------------------------------------------------------------------------

# Human states as specified in full transmission model
# http://journals.plos.org/plosmedicine/article?id=10.1371%2Fjournal.pmed.1000324
# http://www.nature.com/articles/ncomms4136

# fitted parameters for human compartments:
eta <- user() # death rate for exponential population distribution
age_rate[] <- user() # rate at which humans move through age categories
dim(age_rate) <- na
het_wt[] <- user() # weights of the different heterogeneous biting categories
dim(het_wt) <- nh
rA <- user() # rate of movement from A -> U
rT <- user() # rate of treatment working: T -> P
rD <- user() #  rate from D -> A
rU <- user() # rate of clearance of subpatent infection U -> S
rP <- user() # rate at which prophylaxis wears off P -> S

# S - SUSCEPTIBLE
init_S[,] <- user()
dim(init_S) <- c(na,nh)
initial(S[,]) <- init_S[i,j]
dim(S) <- c(na,nh)

deriv(S[1, 1:nh]) <- -FOI_eff[i,j]*S[i,j] + rP*P[i,j] + rU*U[i,j] +
  eta*H*het_wt[j] - (eta+age_rate[i])*S[i,j]
deriv(S[2:na, 1:nh]) <- -FOI_eff[i,j]*S[i,j] + rP*P[i,j] + rU*U[i,j] -
  (eta+age_rate[i])*S[i,j] + age_rate[i-1]*S[i-1,j]

# T- SUCCESSFULLY TREATED
init_T[,] <- user()
dim(init_T) <- c(na,nh)
initial(T[,]) <- init_T[i,j]
dim(T) <- c(na,nh)

deriv(T[1, 1:nh]) <- ft*clin_inc[i,j] - rT*T[i,j] -
  (eta+age_rate[i])*T[i,j]
deriv(T[2:na, 1:nh]) <- ft*clin_inc[i,j] - rT*T[i,j] -
  (eta+age_rate[i])*T[i,j] + age_rate[i-1]*T[i-1,j]

# D - CLEAR DISEASE
init_D[,] <- user()
dim(init_D) <- c(na,nh)
initial(D[,]) <- init_D[i,j]
dim(D) <- c(na,nh)

deriv(D[1, 1:nh]) <- (1-ft)*clin_inc[i,j] - rD*D[i,j] -
  (eta+age_rate[i])*D[i,j]
deriv(D[2:na, 1:nh]) <- (1-ft)*clin_inc[i,j] - rD*D[i,j] -
  (eta+age_rate[i])*D[i,j] + age_rate[i-1]*D[i-1,j]

# A - ASYMPTOMATIC DISEASE
init_A[,] <- user()
dim(init_A) <- c(na,nh)
initial(A[,]) <- init_A[i,j]
dim(A) <- c(na,nh)

deriv(A[1, 1:nh]) <- (1-phi[i,j])*FOI_eff[i,j]*Y[i,j] - FOI_eff[i,j]*A[i,j] +
  rD*D[i,j] - rA*A[i,j] - (eta+age_rate[i])*A[i,j]
deriv(A[2:na, 1:nh]) <- (1-phi[i,j])*FOI_eff[i,j]*Y[i,j] - FOI_eff[i,j]*A[i,j] +
  rD*D[i,j] - rA*A[i,j] - (eta+age_rate[i])*A[i,j] + age_rate[i-1]*A[i-1,j]

# U - SUBPATENT DISEASE
init_U[,] <- user()
dim(init_U) <- c(na,nh)
initial(U[,]) <- init_U[i,j]
dim(U) <- c(na,nh)

deriv(U[1, 1:nh]) <- rA*A[i,j] - FOI_eff[i,j]*U[i,j] - rU*U[i,j] -
  (eta+age_rate[i])*U[i,j]
deriv(U[2:na, 1:nh]) <- rA*A[i,j] - FOI_eff[i,j]*U[i,j] - rU*U[i,j] -
  (eta+age_rate[i])*U[i,j] + age_rate[i-1]*U[i-1,j]

# P - PROPHYLAXIS
init_P[,] <- user()
dim(init_P) <- c(na,nh)
initial(P[,]) <- init_P[i,j]
dim(P) <- c(na,nh)

deriv(P[1, 1:nh]) <- rT*T[i,j] - rP*P[i,j] - (eta+age_rate[i])*P[i,j]
deriv(P[2:na, 1:nh]) <- rT*T[i,j] - rP*P[i,j] - (eta+age_rate[i])*P[i,j] +
  age_rate[i-1]*P[i-1,j]

# The number of individuals able to acquire clinical malaria
dim(Y) <- c(na,nh)
Y[1:na, 1:nh] <- S[i,j]+A[i,j]+U[i,j]

# The number of new cases at this timestep
dim(clin_inc) <- c(na,nh)
clin_inc[1:na, 1:nh] <- phi[i,j]*FOI_eff[i,j]*Y[i,j]
output(clin_inc)<-clin_inc
output(phi)<-phi
# output(FOI)<-FOI
output(Y)<-Y
# Sum compartments over all age, heterogeneity and intervention categories
Sh <- sum(S[,])
Th <- sum(T[,])
Dh <- sum(D[,])
Ah <- sum(A[,])
Uh <- sum(U[,])
Ph <- sum(P[,])
H <- Sh + Th + Dh + Ah + Uh + Ph

##------------------------------------------------------------------------------
#####################
## IMMUNITY STATES ##
#####################
##------------------------------------------------------------------------------

# See supplementary materials S1 from http://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1000324#s6

# ICM - Maternally acquired immunity acquired by babies from mothers (assumed to be proportional to the immunity of a 15 to 30 year old woman)
# ICA - Immunity acquired due to exposure to previous infection, increases with age
# IC - Clinical immunity. Upon infection, immunity against clinical case. IC = ICA + ICM
# IB - Infection blocking immunity, chances of preventing infection upon receiving infectious bite
# ID - Detection immunity, when immunity suppresses parasite densities this makes it less likely that diagnostics will detect parasite infection

# fitted immunity parameters:
uCA <- user() # scale parameter (see Supplementary mats. 3.1.2)
dCA <- user() # decay for clinical immunity
dB <- user() # decay for infection blocking immunity
uB <- user() # scale param for IB immunity
dID <- user() # decay for detection immunity
uD <- user() # scale param for ID immunity
x_I[] <- user() # intermediate variable for calculating immunity functions
dim(x_I) <- na
age20l <- user(integer=TRUE) # lower index of age 20 age compartment
age20u <- user(integer=TRUE) # upper index of age 20 age compartment
age_20_factor <- user() # factor calculated in equilibrium solution
PM <- user() # immunity constant

# ICM - maternally acquired immunity
dim(init_ICM_pre) <- c(nh)
init_ICM_pre[1:nh] <- PM*(ICA[age20l,i] + age_20_factor*(ICA[age20u,i]-ICA[age20l,i]))
ICM_age[]<-user()
dim(ICM_age)<-na
dim(ICM) <- c(na,nh)
ICM[1:na, 1:nh]<-ICM_age[i]*init_ICM_pre[j]


# ICA - exposure driven immunity
init_ICA[,] <- user()
dim(init_ICA) <- c(na,nh)
initial(ICA[,]) <- init_ICA[i,j]
dim(ICA) <- c(na,nh)

deriv(ICA[1, 1:nh]) <- FOI_eff[i,j]/(FOI_eff[i,j] * uCA + 1) - 1/dCA*ICA[i,j] -ICA[i,j]/x_I[i]
deriv(ICA[2:na, 1:nh]) <- FOI_eff[i,j]/(FOI_eff[i,j] * uCA + 1) - 1/dCA*ICA[i,j] - (ICA[i,j]-ICA[i-1,j])/x_I[i]

# clinical immunity is a combination of maternal and exposure-driven immunity
dim(IC) <- c(na,nh)
IC[,] <- ICM[i,j] + ICA[i,j]

# phi - probability of clinical disease, dependent on clinical immunity
phi0 <- user()
phi1 <- user() # these parameters characterise the hill function
IC0 <- user() # for probability of clinical disease
kC <- user() # See supplementary materials 1.1.3
dim(phi) <- c(na,nh)
phi[1:na,1:nh] <- phi0*((1-phi1)/(1+(IC[i,j]/IC0)^kC) + phi1)
dim(phi0to59) <- c(age59,nh)
phi0to59[1:age59,] <- phi[i,j]*den[i]*het_wt[j]
output(phi_out) <- sum(phi0to59[,])
dim(IC_all) <- c(na,nh)
dim(IB_all) <- c(na,nh)
dim(ID_all) <- c(na,nh)
IC_all[,] <- IC[i,j]*den[i]*het_wt[j]
IB_all[,] <- IB[i,j]*den[i]*het_wt[j]
ID_all[,] <- ID[i,j]*den[i]*het_wt[j]
output(IC_out) <- sum(IC_all[,])
output(IB_out) <- sum(IB_all[,])
output(ID_out) <- sum(ID_all[,])

# IB - infection blocking immunity
init_IB[,] <- user()
dim(init_IB) <- c(na,nh)
initial(IB[,]) <- init_IB[i,j]
dim(IB) <- c(na,nh)

deriv(IB[1, 1:nh]) <- EIR[i,j]/(EIR[i,j]* uB + 1) - IB[i,j]/dB - IB[i,j]/x_I[i]
deriv(IB[2:na, 1:nh]) <- EIR[i,j]/(EIR[i,j]* uB + 1) - IB[i,j]/dB - (IB[i,j]-IB[i-1,j])/x_I[i]

# b - probability of disease from infectious bite, depends on infection blocking immunity
b0 <- user() # these parameters characterise the hill function for b
b1 <- user() # prob of infection from bite with zero immunity
kB <- user() #
IB0 <- user()
dim(b) <- c(na,nh)
b[1:na, 1:nh] <- b0 * ((1-b1)/(1+(IB[i,j]/IB0)^kB)+b1)
dim(b0to59) <- c(age59,nh)
b0to59[1:age59,] <- b[i,j]*den[i]*het_wt[j]
output(b_out) <- sum(b0to59[,])

# detection immunity
init_ID[,] <- user()
dim(init_ID) <- c(na,nh)
initial(ID[,]) <- init_ID[i,j]
dim(ID) <- c(na,nh)

deriv(ID[1, 1:nh]) <- FOI_eff[i,j]/(FOI_eff[i,j]*uD + 1) - ID[i,j]/dID - ID[i,j]/x_I[i]
deriv(ID[2:na, 1:nh]) <- FOI_eff[i,j]/(FOI_eff[i,j]*uD + 1) - ID[i,j]/dID - (ID[i,j]-ID[i-1,j])/x_I[i]

# p_det - probability of detection by microscopy, immunity decreases chances of
# infection because it pushes parasite density down
aD <- user()
fD0 <- user()
gammaD <- user()
d1 <- user()
ID0 <- user()
kD <- user()
dim(age) <- na
age[] <- user() # vector of age categories supplied by user

dim(fd) <- na
fd[1:(na-1)] <- 1-(1-fD0)/(1+((age[i]+age[i+1])/2/aD)^gammaD)
fd[na]<-1-(1-fD0)/(1+(age[i]/aD)^gammaD)
dim(p_det) <- c(na,nh)
p_det[,] <- d1 + (1-d1)/(1 + fd[i]*(ID[i,j]/ID0)^kD)
dim(p_det0to59) <- c(age59,nh)
p_det0to59[1:age59,] <- p_det[i,j]*den[i]*het_wt[j]
output(p_det_out) <- sum(p_det0to59[,])
# # Force of infection, depends on level of infection blocking immunity
# dim(FOI) <- c(na,nh)
# FOI[1:na, 1:nh] <- EIR[i,j] * (if(IB[i,j]==0) b0 else b[i,j])

# Force of infection, depends on level of infection blocking immunity
dim(FOI_lag) <- c(na,nh)
FOI_lag[1:na, 1:nh] <- EIR[i,j] * (if(IB[i,j]==0) b0 else b[i,j])

# Current FOI depends on humans that have been through the latent period
dE <- user() # latent period of human infection.
lag_rates <- user()

FOI_eq[,] <- user()
dim(FOI_eq) <- c(na,nh)
init_FOI[,,] <- FOI_eq[i,j]
dim(init_FOI) <- c(na,nh,lag_rates)
initial(FOI[,,]) <- init_FOI[i,j,k]
dim(FOI) <- c(na,nh,lag_rates)

deriv(FOI[,,1]) <- (lag_rates/dE)*FOI_lag[i,j] - (lag_rates/dE)*FOI[i,j,1]
deriv(FOI[,,2:lag_rates]) <- (lag_rates/dE)*FOI[i,j,k-1] - (lag_rates/dE)*FOI[i,j,k]

dim(FOI_eff) <- c(na,nh)
FOI_eff[,] <- FOI[i,j,lag_rates]
# EIR -rate at which each age/het/int group is bitten
# rate for age group * rate for biting category * FOI for age group * prop of
tau1 <- user() # duration of host-seeking behaviour
tau2 <- user() # duration of resting behaviour
Q0 <- user() # proportion of anthropophagy

av <- fv*Q0

DY<-user()
volatility<-user()
# init_EIR <- user()
# max_EIR <- user()
# EIR[,] <- exp(log_EIR) * rel_foi[j] * foi_age[i]
# output(EIR_out) <- exp(log_EIR)*DY
output(EIR_out) <- (av * Iv/omega)*DY

dim(EIR) <- c(na,nh)
EIR[,] <- rel_foi[j] * foi_age[i] * Iv*av0/omega


#EIR_td<-interpolate(EIR_times, EIR_valsd, "constant")
# EIR_times[]<-user()
# EIR_vals[]<-user()
#EIR_valsd[]<-EIR_vals[i]/DY
#dim(EIR_times)<-user()
# dim(EIR_vals)<-user()
#dim(EIR_valsd)<-length(EIR_vals)
dim(foi_age) <- na
foi_age[] <- user()
dim(rel_foi) <- nh
rel_foi[] <- user()

#output(Ivout) <- Iv

#output(omega) <- omega
##------------------------------------------------------------------------------
##########################
## SEASONALITY FUNCTION ##
##########################
##------------------------------------------------------------------------------

# Seasonality is added into the model using a Fourier series that was fit to rainfall at every admin 1 level
#pi <- user() # weird quirk, need to pass pi

# The parameters for the fourier series
#ssa0 <- user()
#ssa1 <- user()
#ssa2 <- user()
#ssa3 <- user()
#ssb1 <- user()
#ssb2 <- user()
#ssb3 <- user()
#theta_c <- user()
# Recreation of the rainfall function
#theta2 <- if(ssa0 == 0 && ssa1  == 0 && ssa2  == 0 && ssb1  == 0 && ssb2  == 0 && ssb3  == 0 && theta_c  == 0)
 # 1 else max((ssa0+ssa1*cos(2*pi*t/365)+ssa2*cos(2*2*pi*t/365)+ssa3*cos(3*2*pi*t/365)+ssb1*sin(2*pi*t/365)+ssb2*sin(2*2*pi*t/365)+ ssb3*sin(3*2*pi*t/365) ) /theta_c,0.001)
#theta2 <-1
# ##------------------------------------------------------------------------------
# #####################
# ## MOSQUITO STATES ##
# #####################
# ##------------------------------------------------------------------------------

# See supplementary materials S1 from http://journals.plos.org/plosmedicine/article?id=10.1371/journal.pmed.1000324#s6
# fitted entomological parameters:
mv0 <- user() # initial mosquito density
p10 <- user() # prob of surviving 1 feeding cycle
p2 <- user() #prob of surviving one resting cycle
fv <- 1/( tau1 + tau2 ) # mosquito feeding rate (zbar from intervention param.)
mu <- -fv*log(p10*p2) # mosquito death rate
omega <- user() #normalising constant for biting rates
# cA is the infectiousness to mosquitoes of humans in the asmyptomatic compartment broken down
# by age/het/int category, infectiousness depends on p_det which depends on detection immunity
cU <- user() # infectiousness U -> mosq
cD <- user() # infectiousness D -> mosq
cT <- user() # T -> mosq
av0 <- user()
gamma1 <- user() # fitted value of gamma1 characterises cA function
dim(cA) <- c(na,nh)
cA[,] <- cU + (cD-cU)*p_det[i,j]^gamma1
# Current hum->mos FOI depends on the number of individuals now producing gametocytes (12 day lag)
delayGam <- user() # Lag from parasites to infectious gametocytes
delayMos <- user() # Extrinsic incubation period.

# Number of mosquitoes that become infected at each time point
surv <- exp(-mu*delayMos)

# Force of infection from humans to mosquitoes
lag_ratesMos <- lag_rates

FOIv_eq <- user()
initial(FOIv[]) <- FOIv_eq*delayGam/lag_ratesMos
dim(FOIv) <- lag_ratesMos

FOIvijk[1:na, 1:nh] <- av0 * (cT*T[i,j] + cD*D[i,j] + cA[i,j]*A[i,j] + cU*U[i,j]) * rel_foi[j] *foi_age[i]/omega
dim(FOIvijk) <- c(na,nh)
lag_FOIv <- sum(FOIvijk)

deriv(FOIv[1]) <- lag_FOIv - (lag_ratesMos/delayGam)*FOIv[1]
deriv(FOIv[2:lag_ratesMos]) <- (lag_ratesMos/delayGam)*FOIv[i-1] -
  (lag_ratesMos/delayGam)*FOIv[i]

ince <- FOIv[lag_ratesMos] * lag_ratesMos/delayGam * Sv

initial(ince_delay[]) <- FOIv_eq*init_Sv*mv0*delayMos/lag_ratesMos
dim(ince_delay) <- lag_ratesMos

deriv(ince_delay[1]) <- ince - (lag_ratesMos/delayMos)*ince_delay[1]
deriv(ince_delay[2:lag_ratesMos]) <- (lag_ratesMos/delayMos)*ince_delay[i-1] -
  (lag_ratesMos/delayMos)*ince_delay[i]

incv <- ince_delay[lag_ratesMos]*lag_ratesMos/delayMos *surv

# feed in betaa values from a random walk
state_check <- user()
betaa_eq <- user()
initial(betaa_td) <- betaa_eq
max_param <- user()
betaa_max <- log(max_param)
betaa_update <- if(state_check==0) min(log(betaa_td)+rnorm(0,1)*volatility,betaa_max) else log(betaa_eq)

update(betaa_td) <- exp(betaa_update)
output(betaa_out) <- betaa_td

# Sv - Susceptible mosquitoes
# Ev - latently infected (exposed) mosquitoes. Number of compartments used to simulate delay in becoming infectious
# Iv - Infectious mosquitoes

# initial state values:
init_Sv <- user()
init_Ev <- user()
init_Iv <- user()
initial(Sv) <- init_Sv * mv0
initial(Ev) <- init_Ev * mv0
initial(Iv) <- init_Iv * mv0

deriv(Sv) <- -ince - mu*Sv + betaa_td
deriv(Ev) <- ince - incv - mu*Ev
deriv(Iv) <- incv - mu*Iv

# Total mosquito population
mv = Sv+Ev+Iv
output(spz_rate) <- Iv/mv
output(eff_moz_pop) <- mv
output(moz2human_ratio) <- mv/H

##------------------------------------------------------------------------------
###################
## LARVAL STATES ##
###################
##------------------------------------------------------------------------------

# Model by White et al.
# (https://parasitesandvectors.biomedcentral.com/articles/10.1186/1756-3305-4-153)

# EL - early larval instar stage
# LL - late larval instar stage
# PL - pupal stage

# mean carrying capacity from initial mosquito density:
#dLL <- user() # development time of larvae
#dPL <- user() #development time of pupae
#dEL <- user() #development time of early stage
#muLL <- user() #daily density dep. mortality rate of larvae
#muPL <- user() #daily den. dep. mortality rate of pupae
#muEL <- user() #daily den. dep. mortality rate of early stage
#gammaL <- user() # eff. of den. dep. on late stage relative to early stage

# fitted entomological parameters:
#mv0 <- user() # initial mosquito density
#mu0 <- user() # baseline mosquito death rate
#tau1 <- user() # duration of host-seeking behaviour
#tau2 <- user() # duration of resting behaviour
#p10 <- user() # prob of surviving 1 feeding cycle
#p2 <- user() #prob of surviving one resting cycle
#betaL <- user() # maximum number of eggs per oviposition per mosq
#Q0 <- user() # proportion of anthropophagy


# Entomological variables:
#eov <- betaL/mu*(exp(mu/fv)-1)
#beta_larval <- eov*mu*exp(-mu/fv)/(1-exp(-mu/fv)) # Number of eggs laid per day
#b_lambda <- (gammaL*muLL/muEL-dEL/dLL+(gammaL-1)*muLL*dEL)
#lambda <- -0.5*b_lambda + sqrt(0.25*b_lambda^2 + gammaL*beta_larval*muLL*dEL/(2*muEL*mu0*dLL*(1+dPL*muPL)))
#K0 <- 2*mv0*dLL*mu0*(1+dPL*muPL)*gammaL*(lambda+1)/(lambda/(muLL*dEL)-1/(muLL*dLL)-1)

# Seasonal carrying capacity KL = base carrying capacity K0 * effect for time of year theta:
#p1<-p10
#KL <- K0*theta2
#fv <- 1/( tau1 + tau2 ) # mosquito feeding rate (zbar from intervention param.)
#mu <- -fv*log(p1*p2) # mosquito death rate
#av <- fv*Q0
# finding equilibrium and initial values for EL, LL & PL
#init_PL <- user()
#initial(PL) <- init_PL
#init_LL <- user()
#initial(LL) <- init_LL
#init_EL <- user()
#initial(EL) <- init_EL

# (beta_larval (egg rate) * total mosquito) - den. dep. egg mortality - egg hatching
#deriv(EL) <- beta_larval*mv-muEL*(1+(EL+LL)/KL)*EL - EL/dEL
# egg hatching - den. dep. mortality - maturing larvae
#deriv(LL) <- EL/dEL - muLL*(1+gammaL*(EL + LL)/KL)*LL - LL/dLL
# pupae - mortality - fully developed pupae
#deriv(PL) <- LL/dLL - muPL*PL - PL/dPL

##------------------------------------------------------------------------------
###################
## MODEL OUTPUTS ##
###################
##------------------------------------------------------------------------------

# Outputs for each compartment across the sum across all ages, biting heterogeneities and intervention categories
output(Sout) <- sum(S[,])
output(Tout) <- sum(T[,])
output(Dout) <- sum(D[,])
output(Aout) <- sum(A[,])
output(Uout) <- sum(U[,])
output(Pout) <- sum(P[,])

# Outputs for clinical incidence and prevalence on a given day
# population densities for each age category
den[] <- user()
dim(den) <- na
# index of the age vector above 59 months
age59 <- user(integer=TRUE)
age05 <- user(integer=TRUE)
age_flex_length <- user(integer=TRUE)
age0 <- user(integer=TRUE)
age1 <- user(integer=TRUE)

# slide positivity in 0 -5 year age bracket
dim(prev0to59) <- c(age59,nh)
prev0to59[1:age59,] <- T[i,j] + D[i,j]  + A[i,j]*p_det[i,j]
prev_u5 <- sum(prev0to59[,])/sum(den[1:age59])
output(prev) <- prev_u5

dim(prevX) <- c(age0,nh)
dim(prevY) <- c(age1,nh)

prevX[1:age0,] <- T[i,j] + D[i,j]  + A[i,j]*p_det[i,j]
prevY[1:age1,] <- T[i,j] + D[i,j]  + A[i,j]*p_det[i,j]

prev_flex <- (sum(prevY[,])-sum(prevX[,]))/sum(den[age0:age1])

output(prev_flex) <- prev_flex


output(age59)<-age59
dim(prevall) <- c(na,nh)
prevall[,] <- T[i,j] + D[i,j]  + A[i,j]*p_det[i,j]
output(prev_all) <- sum(prevall[,])/sum(den[])
logodds_child <- log(prev_u5/(1-prev_u5))

log_OR_pg_v_c <- user()
log_OR_ps_v_pp <- user()
log_OR_pm_v_pp <- user()
log_OR_pall_v_c <- user()

log_odds_pg <- logodds_child + log_OR_pg_v_c
log_odds_sg <- log_odds_pg + log_OR_ps_v_pp
log_odds_mg <- log_odds_pg + log_OR_pm_v_pp
log_odds_all <- logodds_child + log_OR_pall_v_c

output(prev_preg_pg) <- exp(log_odds_pg)/(1+exp(log_odds_pg))
output(prev_preg_sg) <- exp(log_odds_sg)/(1+exp(log_odds_sg))
output(prev_preg_mg) <- exp(log_odds_mg)/(1+exp(log_odds_mg))
output(prev_preg_all) <- exp(log_odds_all)/(1+exp(log_odds_all))

#Get prevalence by each age group
###Need to create switch to turn this on and off
# ag_dim <- user()
# age_convert[] <- user()
# dim(age_convert) <- ag_dim
# prevdim <- ag_dim-1
# dim(prevbyage) <- prevdim
# prevbyage[1] <- sum(prevall[age_convert[i]:age_convert[i+1],])/sum(den[age_convert[i]:age_convert[i+1]])
# prevbyage[2:prevdim] <- sum(prevall[(age_convert[i]+1):age_convert[i+1],])/sum(den[(age_convert[i]+1):age_convert[i+1]])
# dim(prevout) <- prevdim
# output(prevout[]) <- prevbyage[i]

# clinical incidence
dim(clin_inc0tounder5) <- c(age59,nh)
clin_inc0tounder5[1:age59,] <- clin_inc[i,j]
output(incunder5) <- sum(clin_inc0tounder5)/sum(den[1:age59])

dim(clin_inc0to5) <- c(age05,nh)
clin_inc0to5[1:age05,] <- clin_inc[i,j]
output(inc05) <- sum(clin_inc0to5)/sum(den[1:age05])

output(inc) <- sum(clin_inc[,])


# Param checking outputs
#output(mu) <- mu
#output(beta_larval) <- beta_larval
#output(KL) <- KL
#output(mv) <- mv
#output(K0) <- K0
