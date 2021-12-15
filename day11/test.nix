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
  directions = [{ y = 1; x = 0; } { y = -1; x = 0; } { y = 0; x = 1; } { y = 0; x = -1; } { y = -1; x = -1; } { y = 1; x = 1; } { y = 1; x = -1; } { y = -1; x = 1; }];
  add = c1: c2: { y = c1.y + c2.y; x = c1.x + c2.x; };
  locate = { y, x }: "${toString y} ${toString x}";
  energy = state: c: state.${locate c};
  flashed = state: c: hasAttr (locate c) state;
  flash = state: c: state // { ${locate c} = true; };

  surround = coord: pipe directions [
    (map (add coord))
    (filter ({ y, x }: y >= 0 && x >= 0 && y < N && x < M))
  ];
  incr = val: mapAttrs (name: value: value + val);

  initial = foldl (state: c: state // { ${locate c} = (elemAt (elemAt rows c.y) c.x); }) { } coords;

  step = state:
    let conclude = state: visited:
      let
        isStable = coord: energy state coord < 10 || flashed visited coord;
        simplify = mapAttrs (name: value: if value >= 10 then 0 else value);
        unstable = filter (c: !(isStable c)) coords;
        incrNeighbour = state: c:
          foldl (s: neighbour: s // { ${locate neighbour} = (energy s neighbour) + 1; }) state (surround c);

      in

      if unstable == [ ] then
        { state = simplify state; total = count (c: energy state c >= 10) coords; }
      else
        let
          result = foldl
            (acc: c: {
              visited = flash acc.visited c;
              state = incrNeighbour acc.state c;
            })
            { visited = visited; state = state; }
            unstable;
        in
        conclude result.state result.visited;
    in
    conclude (incr 1 state) { };

  solve1 = foldl
    ({ state, total }: iteration:
      let result = step state; in
      { state = result.state; total = total + result.total; }
    )
    { state = initial; total = 0; }
    (range 1 100);

  countStep = state:
    let nextState = (step state).state; in
    if all (coord: energy nextState coord == 0) coords then
      1
    else
      1 + countStep nextState;

  solve2 = countStep initial;
in
[ solve1.total solve2 ] 
