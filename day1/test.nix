/* nix-instantiate --eval */
with import <nixpkgs> { };

let lib = pkgs.lib; in
let lists = lib.lists; in
let strings = lib.strings; in
let sum = lists.foldr (a: b: a + b) 0; in

let

  windows = with pkgs.lib.lists; input:
    if length input <= 2 then
      [ ]
    else
      [ (sum (take 3 input)) ] ++ (windows (tail input));

  solve = with pkgs.lib.lists; input:
    if length input <= 1 then
      0
    else
      (if (elemAt input 1) > (elemAt input 0) then 1 else 0) + (solve (tail input));

  rawInput = builtins.readFile ./input.txt;
  notEmpty = s: s != "";

  input = with strings;
    (map toInt
      (filter notEmpty
        (splitString "\n" rawInput)));

  result1 = solve input;
  result2 = solve (windows input);
in
[ result1 result2 ]
