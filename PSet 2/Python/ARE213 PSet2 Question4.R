library(tidyverse)
library(data.table)
library(tidysynth)
library(synthdid)
library(xtable)
library(abind)

setwd("/Users/maxsnyder/Dropbox/Berkeley ARE/Year 2/First Semester/Applied Metrics/Metrics PS2")

#Borrowing from here: https://ianadamsresearch.com/post/2021-02-07-tidysynth-demonstration/
set.seed(12345)

df <- fread("/Users/maxsnyder/Dropbox/Berkeley ARE/Year 2/First Semester/Applied Metrics/Metrics PS2/pset2.csv") %>%
  mutate(log_fatal_per_capita = log( (fatalities / (population * 1000)   )))

  control_states <- df %>%
  group_by(state) %>%
  summarize(count_primary = sum(primary == 1)) %>%
  filter(count_primary == 0) %>%
  pull(state)
 
df_for_sc  <- df %>%
  filter(state %in% c("CA", control_states))

#OG SC w/o controls: 
sc_out <- df_for_sc %>%
  # initial the synthetic control object
  synthetic_control(outcome = log_fatal_per_capita, # outcome
                    unit = state, # unit index in the panel data
                    time = year, # time index in the panel data
                    i_unit = "CA", # unit where the intervention occurred
                    i_time = 1993, # time period when the intervention occurred
                    generate_placebos=T ) %>% # generate placebo synthetic controls (for inference)
  generate_predictor(time_window = 1981:1992,
                     log_fatal_per_capita = mean(log_fatal_per_capita, na.rm = T)) %>%
  generate_weights(optimization_window = 1981:1992, # time to use in the optimization task
                   margin_ipop = .02,sigf_ipop = 7,bound_ipop = 6 # optimizer options
  ) %>%
  generate_control()

sc_out %>% plot_trends()  
sc_out %>% plot_weights()


#OG SC w/ controls: 
sc_out <- df_for_sc %>%
  # initial the synthetic control object
  synthetic_control(outcome = log_fatal_per_capita, # outcome
                    unit = state, # unit index in the panel data
                    time = year, # time index in the panel data
                    i_unit = "CA", # unit where the intervention occurred
                    i_time = 1993, # time period when the intervention occurred
                    generate_placebos=T ) %>% # generate placebo synthetic controls (for inference)
  generate_predictor(time_window = 1981:1992,
                     log_fatal_per_capita = mean(log_fatal_per_capita, na.rm = T),
                     college = mean(college, na.rm = T),
                     beer = mean(beer, na.rm = T),
                     unemploy = mean(unemploy, na.rm = T),
                     totalvmt = mean(totalvmt, na.rm = T),
                     precip = mean(precip, na.rm = T),
                     snow32 = mean(snow32, na.rm = T),
                     rural_speed = mean(rural_speed, na.rm = T),
                     population = mean(population, na.rm = T)) %>%
  generate_weights(optimization_window = 1981:1992, # time to use in the optimization task
                   margin_ipop = .02,sigf_ipop = 7,bound_ipop = 6 # optimizer options
  ) %>%
  generate_control()

p1 <- sc_out %>% plot_trends() + ylab("Log Fatalaties per Capita") + xlab("Year") + ggtitle("Time Series of Synthetic and Observed CA")
p2 <- sc_out %>% plot_weights()
p3 <- sc_out %>% plot_differences() +  ylab("Log Fatalaties per Capita") + xlab("Year") + ggtitle("Gap in Log Fatalaties Per Capita in Synthetic and Observed CA")
p4 <- sc_out %>% plot_placebos() + ylab("Log Fatalaties per Capita") + xlab("Year") + ggtitle("Log Fatalaties Per Capita in CA vs Placebo Gaps in Donor States")

ggsave("q4a_synth_observed_plot.pdf",
       p1,
       height = 6,
       width = 10)
ggsave("q4a_synth_weights.pdf", 
       p2,
       height = 6,
       width = 10)
ggsave("q4a_gap_log_fatalties.pdf", 
       p3,
       height = 6,
       width = 10)

ggsave("q4a_placebo_gaps.pdf", 
       p4,
       height = 6,
       width = 10)



#For latex
variable_names <- c("Beer consumption per cap (gals)", "Percent college grads",
                    "Log fatalaties per capita", 
                    "Precipitation(inches)",
                    "Population",
                    "Rural interstate sped limit",
                    "Snow (inches)", 
                    "Vehicle miles traveled",
                    "Unemployment rate")
balance_table <- sc_out %>% grab_balance_table()

balance_table$variable <- variable_names
colnames(balance_table) <- c("Variables", "CA", "Synthetic CA", "Donor Samples")
latex_table <- xtable(balance_table)

print(latex_table, file = "q4a_tex_balance_table.tex")

??plot_trends()

  generate_predictor(time_window = 1981:1992,
                     ln_income = mean(lnincome, na.rm = T),
                     ret_price = mean(retprice, na.rm = T),
                     youth = mean(age15to24, na.rm = T))



#Synthetic diff in diff:
df_for_sc_did <- df_for_sc %>%
  select(state, year, log_fatal_per_capita, primary) %>%
  panel.matrices()

df_for_sc_did$Y

df_for_array <- df_for_sc %>%
  arrange(year, state)

N_var <- length(unique(df_for_sc$state))
T_var <- length(unique(df_for_sc$year))

empty <- array(numeric(), c(N_var, T_var,8)) 

j <- 1
for(i in c("college", "beer", "unemploy", "totalvmt", "precip", "snow32", "rural_speed", "population")){
covar_df <-  df_for_sc %>%
    select(one_of(c("state", "year", i, "primary"))) %>%
    panel.matrices()

empty[,,j]<- df_for_sc_did$Y
j <- j + 1
}

#W.o Covars
tau.hat = synthdid_estimate(df_for_sc_did$Y, df_for_sc_did$N0, df_for_sc_did$T0)
se = sqrt(vcov(tau.hat, method='placebo'))
sprintf('point estimate: %1.2f', tau.hat)
sprintf('95%% CI (%1.2f, %1.2f)', tau.hat - 1.96 * se, tau.hat + 1.96 * se)
plot(tau.hat) + ggtitle("No Covariates")





array(dim = c(dim(setup$Y), 0))

#an optional 3-D array of time-varying covariates. Shape should be N X T X C for C covariates.




data('california_prop99')
setup = panel.matrices(california_prop99)
setup$Y
setup$N0
setup$T0

tau.hat = synthdid_estimate(setup$Y, setup$N0, setup$T0)
se = sqrt(vcov(tau.hat, method='placebo'))
sprintf('point estimate: %1.2f', tau.hat)
sprintf('95%% CI (%1.2f, %1.2f)', tau.hat - 1.96 * se, tau.hat + 1.96 * se)
plot(tau.hat)


#w covars
tau.hat = synthdid_estimate(df_for_sc_did$Y, df_for_sc_did$N0, df_for_sc_did$T0, empty)
#se = sqrt(vcov(tau.hat, method='placebo'))
sprintf('point estimate: %1.2f', tau.hat)
sprintf('95%% CI (%1.2f, %1.2f)', tau.hat - 1.96 * se, tau.hat + 1.96 * se)
p_covars <- plot(tau.hat) + ggtitle("Analaysis with Covariates")


#4b: add in this second graph with weights for each unit.
#Write up 2a and 2b 

ggsave("q4b_covars_sc_did.pdf", 
       p_covars,
       height = 6,
       width = 10)
