my_theme <- theme_bw() +
  theme(
    panel.grid = element_blank(),
    axis.line = element_line(linewidth = 0.4),
    strip.background = element_blank(),
    panel.border = element_blank()
  )

parse_time <- function(filename) {
  v_log = read_lines(filename)
  as.numeric(v_log[length(v_log) - 2] %>%
               str_split_i("\t", 2) %>% str_split_i("m", 1))
}
