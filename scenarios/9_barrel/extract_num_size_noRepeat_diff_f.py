import sys
sys.path.append('../../tool/')
import partmc
import scipy.io
import os
import numpy
import math
import mpl_helper
import matplotlib.pyplot as plt

col = 41
dataset_name = '0925'

partmc_data_1 = numpy.loadtxt("out/barrel_wc_0001_aero_size_num_f_1.txt")
partmc_data_2 = numpy.loadtxt("out/barrel_wc_0001_aero_size_num_f_135.txt")
partmc_data_3 = numpy.loadtxt("out/barrel_wc_0001_aero_size_num_f_143.txt")
partmc_data_4 = numpy.loadtxt("out/barrel_wc_0001_aero_size_num_f_2.txt")

"""
Calculate and plot percentage difference
"""
diff = abs(partmc_data_1[:,col] - partmc_data_4[:,col])
for i in range(0, len(partmc_data_1)):
    if (partmc_data_1[i,col]==0 and partmc_data_4[i,col]==0):
        diff[i] = 0
    else:
        diff[i] = diff[i] / abs((partmc_data_1[i,col] + partmc_data_4[i,col]) / 2) * 100
(figure, axes) = mpl_helper.make_fig(colorbar=False)
axes.semilogx(partmc_data_1[:,0], diff, color='k')
axes.set_title("")
axes.set_xlabel("Dry diameter (m)")
axes.set_ylabel("Percentage difference (\%)")
axes.grid()
filename_out = "percentage_diff_f.pdf"
figure.savefig(filename_out)

(figure, axes) = mpl_helper.make_fig(colorbar=False)
axes.semilogx(partmc_data_1[:,0], partmc_data_1[:,col] * math.log(10), color='g')
axes.semilogx(partmc_data_2[:,0], partmc_data_2[:,col] * math.log(10), color='b')
axes.semilogx(partmc_data_3[:,0], partmc_data_3[:,col] * math.log(10), color='r')
axes.semilogx(partmc_data_4[:,0], partmc_data_4[:,col] * math.log(10), color='y')
axes.set_title("")
axes.set_xlabel("Dry diameter (m)")
axes.set_ylabel(r"Number concentration ($\mathrm{m}^{-3}$)")
axes.grid()
axes.set_ylim(0,)
axes.legend(('$f$ = 1.0','$f$ = 1.35','$f$ = 1.43','$f$ = 2.0'),loc='upper left')
filename_out = "aero_num_size.pdf"
figure.savefig(filename_out)
