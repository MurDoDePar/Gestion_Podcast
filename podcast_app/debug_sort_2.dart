void main() {
  var l = [DateTime(2025), DateTime(2021)];

  l.sort((a, b) {
    int cmp = a.compareTo(b);
    // a=2025, b=2021. cmp = 1
    // asc logic with -cmp:
    return -cmp; // returns -1. So a (2025) is put BEFORE b (2021).
  });
  print(l); // Expected: [2025, 2021]
}
