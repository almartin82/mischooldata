# Michigan Enrollment Trends

``` r
library(mischooldata)
library(ggplot2)
library(dplyr)
library(scales)
```

``` r
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
            "hispanic" = "#F39C12", "asian" = "#9B59B6", "native_american" = "#1ABC9C",
            "pacific_islander" = "#E67E22", "multiracial" = "#95A5A6")
```

``` r
# Get available years
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
enr <- fetch_enr_multi((max_year - 7):max_year, use_cache = TRUE)
key_years <- seq(max(min_year, 2000), max_year, by = 5)
if (!max_year %in% key_years) key_years <- c(key_years, max_year)
# Exclude 2015 - uses .xlsb format which is not supported
key_years <- key_years[key_years != 2015]
enr_long <- fetch_enr_multi(key_years, use_cache = TRUE)
enr_current <- fetch_enr(max_year, use_cache = TRUE)
```

## 1. Detroit’s collapse is staggering

Detroit Public Schools Community District has lost over 100,000 students
since 2000, now serving under 50,000. This represents one of the most
dramatic urban enrollment declines in American education history.

``` r
detroit <- enr_long %>%
  filter(is_district, district_id == "82015",
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(detroit, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Detroit Public Schools Collapse",
       subtitle = "Lost over 100,000 students since 2000",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 2. Statewide enrollment has been declining

Michigan has lost hundreds of thousands of students since 2000,
reflecting demographic shifts and economic changes. The state peaked at
around 1.7 million K-12 students and now serves approximately 1.4
million.

``` r
state <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(state, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Michigan Statewide Enrollment Decline",
       subtitle = "Total K-12 enrollment trending downward",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 3. Grand Rapids is more diverse than you think

Michigan’s second-largest city has become majority-minority, with
Hispanic enrollment growing fastest. Grand Rapids Public Schools now
reflects a highly diverse student population.

``` r
gr <- enr %>%
  filter(is_district, grepl("Grand Rapids", district_name, ignore.case = TRUE),
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian"))

ggplot(gr, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors,
                     labels = c("Asian", "Black", "Hispanic", "White")) +
  labs(title = "Grand Rapids is Majority-Minority",
       subtitle = "More diverse than you might think",
       x = "School Year", y = "Percent", color = "") +
  theme_readme()
```

## 4. The Upper Peninsula is emptying out

UP districts have lost 25-40% of students since 2000 as the region’s
population ages and young families move south. This rural decline
mirrors national patterns but is particularly acute in Michigan’s
northern reaches.

``` r
up_districts <- c("Marquette", "Houghton", "Iron Mountain", "Menominee")
up <- enr_long %>%
  filter(is_district, grepl(paste(up_districts, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

ggplot(up, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Upper Peninsula Emptying Out",
       subtitle = "Marquette, Houghton, Iron Mountain, Menominee combined",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 5. COVID hit kindergarten hard

Michigan lost nearly 10,000 kindergartners in 2021 and hasn’t fully
recovered. The pandemic disrupted the transition to formal schooling for
thousands of Michigan families.

``` r
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12"
  ))

ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Hit Michigan Kindergarten Hard",
       subtitle = "Lost nearly 10,000 kindergartners in 2021",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

## 6. Ann Arbor: island of stability

While Detroit hemorrhages students, Ann Arbor maintains around 17,000
and high diversity. The university town’s economic stability and
educated workforce create a different enrollment trajectory.

``` r
aa <- enr %>%
  filter(is_district, grepl("Ann Arbor", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(aa, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Ann Arbor: Island of Stability",
       subtitle = "Maintains ~17,000 students while Detroit collapses",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 7. Multiracial enrollment growing fastest

Multiracial students are Michigan’s fastest-growing demographic,
increasing 31% from 57,291 to 75,055 students since 2018. While overall
enrollment declines, multiracial and Hispanic populations continue to
grow, reshaping the state’s educational demographics.

``` r
multiracial_state <- enr %>%
  filter(is_state, subgroup == "multiracial", grade_level == "TOTAL")

