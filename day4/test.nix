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
  readBoards = lines:
    if lines == [ ] then [ ]
    else [ (readBoard (take 5 lines)) ] ++ (readBoards (drop 5 lines));

  readBoard = map readBoardRow;
  readBoardRow = line: pipe line [ (splitString " ") (filter nonEmpty) (map toInt) ];
  toRecord = board: { inherit board; };
  toRecords = map toRecord;

  rawInput = builtins.readFile ./input.txt;
  lines = pipe rawInput [ (splitString "\n") (filter nonEmpty) ];

  actions = pipe (head lines) [ (splitString ",") (map toInt) unique ];
  records = pipe (tail lines) [ readBoards toRecords ];
in
let
  check = { board }:
    let
      checkRow = any (row: all (eq (-1)) row);
      checkCol = board:
        if (elemAt board 1) == [ ] then
          false
        else
          (all (eq (-1)) (map head board)) || (checkCol (map tail board));
    in
    (checkRow board) || (checkCol board);

  step = action: { board }:
    let stepRow = map (el: if el == action then -1 else el);
    in { board = map stepRow board; };

  getScore = action: { board }:
    (foldl (a: b: a + (if b == -1 then 0 else b)) 0 (flatten board)) * action;

  play1 = action: records:
    let
      nextRecords = map (step action) records;
      winner = findFirst check false nextRecords;
    in
    if winner != false then
      { inherit winner; records = nextRecords; done = true; }
    else
      { records = nextRecords; done = false; };

  play2 = action: records:
    let
      nextRecords = map (step action) records;
      left = filter (r: !(check r)) nextRecords;
    in
    if left == [ ] then
      if length nextRecords != 1 then
        throw "Multiple winners exist"
      else
        { winner = head nextRecords; records = left; done = true; }
    else
      { records = left; done = false; };

  solve = play: actions: records:
    if actions == [ ] then
      throw "The winner doesn't exists"
    else
      let
        result = play (head actions) records;
      in
      if result.done then
        getScore (head actions) result.winner
      else
        solve play (tail actions) result.records;

in
[ (solve play1 actions records) (solve play2 actions records) ]
