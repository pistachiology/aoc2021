/* nix-instantiate --eval */
with import <nixpkgs> { };
with pkgs.lib;

let
  sum = lists.foldr (a: b: a + b) 0;
  mul = a: b: a * b;
  id = a: a;
  notEmpty = s: s != "";
  bitsToInt = lists.foldl (acc: d: d + acc * 2) 0;
in
let
  rawInput = builtins.readFile ./input.txt;
  parseLine = line: with strings;
    map toInt (stringToCharacters line);
  rows = with strings;
    pipe rawInput [ (splitString "\n") (filter notEmpty) (map parseLine) ];
in
let
  diff = lists.foldl (acc: cur: acc + (if cur == 1 then 1 else -1)) 0;
  gte = num: l: if l >= num then 1 else 0;
  le = num: l: if l < num then 1 else 0;

  headVal = record: head record.val;
  toRecord = r: { state = r; val = r; };

  calPower = cmp: digitsList:
    if (elemAt digitsList 0) == [ ] then
      [ ]
    else
      [ (pipe digitsList [ (map head) diff cmp ]) ] ++ (calPower cmp (map tail digitsList));
  calGamma = calPower (gte 0);
  calElipson = calPower (le 0);

  calRating = cmp: records:
    if (length records) == 1 then
      (head records).state
    else
      let
        digit = pipe records [ (map headVal) diff cmp ];
        rest = pipe records [
          (filter (record: (headVal record) == digit))
          (map (record: { state = record.state; val = tail record.val; }))
        ];
      in
      calRating cmp rest;
  calOxygen = calRating (gte 0);
  calCo2 = calRating (le 0);

  solve1 = rows:
    let
      g = calGamma rows;
      e = calElipson rows;
    in
    (bitsToInt g) * (bitsToInt e);

  solve2 = rows:
    let
      records = (map toRecord rows);
      ox = calOxygen records;
      co2 = calCo2 records;
    in
    (bitsToInt ox) * (bitsToInt co2);

in
[ (solve1 rows) (solve2 rows) ]
