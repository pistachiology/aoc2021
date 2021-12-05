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
  input = pipe rawInput [ (splitString "\n") (filter nonEmpty) ];
  parseLine = line:
    pipe line [ (splitString " -> ") (filter nonEmpty) ];
  parseEl = l: { x = toInt (elemAt l 0); y = toInt (elemAt l 1); };
  parseEls = l: { from = parseEl (elemAt l 0); to = parseEl (elemAt l 1); };

  lines = pipe input [ (map parseLine) (map (map (splitString ","))) (map parseEls) ];
in
let
  l = groupBy
    ({ from, to }:
      if from.x == to.x then
        "verticals"
      else if from.y == to.y then
        "horizontals"
      else
        "diagonals")
    lines;
  horizontals = map ({ from, to }: { from = from // { x = min from.x to.x; }; to = to // { x = max from.x to.x; }; }) l.horizontals;
  verticals = map ({ from, to }: { from = from // { y = min from.y to.y; }; to = to // { y = max from.y to.y; }; }) l.verticals;
  diagonals = map
    ({ from, to }: if from.y > to.y then { from = to; to = from; } else { inherit from to; })
    l.diagonals;


  /* Part 1 */
  cross = v: h:
    if (h.from.x <= v.from.x && v.from.x <= h.to.x) && (v.from.y <= h.from.y && h.from.y <= v.to.y) then
      [{ x = v.from.x; y = h.from.y; }]
    else
      [ ];

  horizontalOverlap = l1: l2:
    if l1.from.y == l2.from.y then
      pipe (range (max l1.from.x l2.from.x) (min l1.to.x l2.to.x)) [ (map (a: { y = l1.from.y; x = a; })) ]
    else
      [ ];

  verticalOverlap = l1: l2:
    if l1.from.x == l2.from.x then
      pipe (range (max l1.from.y l2.from.y) (min l1.to.y l2.to.y)) [ (map (a: { x = l1.from.x; y = a; })) ]
    else
      [ ];

  apply = h: foldl (acc: v: acc ++ (cross v h)) [ ];
  result = (foldl (acc: h: acc ++ (apply h verticals)) [ ] horizontals)
    ++ (sameAxisCheck horizontalOverlap horizontals)
    ++ (sameAxisCheck verticalOverlap verticals);
  solve1 = unique result;

  /* Part 2 */
  /* We just reuse part 1 and add diagonal to extra calculation */
  slope = l: (l.to.y - l.from.y) / (l.to.x - l.from.x);
  getPoint = diag: line:
    if slope diag == 1 then
      if line.from.x == line.to.x then
        let y = diag.from.y + (line.to.x - diag.from.x); in
        if line.from.y <= y && y <= line.to.y && diag.from.y <= y && y <= diag.to.y then
          [{ inherit y; x = line.to.x; }]
        else
          [ ]
      else if line.from.y == line.to.y then
        let x = diag.from.x + (line.to.y - diag.from.y); in
        if line.from.x <= x && x <= line.to.x && diag.from.x <= x && x <= diag.to.x then
          [{ inherit x; y = line.to.y; }]
        else
          [ ]
      else throw "line should be horizontal or vertical"
    else
      if line.from.x == line.to.x then
        let y = diag.from.y - (line.to.x - diag.from.x); in
        if line.from.y <= y && y <= line.to.y && diag.from.y <= y && y <= diag.to.y then
          [{ inherit y; x = line.to.x; }]
        else
          [ ]
      else if line.from.y == line.to.y then
        let x = diag.from.x - (line.to.y - diag.from.y); in
        if line.from.x <= x && x <= line.to.x && diag.to.x <= x && x <= diag.from.x then
          [{ inherit x; y = line.to.y; }]
        else
          [ ]
      else
        throw "line should be horizontal or vertical";

  /* Maxbe we should've just draw the matrix or split anti-diagonal and diagonal since code is over complicate for such a simple task :( */
  diagonalOverlap = l1: l2:
    if slope l1 != slope l2 then
      let
        diag = if slope l1 == 1 then l1 else l2;
        antidiag = if slope l1 == -1 then l1 else l2;
        c1 = diag.from.y - diag.from.x;
        c2 = antidiag.from.y + antidiag.from.x;
        x = (c2 - c1) / 2;
        y = x + c1;
      in
      if mod (c2 - c1) 2 == 0 && diag.from.y <= y && y <= diag.to.y && antidiag.from.y <= y && y <= antidiag.to.y then
        [{ inherit x y; }]
      else
        [ ]
    else if slope l1 == 1 && l1.from.x + (l2.from.y - l1.from.y) == l2.from.x then
      let
        from = if l1.from.y > l2.from.y then l1.from else l2.from;
        to = if l1.to.y < l2.to.y then l1.to else l2.to;
      in
      pipe (range 0 (to.y - from.y)) [ (map (a: { x = from.x + a; y = from.y + a; })) ]
    else if slope l1 == -1 && l1.from.x - (l2.from.y - l1.from.y) == l2.from.x then
      let
        from = if l1.from.y > l2.from.y then l1.from else l2.from;
        to = if l1.to.y < l2.to.y then l1.to else l2.to;
      in
      pipe (range 0 (to.y - from.y)) [ (map (a: { x = from.x - a; y = from.y + a; })) ]
    else
      [ ];

  sameAxisCheck = check: lines:
    if lines == [ ] then [ ]
    else (foldl (acc: l: acc ++ (check (head lines) l)) [ ] (tail lines)) ++ sameAxisCheck check (tail lines);

  getPoints = line: foldl (acc: d: acc ++ (getPoint d line)) [ ];
  solve2 = unique (
    solve1
    ++ (foldl (acc: line: acc ++ (getPoints line diagonals)) [ ] (horizontals ++ verticals))
    ++ (sameAxisCheck diagonalOverlap diagonals)
  );
in
[ (length solve1) (length solve2) ]
