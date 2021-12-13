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
    pipe line [ (splitString "") (filter nonEmpty) (map toInt) ];

  rawInput = builtins.readFile ./input.txt;
  rows = pipe rawInput [ (splitString "\n") (filter nonEmpty) (map parseRow) ];
  N = length rows;
  M = length (head rows);
in
let
  coords = cartesianProductOfSets { y = range 0 (N - 1); x = range 0 (M - 1); };
  directions = [{ y = 1; x = 0; } { y = -1; x = 0; } { y = 0; x = 1; } { y = 0; x = -1; }];
  add = c1: c2: { y = c1.y + c2.y; x = c1.x + c2.x; };
  height = { y, x }: (elemAt (elemAt rows y) x);
  isLower = c1: c2: height c1 < height c2;

  surround = coord: pipe directions [
    (map (add coord))
    (filter ({ y, x }: y >= 0 && x >= 0 && y < N && x < M))
  ];
  lowestPoints = pipe coords [ (filter (coord: all (isLower coord) (surround coord))) ];
  solve1 = length lowestPoints + sum (map height lowestPoints);

  coordinateToString = { y, x }: "${toString y} ${toString x}";
  mark = c: state: state // { "${coordinateToString c}" = true; };
  marked = c: state: hasAttr (coordinateToString c) state;

  findBasin = q: result:
    let queue = pipe q [ (filter (c: height c != 9)) (filter (c: !(marked c result.state))) ]; in

    if queue == [ ] then
      result
    else
      let n = foldl
        (current@{ result, nextQueue }: c:
          if marked c result.state then
            current
          else
            {
              result = { state = mark c result.state; score = result.score + 1; };
              nextQueue = nextQueue ++ (surround c);
            }
        )
        { result = result; nextQueue = [ ]; }
        queue;
      in
      findBasin n.nextQueue n.result;

  base = { state = { }; scores = [ ]; };
  basins = foldl
    (acc: c:
      if marked c acc.state then
        acc
      else
        let result = findBasin [ c ] { state = acc.state; score = 0; }; in
        { state = result.state; scores = acc.scores ++ [ result.score ]; }
    )
    base
    lowestPoints;
  solve2 = pipe basins.scores [ (sort (a: b: a > b)) (take 3) (foldl (acc: score: acc * score) 1) ];
in
[ solve1 solve2 ] 
