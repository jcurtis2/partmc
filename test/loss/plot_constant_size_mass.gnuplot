# run from inside gnuplot with:
# load "<filename>.gnuplot"
# or from the commandline with:
# gnuplot -persist <filename>.gnuplot

set title "constant size mass"

set logscale
set xlabel "diameter / m"
set ylabel "mass concentration / (kg/m^3)"

set key left top

set xrange [1e-9:1e-3]
set yrange [1e-15:1e-3]

plot "out/loss_part_constant_0001_aero_size_mass.txt" using 1:2 title "particle t = 0 minutes", \
     "out/loss_part_constant_0001_aero_size_mass.txt" using 1:5 title "particle t = 30 minutes", \
     "out/loss_part_constant_0001_aero_size_mass.txt" using 1:8 title "particle t = 60 minutes", \
     "out/loss_exact_constant_aero_size_mass.txt" using 1:2 with lines title "exact t = 0 minutes", \
     "out/loss_exact_constant_aero_size_mass.txt" using 1:5 with lines title "exact t = 30 minutes", \
     "out/loss_exact_constant_aero_size_mass.txt" using 1:8 with lines title "exact t = 60 minutes"
