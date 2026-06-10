// GENERATED FILE - do not edit by hand.
// Coefficients transcribed from the JSPE/JSGA reference workbooks.

// Standard-weight coefficient tables for the three obesity indices.

// Murata infant quadratic: stdWeight(kg) = a*h^2 + b*h + c, h in cm.
const List<double> murataMale = [2.06e-3, -0.1166, 6.5273];
const List<double> murataFemale = [2.49e-3, -0.1858, 9.036];

// Ito height-band cubic: stdWeight(kg) = a*X^3+b*X^2+c*X+d, X = height(cm)/100.
// Rows 0-2 male (h<140, 140-149, >=149), rows 3-5 female.
const List<List<double>> itoHeightCubic = [
  [30.3882, -57.1495, 50.8124, -9.17791],
  [-85.013, 370.692, -465.58, 191.847],
  [-310.205, 1511.59, -2363.03, 1231.04],
  [127.719, -414.712, 485.75, -184.492],
  [-1787.66, 8039.22, -11931.0, 5885.03],
  [956.401, -4627.55, 7530.58, -4068.31],
];

// Ito age-linear: stdWeight(kg) = a*h + b, h in cm. Index = INT(age)-5 for ages 5..17.
const List<List<double>> itoAgeLinearMale = [
  [0.386, -23.699],
  [0.461, -32.382],
  [0.513, -38.878],
  [0.592, -48.804],
  [0.687, -61.39],
  [0.752, -70.461],
  [0.782, -75.106],
  [0.783, -75.642],
  [0.815, -81.348],
  [0.832, -83.695],
  [0.766, -70.989],
  [0.656, -51.822],
  [0.672, -53.642],
];
const List<List<double>> itoAgeLinearFemale = [
  [0.377, -22.75],
  [0.458, -32.079],
  [0.508, -38.367],
  [0.561, -45.006],
  [0.652, -56.992],
  [0.73, -68.091],
  [0.803, -78.846],
  [0.796, -76.934],
  [0.655, -54.234],
  [0.594, -43.264],
  [0.56, -37.002],
  [0.578, -39.057],
  [0.598, -42.339],
];
