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
  toStr = list: replaceStrings [ " " ] [ "" ] (toString list);
  parsePart = raw: pipe raw [ (splitString " ") (filter nonEmpty) (map stringToCharacters) (map naturalSort) (map toStr) ];
  parseRow = line:
    let parts = pipe line [ (splitString "|") (filter nonEmpty) ]; in
    { blueprints = parsePart (elemAt parts 0); digits = parsePart (elemAt parts 1); };

  rawInput = builtins.readFile ./input.txt;
  rows = pipe rawInput [ (splitString "\n") (filter nonEmpty) (map parseRow) ];
in
let
  find = pred: findSingle pred false "dup";
  lenIs = len: text: stringLength text == len;
  and = f: g: text: f text && g text;
  contain = hay: needle: length (intersectLists (stringToCharacters hay) (stringToCharacters needle)) == stringLength hay;
  notContain = hay: needle: !(contain hay needle);
  subtract = a: b: toStr (subtractLists (stringToCharacters b) (stringToCharacters a));
  indexOf = list: str: if list == [ ] then throw "Not found" else if head list == str then 0 else 1 + indexOf (tail list) str;

  solve = { blueprints, digits }:
    let
      m = rec {
        one = find (lenIs 2) blueprints;
        four = find (lenIs 4) blueprints;
        seven = find (lenIs 3) blueprints;
        eight = find (lenIs 7) blueprints;
        three = find (and (lenIs 5) (contain seven)) blueprints;
        nine = find (and (lenIs 6) (contain three)) blueprints;
        six = find (and (lenIs 6) (and (contain (subtract three one)) (notContain nine))) blueprints;
        zero = find (and (lenIs 6) (and (notContain nine) (notContain six))) blueprints;
        two = find (and (lenIs 5) (contain (subtract eight nine))) blueprints;
        five = find (and (lenIs 5) (and (notContain two) (notContain three))) blueprints;
      };
      seq = with m; [ zero one two three four five six seven eight nine ];
    in
    map (indexOf seq) digits;


  answers = map solve rows;
  solve1 = count (a: a == 1 || a == 4 || a == 7 || a == 8) (flatten answers);

  listToInt = foldl (acc: num: acc * 10 + num) 0;
  solve2 = sum (map listToInt answers);
in
[ solve1 solve2 ]