ggplot(multiracial_state, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["multiracial"]) +
  geom_point(size = 3, color = colors["multiracial"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Multiracial Enrollment Growing Statewide",
       subtitle = "Fastest-growing demographic in Michigan schools (+31% since 2018)",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 8. Largest districts by enrollment

The 10 largest districts represent a mix of urban, suburban, and diverse
communities. Detroit remains the largest despite decades of decline,
followed by suburban powerhouses like Utica and Dearborn.

``` r
largest <- enr_current %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10) %>%
  mutate(district_label = reorder(district_name, n_students))

ggplot(largest, aes(x = district_label, y = n_students)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Michigan's Largest School Districts",
       subtitle = "Top 10 districts by total enrollment",
       x = "", y = "Total Students") +
  theme_readme()
```

## 9. Flint’s water crisis visible in enrollment

Flint Community Schools lost over 40% of students during and after the
water crisis. The crisis accelerated an already declining enrollment as
families fled the city.

``` r
flint <- enr %>%
  filter(is_district, grepl("Flint Community", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(flint, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Flint's Water Crisis Visible in Enrollment",
       subtitle = "Lost over 40% of students during and after the crisis",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 10. Oakland County suburbs holding

Oakland County districts like Troy, Rochester, and Novi maintain
enrollment while Detroit collapses. These affluent suburbs benefit from
strong economies and excellent school reputations.

``` r
oakland <- c("Troy", "Rochester", "Novi", "Farmington")
oakland_trend <- enr %>%
  filter(is_district, grepl(paste(oakland, collapse = "|"), district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(oakland_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Oakland County Suburbs Holding",
       subtitle = "Troy, Rochester, Novi, Farmington stable",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

## 11. Dearborn: Arab American educational hub

Dearborn Public Schools serves one of the largest Arab American
communities in the nation. The district maintains stable enrollment with
a unique demographic profile.

``` r
dearborn <- enr %>%
  filter(is_district, grepl("Dearborn", district_name, ignore.case = TRUE),
         !grepl("Heights", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(dearborn, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Dearborn: A Unique Michigan Story",
       subtitle = "Home to largest Arab American student population in the US",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 12. Black student enrollment declining

Black student enrollment in Michigan has declined significantly, driven
primarily by Detroit’s collapse. This demographic shift is reshaping the
state’s educational landscape.

``` r
black_state <- enr %>%
  filter(is_state, subgroup == "black", grade_level == "TOTAL")

ggplot(black_state, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["black"]) +
  geom_point(size = 3, color = colors["black"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Black Student Enrollment Declining",
       subtitle = "Driven by Detroit's population loss",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 13. Lansing bucking the urban decline

Unlike Detroit and Flint, Lansing School District has maintained
relatively stable enrollment. The state capital’s diverse economy and
state government employment provide a buffer against the losses seen in
other urban cores.

``` r
lansing <- enr %>%
  filter(is_district, grepl("Lansing School District", district_name, ignore.case = TRUE),
         subgroup == "total_enrollment", grade_level == "TOTAL")

ggplot(lansing, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Lansing Bucking the Urban Decline",
       subtitle = "State capital maintains stability while other cities collapse",
       x = "School Year", y = "Students") +
  theme_readme()
```

## 14. High school enrollment shrinking faster

High school grades are shrinking faster than elementary grades
statewide, as the birth rate decline from the 2008 recession reaches
secondary schools.

``` r
grade_bands <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "02", "03", "04", "05",
                            "09", "10", "11", "12")) %>%
  mutate(level = ifelse(grade_level %in% c("K", "01", "02", "03", "04", "05"),
                        "Elementary (K-5)", "High School (9-12)")) %>%
  group_by(end_year, level) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

ggplot(grade_bands, aes(x = end_year, y = n_students, color = level)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "High School Shrinking Faster Than Elementary",
       subtitle = "2008 recession birth rate decline reaching high school",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

## 15. Demographic transformation: Michigan’s changing face

Michigan’s racial demographics are shifting dramatically. White student
enrollment has declined substantially while Hispanic and multiracial
populations grow. This transformation will reshape Michigan education
for decades.

``` r
demo_state <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial"))

ggplot(demo_state, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors,
                     labels = c("Asian", "Black", "Hispanic", "Multiracial", "White")) +
  scale_y_continuous(limits = c(0, NA)) +
  labs(title = "Michigan's Demographic Transformation",
       subtitle = "White enrollment declining, Hispanic and multiracial growing",
       x = "School Year", y = "Percent of Students", color = "") +
  theme_readme()
```
