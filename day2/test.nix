/* nix-instantiate --eval */
with import <nixpkgs> { };
with pkgs.lib;

let
  sum = lists.foldr (a: b: a + b) 0;
  mul = a: b: a * b;
  id = a: a;
  notEmpty = s: s != "";
in
let
  nullDepth = aim: depth: depth;
  calDepth = fw: aim: depth: (fw * aim) + depth;

  /* list of horizontal of aim of depth  */
  rowToList = { cmd, val }:
    if cmd == "forward" then
      [ (add val) id (calDepth val) ]
    else if cmd == "down" then
      [ id (add val) nullDepth ]
    else
      [ id (add (-val)) nullDepth ];

  combine = (val: fx: [
    ((elemAt fx 0) (elemAt val 0))
    ((elemAt fx 1) (elemAt val 1))
    ((elemAt fx 2) (elemAt val 1) (elemAt val 2))
  ]);

  rowsToLists = map rowToList;
  listsToPos = lists.foldl combine [ 0 0 0 ];
  posToAns = pos: mul (elemAt pos 0) (elemAt pos 2);

  rawInput = builtins.readFile ./input.txt;
  parseLine = line: with strings;
    let a = (splitString " " line); in
    { cmd = (elemAt a 0); val = (toInt (elemAt a 1)); };

  rows = with strings;
    (map parseLine
      (filter notEmpty
        (splitString "\n" rawInput)));

  solve = rows: (posToAns (listsToPos (rowsToLists rows)));
in
(solve rows)
