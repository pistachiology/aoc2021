/* nix-instantiate --eval */
with import <nixpkgs> { };
with pkgs.lib;

let
  sum = lists.foldr (a: b: a + b) 0;
  mul = a: b: a * b;
  eq = a: b: a == b;
  id = a: a;
  nonEmpty = s: s != "";
  bitsToInt = lists.foldl (acc: d: d + acc * 2) 0;
  abs = a: if a < 0 then -a else a;
in
let
  rawInput = builtins.readFile ./input.txt;
  input = pipe rawInput [ (splitString ",") (filter nonEmpty) (map toInt) (sort (a: b: a < b)) ];
in
let
  mid = (length input) / 2;
  median = elemAt input mid;
  solve1 = foldl (acc: a: acc + (abs (a - median))) 0 input;

  /* We don't have rounding so just compute all :) */
  avgFloor = sum input / length input;
  avgCeil = avgFloor + 1;
  stepCost = a: (a * (a + 1)) / 2;
  cost = avg: foldl (acc: a: acc + (stepCost (abs (a - avg)))) 0 input;
  solve2 = min (cost avgFloor) (cost avgCeil);
in
[ solve1 solve2 ]
