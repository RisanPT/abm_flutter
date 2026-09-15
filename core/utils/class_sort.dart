/// Orders class names the way a school register reads — pre-primary first
/// (Pre-KG, Nursery, LKG, UKG), then numbered standards in NUMERIC order
/// (Class 2 before Class 10), then anything else alphabetically.
///
/// A plain alphabetical sort pushed "UKG" near the bottom and ordered
/// "Class 10" before "Class 2"; this fixes both, so UKG shows at the top.
int classSortRank(String name) {
  final n = name.toLowerCase().replaceAll(RegExp(r'[\s._-]'), '');
  if (n.contains('prekg') || n.contains('playgroup') || n == 'pg') return 0;
  if (n.contains('nursery')) return 1;
  if (n.contains('lkg') || n.contains('kg1')) return 2;
  if (n.contains('ukg') || n.contains('kg2')) return 3;
  if (n.contains('kg')) return 4;
  final m = RegExp(r'\d+').firstMatch(name);
  if (m != null) return 100 + int.parse(m.group(0)!);
  return 900;
}

int compareClassNames(String a, String b) {
  final ra = classSortRank(a), rb = classSortRank(b);
  if (ra != rb) return ra.compareTo(rb);
  return a.toLowerCase().compareTo(b.toLowerCase());
}

/// Sort a list of class-name strings in register order.
List<String> sortClassNames(Iterable<String> names) {
  final list = names.toList()..sort(compareClassNames);
  return list;
}

/// Sort any objects that carry a class name (e.g. ClassroomModel) in register order.
List<T> sortByClassName<T>(Iterable<T> items, String Function(T) nameOf) {
  final list = items.toList()..sort((a, b) => compareClassNames(nameOf(a), nameOf(b)));
  return list;
}
