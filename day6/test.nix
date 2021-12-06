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
in
let

  rawInput = builtins.readFile ./input.txt;
  input = pipe rawInput [ (splitString ",") (filter nonEmpty) (map toInt) ];
  state = {
    timer = pipe (range 0 6) [ (map (i: (count (eq(i)) input))) ];
    breed = [ 0 0 ];
  };
in
let
  step = state:
    let 
        newBorn = head state.timer;
        tailTimer = [(newBorn + head state.breed)];
    in {
        timer = tail state.timer ++ tailTimer;
        breed = tail state.breed ++ [newBorn];
    };
 
  finalState = foldl (state: day: step state) state (range 1 80);
  solve1 = sum finalState.breed + sum finalState.timer;

  finalState2 = foldl (state: day: step state) state (range 1 256);
  solve2 = sum finalState2.breed + sum finalState2.timer;
in
[ solve1 solve2 ]
