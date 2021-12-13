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
  parseRow = line:
    pipe line [ (splitString "") (filter nonEmpty) ];

  rawInput = builtins.readFile ./input.txt;
  rows = pipe rawInput [ (splitString "\n") (filter nonEmpty) (map parseRow) ];
in
let
  pair = {
    "(" = ")";
    "{" = "}";
    "[" = "]";
    "<" = ">";
  };

  computeCorrectness = foldl
    (acc: char:
      if hasAttr char pair then
        acc // { stack = [ pair.${char} ] ++ acc.stack; }
      else if char == head acc.stack then
        acc // { stack = tail acc.stack; }
      else
        acc // { errors = acc.errors ++ [ char ]; }
    )
    { stack = [ ]; errors = [ ]; };

  byCorrectness = row@{ errors, stack, ... }: errors == [ ];

  errorScore = { errors, ... }: {
    ")" = 3;
    "]" = 57;
    "}" = 1197;
    ">" = 25137;
  }.${head errors};

  parenthesisScore = {
    ")" = 1;
    "]" = 2;
    "}" = 3;
    ">" = 4;
  };

  score = { stack, ... }: foldl (acc: char: acc * 5 + parenthesisScore.${char}) 0 stack;
  median = records: elemAt (sort (a: b: a < b) records) ((length records) / 2);

  computed = map computeCorrectness rows;
  partitioned = partition byCorrectness computed;

  solve1 = pipe partitioned.wrong [ (map errorScore) sum ];
  solve2 = pipe partitioned.right [ (map score) median ];
in
[ solve1 solve2 ] 
