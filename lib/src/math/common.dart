import 'dart:math';

/// Mathematical constants mapped to their [num] values.
const constants = {'e': e, 'pi': pi};

/// Single-argument mathematical functions mapped to unary evaluation closures.
final functions1 = {
  'acos': acos,
  'asin': asin,
  'atan': atan,
  'cos': cos,
  'exp': exp,
  'log': log,
  'sin': sin,
  'sqrt': sqrt,
  'tan': tan,
  'abs': (num x) => x.abs(),
  'ceil': (num x) => x.ceil(),
  'floor': (num x) => x.floor(),
  'round': (num x) => x.round(),
  'sign': (num x) => x.sign,
  'truncate': (num x) => x.truncate(),
};

/// Two-argument mathematical functions mapped to binary evaluation closures.
final functions2 = {
  'atan2': (num x, num y) => atan2(x, y),
  'max': (num x, num y) => max(x, y),
  'min': (num x, num y) => min(x, y),
  'pow': (num x, num y) => pow(x, y),
};
