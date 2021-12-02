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
      { x = (add val); y = (calDepth val); aim = id; }
    else if cmd == "down" then
      { x = id; y = nullDepth; aim = (add val); }
    else
      { x = id; y = nullDepth; aim = (add (-val)); };

  combine = (val: f: {
    x = (f.x val.x);
    y = (f.y val.aim val.y);
    aim = (f.aim val.aim);
  });

  rowsToLists = map rowToList;
  listsToPos = lists.foldl combine { x = 0; y = 0; aim = 0; };
  posToAns = pos: mul pos.x pos.y;

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
