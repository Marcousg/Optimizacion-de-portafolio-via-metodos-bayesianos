# ==============================================================================
# LIBRERÍAS
# ==============================================================================
library(quantmod)
library(tidyverse)
library(MCMCpack)
library(ggplot2)
library(ggcorrplot)

# ==============================================================================
# DESCARGA DE DATOS HISTÓRICOS 
# ==============================================================================
tickers <- c("AAPL", "MSFT","GLD", "BTC-USD", "JNJ")

# Tomamos una muestra de 1 año
# 
inicio <- "2024-01-01" 
fin    <- "2025-01-01"

portfolio <- new.env()
getSymbols(tickers, src = "yahoo", from = inicio, to = fin, env = portfolio)

# Combinar los cierres ajustados y limpiar nombres
cierres_df <- do.call(merge, lapply(portfolio, Ad))
colnames(cierres_df) <- gsub("\\.Adjusted", "", colnames(cierres_df))
cierres_df <- na.omit(cierres_df)

# ==============================================================================
# ESTIMACIÓN DE MATRICES DE COVARIANZA
# ==============================================================================
# Calcular retornos logarítmicos diarios
retornos <- diff(log(cierres_df))[-1, ]
retornos_mat <- as.matrix(retornos)

t <- nrow(retornos_mat)  # Número de observaciones temporales (T)
N <- ncol(retornos_mat)  # Número de activos

# 1. Enfoque Frecuentista
Sigma_muestral <- cov(retornos_mat) 

# 2. Enfoque Bayesiano (Prior Inversa-Wishart)
# Elevamos v0 para representar una creencia moderada en nuestra prior
v0 <- 60  

# S0: Asumimos una prior diagonal con independecia entre las variables
varianza_media <- mean(diag(Sigma_muestral))
S0 <- diag(N) * varianza_media * v0 

# Parámetros de la Posterior
vn <- v0 + t
Sn <- S0 + (t - 1) * Sigma_muestral

# Simulación de Monte Carlo (Muestreo de Gibbs)
set.seed(123) 
num_sims <- 10000
cov_simuladas <- array(0, dim = c(N, N, num_sims))

for(i in 1:num_sims) {
  cov_simuladas[,,i] <- riwish(v = vn, S = Sn)
}

# Esperanza de la Matriz Posterior
Sigma_bayes <- apply(cov_simuladas, c(1, 2), mean)
rownames(Sigma_bayes) <- colnames(retornos_mat)
colnames(Sigma_bayes) <- colnames(retornos_mat)

# ==============================================================================
# CÁLCULO DE PESOS: PORTAFOLIO DE MÍNIMA VARIANZA GLOBAL (GMV)
# ==============================================================================
unos <- rep(1, N)

# Inversas
inv_Sigma_muestral <- solve(Sigma_muestral)
inv_Sigma_bayes <- solve(Sigma_bayes)

# Pesos Markowitz
pesos_markowitz <- (inv_Sigma_muestral %*% unos) / as.numeric(t(unos) %*% inv_Sigma_muestral %*% unos)

# Pesos Bayesianos
pesos_bayes <- (inv_Sigma_bayes %*% unos) / as.numeric(t(unos) %*% inv_Sigma_bayes %*% unos)

# ==============================================================================
# COMPARATIVA DE RESULTADOS
# ==============================================================================
resultados <- data.frame(
  Activo = colnames(retornos_mat),
  Peso_Markowitz = round(as.vector(pesos_markowitz) * 100, 2),
  Peso_Bayesiano = round(as.vector(pesos_bayes) * 100, 2)
)

print("--- Comparativa de Pesos (%) del Portafolio Mínima Varianza ---")
print(resultados)



#===============================================================================
#Grafico pesos
#===============================================================================

resultados_long <- resultados %>%
  pivot_longer(cols = starts_with("Peso"), 
               names_to = "Enfoque", 
               values_to = "Peso") %>%
  mutate(Enfoque = ifelse(Enfoque == "Peso_Markowitz", "Frecuentista (Markowitz)", "Bayesiano"))

# Gráfico de barras
ggplot(resultados_long, aes(x = Activo, y = Peso, fill = Enfoque)) +
  geom_bar(stat = "identity", position = "dodge", color = "black", alpha = 0.8) +
  scale_fill_manual(values = c("Frecuentista (Markowitz)" = "#CBD5E0", "Bayesiano" = "#1A4D4A")) +
  theme_minimal() +
  labs(title = "Comparativa de Pesos: Portafolio de Mínima Varianza Global (GMV)",
       x = "Activo",
       y = "Peso Asignado (%)",
       fill = "Modelo") +
  theme(legend.position = "bottom",
        plot.title = element_text(face = "bold"))


#===============================================================================
#Grafico matriz de covarianza
#===============================================================================
Cor_muestral <- cov2cor(Sigma_muestral)
Cor_bayes <- cov2cor(Sigma_bayes)

# mapa de calor Frecuentista
p1 <- ggcorrplot(Cor_muestral, hc.order = FALSE, type = "lower",
                 lab = TRUE, lab_size = 3, colors = c("#6D9EC1", "white", "#E46726"),
                 title = "Correlación Frecuentista")

p1

# mapa de calor Bayesiano
p2 <- ggcorrplot(Cor_bayes, hc.order = FALSE, type = "lower",
                 lab = TRUE, lab_size = 3, colors = c("#6D9EC1", "white", "#E46726"),
                 title = "Correlación Bayesiana (Prior Inversa-Wishart)")

p2


#===============================================================================
#Comportamiento fuera de la muestra
#===============================================================================

# Descargamos datos fuera de la muestra 
inicio_oos <- "2026-01-01"
fin_oos <- "2026-06-01"
portfolio_oos <- new.env()
getSymbols(tickers, src = "yahoo", from = inicio_oos, to = fin_oos, env = portfolio_oos)

cierres_oos <- do.call(merge, lapply(portfolio_oos, Ad))
colnames(cierres_oos) <- gsub("\\.Adjusted", "", colnames(cierres_oos))
retornos_oos <- na.omit(diff(log(cierres_oos))[-1, ])
retornos_oos_mat <- as.matrix(retornos_oos)

# Calcular retornos diarios de los portafolios
port_ret_markowitz <- retornos_oos_mat %*% pesos_markowitz
port_ret_bayes <- retornos_oos_mat %*% pesos_bayes

# Calcular la volatilidad anualizada fuera de muestra
vol_markowitz <- sd(port_ret_markowitz) * sqrt(252) * 100
vol_bayes <- sd(port_ret_bayes) * sqrt(252) * 100

tabla_oos <- data.frame(
  Modelo = c("Markowitz", "Bayesiano"),
  Volatilidad_OOS_Anualizada = c(round(vol_markowitz, 2), round(vol_bayes, 2))
)
print("--- Volatilidad Realizada (Fuera de Muestra 2024) ---")
print(tabla_oos)



