# Optimización Bayesiana de Portafolios: Enfoque Inversa-Wishart

Este repositorio contiene el código en `R` utilizado para el ejercicio empírico del artículo sobre **Optimización Bayesiana de Portafolios frente al Modelo Frecuentista de Markowitz**. 

El objetivo principal de este script es demostrar cómo la estadística bayesiana, a través del uso de una distribución *a priori* Inversa-Wishart, mitiga el riesgo de estimación y el efecto de "maximizador de errores" presente en la optimización clásica de media-varianza.

## 📊 Descripción del Ejercicio
El código calcula y compara los pesos óptimos de un **Portafolio de Mínima Varianza Global (GMV)** utilizando dos metodologías:
1. **Enfoque Frecuentista (Markowitz):** Utiliza la matriz de covarianza muestral de los datos históricos.
2. **Enfoque Bayesiano:** Aplica simulación Monte Carlo (Muestreo de Gibbs) para obtener la media de la distribución *a posteriori* de la matriz de covarianzas, induciendo un efecto de encogimiento (*shrinkage*) hacia una prior de independencia.

Se utiliza un universo de cinco activos contrastantes (JNJ, AAPL, MSFT, GLD y BTC-USD) para someter a estrés ambos modelos ante problemas de hiperconcentración y multicolinealidad.

## 🛠️ Requisitos y Librerías
Para ejecutar el código y generar las visualizaciones, necesitas tener instalado `R` y los siguientes paquetes:

- `quantmod`: Para la descarga de datos históricos financieros (Yahoo Finance).
- `tidyverse` (`dplyr`, `purrr`): Para la manipulación de datos y cálculo de retornos.
- `MCMCpack`: Para el muestreo de la distribución Inversa-Wishart (`riwish`).
- `ggplot2`: Para la creación de gráficos avanzados y comparativas visuales de los pesos del portafolio.
- `ggcorrplot`: Para la visualización térmica (*heatmap*) de las matrices de covarianza y correlación.

Puedes instalar las dependencias con el siguiente comando en R:
```R
install.packages(c("quantmod", "tidyverse", "MCMCpack", "ggplot2", "ggcorrplot"))
