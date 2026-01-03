#!/usr/bin/env Rscript
# Generate README figures for mischooldata

library(ggplot2)
library(dplyr)
library(scales)
devtools::load_all(".")

# Create figures directory
dir.create("man/figures", recursive = TRUE, showWarnings = FALSE)

# Theme
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6")

# Get available years (handles both vector and list return types)
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
message("Fetching data...")
enr <- fetch_enr_multi((max_year - 7):max_year)
key_years <- seq(max(min_year, 2000), max_year, by = 5)
if (!max_year %in% key_years) key_years <- c(key_years, max_year)
enr_long <- fetch_enr_multi(key_years)
enr_current <- fetch_enr(max_year)

# 1. Detroit decline
message("Creating Detroit decline chart...")
detroit <- enr_long %>%
  filter(is_district, district_id == "82015",
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(detroit, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Detroit Public Schools Collapse",
       subtitle = "Lost over 100,000 students since 2000",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/detroit-decline.png", p, width = 10, height = 6, dpi = 150)

# 2. Charter growth
message("Creating charter growth chart...")
charter <- enr %>%
  filter(is_charter, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p <- ggplot(charter, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Michigan Charter Schools Serve 150,000+",
       subtitle = "One of the largest charter sectors in the country",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/charter-growth.png", p, width = 10, height = 6, dpi = 150)

# 3. Grand Rapids diversity
message("Creating Grand Rapids diversity chart...")
gr <- enr %>%
  filter(is_district, grepl("Grand Rapids", district_name, ignore.case = TRUE),
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian"))

p <- ggplot(gr, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors,
                     labels = c("Asian", "Black", "Hispanic", "White")) +
  labs(title = "Grand Rapids is Majority-Minority",
       subtitle = "More diverse than you might think",
       x = "School Year", y = "Percent", color = "") +
  theme_readme()
ggsave("man/figures/gr-diversity.png", p, width = 10, height = 6, dpi = 150)

# 4. UP decline
message("Creating UP decline chart...")
up_districts <- c("Marquette", "Houghton", "Iron Mountain", "Menominee")
up <- enr_long %>%
  filter(is_district, grepl(paste(up_districts, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

p <- ggplot(up, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Upper Peninsula Emptying Out",
       subtitle = "Marquette, Houghton, Iron Mountain, Menominee combined",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/up-decline.png", p, width = 10, height = 6, dpi = 150)

# 5. COVID kindergarten
message("Creating COVID K chart...")
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12"
  ))

p <- ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Hit Michigan Kindergarten Hard",
       subtitle = "Lost nearly 10,000 kindergartners in 2021",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/covid-k.png", p, width = 10, height = 6, dpi = 150)

# 6. Ann Arbor stability
message("Creating Ann Arbor chart...")
aa <- enr %>%
  filter(is_district, grepl("Ann Arbor", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(aa, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Ann Arbor: Island of Stability",
       subtitle = "Maintains ~17,000 students while Detroit collapses",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/aa-stable.png", p, width = 10, height = 6, dpi = 150)

# 7. Economic divide
message("Creating econ divide chart...")
econ <- enr_current %>%
  filter(is_district, subgroup == "econ_disadv", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

p <- ggplot(econ, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  labs(title = "Economic Disadvantage Varies Wildly",
       subtitle = "From 90%+ in some districts to 10% in wealthy suburbs",
       x = "", y = "Percent Economically Disadvantaged") +
  theme_readme()
ggsave("man/figures/econ-divide.png", p, width = 10, height = 6, dpi = 150)

# 8. EL concentration
message("Creating EL concentration chart...")
el <- enr_current %>%
  filter(is_district, subgroup == "lep", grade_level == "TOTAL") %>%
  arrange(desc(pct)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, pct))

p <- ggplot(el, aes(x = district_label, y = pct * 100)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  labs(title = "English Learners in Southwest Michigan",
       subtitle = "Holland, Grand Rapids, Kalamazoo have highest EL rates",
       x = "", y = "Percent English Learners") +
  theme_readme()
ggsave("man/figures/el-concentration.png", p, width = 10, height = 6, dpi = 150)

# 9. Flint crisis
message("Creating Flint chart...")
flint <- enr %>%
  filter(is_district, grepl("Flint Community", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(flint, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Flint's Water Crisis Visible in Enrollment",
       subtitle = "Lost over 40% of students during and after the crisis",
       x = "School Year", y = "Students") +
  theme_readme()
ggsave("man/figures/flint-crisis.png", p, width = 10, height = 6, dpi = 150)

# 10. Oakland suburbs
message("Creating Oakland suburbs chart...")
oakland <- c("Troy", "Rochester", "Novi", "Farmington")
oakland_trend <- enr %>%
  filter(is_district, grepl(paste(oakland, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

p <- ggplot(oakland_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Oakland County Suburbs Holding",
       subtitle = "Troy, Rochester, Novi, Farmington stable",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
ggsave("man/figures/oakland-suburbs.png", p, width = 10, height = 6, dpi = 150)

message("Done! Generated 10 figures in man/figures/")
