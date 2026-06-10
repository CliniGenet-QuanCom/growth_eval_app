// GENERATED FILE - do not edit by hand.
// Coefficients transcribed from the JSPE/JSGA reference workbooks.
// ignore_for_file: constant_identifier_names

// Weight-SDS LMS: L,M,S are piecewise polynomials of integer age in months.
// Polynomial coefficient lists are ordered power 10 -> 0 (11 entries).

const List<double> wL_male = [0.0, 0.0, 0.0, -1.22124e-14, 1.21101e-11, -4.60186e-09, 8.47206e-07, -7.9448e-05, 0.003821167, -0.105462102, 0.773978418];
const List<double> wL_female_lo = [0.0, 0.0, 0.0, 9.57783e-15, 3.40688e-12, -4.02644e-09, 1.02461e-06, -0.000111585, 0.00572164, -0.1423975, 0.75407123];  // months < 186
// female L, months>=186: U9 + V9*(x-W9)
const double wL_female_hi_U = -1.01189265313387;
const double wL_female_hi_V = -0.01;
const double wL_female_hi_W = 186.0;

const List<double> wM_male_a = [-1.47516e-16, 8.64234e-14, -2.1785e-11, 3.09361e-09, -2.72279e-07, 1.5405e-05, -0.000562773, 0.013003151, -0.180948751, 1.543755195, 2.997999999999999];  // months < 45
const List<double> wM_male_b = [-1.1515e-19, 6.81139e-17, 4.2436e-15, -1.38588e-11, 5.04956e-09, -9.26625e-07, 0.000100181, -0.006595815, 0.258754709, -5.3772656, 57.357579975];  // months < 153
// male M, months>=153: M27 + N27/(1+exp(O27+P27*x))
const List<double> wM_male_logit = [32.573560788, 29.54392183, 9.666614296, -0.061094318];
const List<double> wM_female_a = [-7.51741e-17, 4.69662e-14, -1.2713e-11, 1.94862e-09, -1.85497e-07, 1.1321e-05, -0.000442047, 0.010732292, -0.153244414, 1.344114385, 2.9604311032655537];  // months < 43.8 ; then -0.010431*(1-x/210)
const List<double> wM_female_b = [1.4809e-18, -1.83788e-15, 9.87822e-13, -3.01759e-10, 5.78356e-08, -7.24866e-06, 0.000600612, -0.032450221, 1.093746236, -20.60434468, 175.86326566];  // months < 123 ; then -0.010431*(1-1/x)
// female M, months>=123: M32 + N32/(1+exp(O32+P32*x)) - 0.010431*(1-x/210)
const List<double> wM_female_logit = [20.045309811, 32.70516364, 7.321946213, -0.055342147];

const List<double> wS_male_lo = [0.0, 0.0, 0.0, -1.70052e-15, 1.44639e-12, -4.82906e-10, 8.05352e-08, -7.13202e-06, 0.000331663, -0.006705229, 0.148630769];  // months < 162
const List<double> wS_male_hi = [0.0, 0.0, 0.0, -3.15182e-15, 2.49168e-12, -7.75159e-10, 1.20356e-07, -9.84604e-06, 0.000415677, -0.007506024, 0.14931116];  // months >= 162
const List<double> wS_female_lo = [0.0, 0.0, 1.26329e-16, -8.73489e-14, 2.49993e-11, -3.84539e-09, 3.44807e-07, -1.8279e-05, 0.000556515, -0.008191452, 0.146045294];  // months < 156
// female S, 156<=months<186: U + (V-U)/24*(x-186) + Wc*(186-x)^2 - 0.005
//            months>=186: U + (V-U)/24*(x-186) - 0.005
const double wS_female_U = 0.1442;
const double wS_female_V = 0.138804;
const double wS_female_W = 3.3e-05;
