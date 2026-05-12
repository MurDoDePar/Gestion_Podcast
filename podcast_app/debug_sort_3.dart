void main() {
  var list = [
    {'title': '#14', 'date': DateTime(2025, 1, 1)},
    {'title': '#10', 'date': DateTime(2024, 1, 1)},
    {'title': '#13', 'date': DateTime(2024, 12, 1)},
    {'title': '#11', 'date': DateTime(2024, 6, 1)},
    {'title': '#12', 'date': DateTime(2024, 9, 1)},
  ];

  // order == 'asc'
  list.sort((a, b) {
    int dateComparison =
        (a['date'] as DateTime).compareTo(b['date'] as DateTime);
    return dateComparison; // This is what I have for asc
  });

  print("ASC (return dateComparison):");
  for (var item in list) {
    print(item['title']);
  }

  // order == 'desc'
  list.sort((a, b) {
    int dateComparison =
        (a['date'] as DateTime).compareTo(b['date'] as DateTime);
    return -dateComparison; // This is what I have for desc
  });

  print("\nDESC (return -dateComparison):");
  for (var item in list) {
    print(item['title']);
  }
}
