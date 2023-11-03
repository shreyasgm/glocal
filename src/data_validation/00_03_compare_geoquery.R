# Load packages
packages <-
  c("tidyverse",
    "arrow",
    "sf",
    "ggcorrplot",
    "here")
sapply(packages, library, character.only = T)

# Set working directory appropriately
# setwd("/n/holystore01/LABS/hausmann_lab/lab/glocal_aggregations/shreyas")
here::i_am("data_validation/00_03_compare_geoquery.R")
PROJ <- here("data_validation/")
ROOT <- here()
DATA <- here(ROOT, "data")
#-------------------------------------------------------------------

# Read GADM data
gadm <-
  read_parquet(here(DATA, "intermediate/gadm_without_geometry/gadm36_1.parquet")) %>%
  select(GID_0, GID_1, NAME_1) %>%
  # filter(GID_0 == "USA") %>%
  select(-GID_0) %>%
  rename(state = NAME_1, gid = GID_1)

# Loads GID_1 to state name key
gid_states <-
  read_csv(here(PROJ, "supporting_data/gid_to_states_viirs.csv"),
           show_col_types = FALSE) %>%
  select(gid, state) %>%
  # Split last 4 characters of gid into separate column called year
  separate(gid, into = c("gid", "year"), sep = -4) %>%
  separate(state, into = c("state", "year2"), sep = -4) %>%
  select(-year2, -year) %>%
  # Remove duplicates
  distinct()

# Check if gid is unique
length(unique(gid_states$gid)) == nrow(gid_states)

# Read geoquery
viirs_geoquery <-
  read_csv(here(PROJ, "supporting_data/geoquery_viirs_raw.csv"),
           show_col_types = FALSE) %>%
  # Keep only column shapeName and those that starts with viirs_
  select(shapeName, starts_with("viirs_")) %>%
  # Convert to long
  pivot_longer(cols = starts_with("viirs_"),
               names_to = "year",
               values_to = "viirs_geoquery") %>%
  # Separate year using separator . into dataset, year, method
  separate(year,
           into = c("dataset", "year", "method"),
           sep = "\\.") %>%
  select(state = shapeName, year, viirs_geoquery) %>%
  # Merge in gid_states
  left_join(gadm, by = c("state")) %>%
  rename(GID_1 = gid) %>%
  # Convert year to int
  mutate(year = as.integer(year)) %>%
  # Keep year 2020
  filter(year == 2020)

# Read GADM
gadm_1 <- arrow::read_parquet(here(DATA, "processed/simplified_shapefiles/gadm/gadm_1.parquet"), col_select=c("GID_0", "GID_1"))

viirs_glocal <-
  arrow::open_dataset(here(
    DATA,
    "processed/imagery_aggregations/annualized_level_1.parquet"
  )) %>%
  # Keep year 2020
  filter(year == 2020)
names(viirs_glocal)

id_variables <- c("GID_1",
                  "year")

ntl_variables <- c(
  "viirs_custom_mean",
  "viirs_custom_median",
  "ntl_dvnl",
  "ntl_dmsp_ext",
  "viirs",
  "dmsp_stable_lights"
)

viirs_glocal <-
  arrow::read_parquet(
    here(
      DATA,
      "processed/imagery_aggregations/annualized_level_1.parquet"
    ),
    col_select = all_of(c(id_variables, ntl_variables))
  ) %>%
  # Keep year 2020
  filter(year == 2020) %>%
  # Inner join GADM
  inner_join(gadm_1, by = c("GID_1"))

# Merge in geoquery data
viirs_glocal <- viirs_glocal %>%
  left_join(viirs_geoquery, by = c("GID_1", "year"))

# Check correlations between ntl variables, with annotation inside the cell
ntl_corr <- viirs_glocal %>%
  select(all_of(c(ntl_variables, "viirs_geoquery"))) %>%
  cor(use = "pairwise.complete.obs") %>%
  as.data.frame()
  
  
  #  %>%
  # # Replace all NA values with 0
  # mutate_all(~ replace(., is.na(.), 0))


# Plot
plot_ntl_corr <- ggcorrplot(
  ntl_corr,
  method = "square",
  type = "full",
  lab = TRUE,
  lab_size = 6
) +
  theme(legend.key.height = unit(2, "cm"))
# Export
ggsave(here(PROJ, "figs/ntl_correlations.png"),
       plot_ntl_corr,
       dpi = 300,
       height=10,
       width=10)
ggsave(here(PROJ, "figs/ntl_correlations.pdf"),
       plot_ntl_corr,
       dpi = 300,
       height=10,
       width=10)

plot_ntl_corr

