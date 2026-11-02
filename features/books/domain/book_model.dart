class BookModel {
  const BookModel({
    required this.id,
    required this.instituteId,
    required this.title,
    this.bookCode = '',
    this.isbn = '',
    this.subject = 'General',
    this.classroomId,
    this.grade = 'All',
    this.price = 0.0,
    this.stockQuantity = 0,
    this.author = '',
    this.publisher = '',
    this.edition = '',
    this.description = '',
    this.status = 'In Stock',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String instituteId;
  final String title;
  final String bookCode;
  final String isbn;
  final String subject;
  final String? classroomId;
  final String grade;
  final double price;
  final int stockQuantity;
  final String author;
  final String publisher;
  final String edition;
  final String description;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get totalValue => price * stockQuantity;

  bool get isOutOfStock => stockQuantity <= 0 || status == 'Out of Stock';
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5 || status == 'Low Stock';
  bool get isInStock => stockQuantity > 5;

  factory BookModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is DateTime) return d;
      return DateTime.tryParse(d.toString());
    }

    final rawPrice = json['price'];
    final double parsedPrice = (rawPrice is num)
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;

    final rawQty = json['stockQuantity'] ?? json['quantity'] ?? json['stock'];
    final int parsedQty = (rawQty is num)
        ? rawQty.toInt()
        : int.tryParse(rawQty?.toString() ?? '0') ?? 0;

    return BookModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      instituteId: json['instituteId']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Untitled Book',
      bookCode: json['bookCode']?.toString() ?? json['code']?.toString() ?? '',
      isbn: json['isbn']?.toString() ?? '',
      subject: json['subject']?.toString() ?? json['category']?.toString() ?? 'General',
      classroomId: json['classroomId']?.toString(),
      grade: json['grade']?.toString() ?? json['classroom']?.toString() ?? 'All',
      price: parsedPrice,
      stockQuantity: parsedQty,
      author: json['author']?.toString() ?? '',
      publisher: json['publisher']?.toString() ?? '',
      edition: json['edition']?.toString() ?? '',
      description: json['description']?.toString() ?? json['remarks']?.toString() ?? '',
      status: json['status']?.toString() ?? (parsedQty <= 0 ? 'Out of Stock' : (parsedQty <= 5 ? 'Low Stock' : 'In Stock')),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'instituteId': instituteId,
        'title': title,
        'bookCode': bookCode,
        'isbn': isbn,
        'subject': subject,
        if (classroomId != null && classroomId!.isNotEmpty) 'classroomId': classroomId,
        'grade': grade,
        'price': price,
        'stockQuantity': stockQuantity,
        'author': author,
        'publisher': publisher,
        'edition': edition,
        'description': description,
        'status': status,
      };

  BookModel copyWith({
    String? id,
    String? instituteId,
    String? title,
    String? bookCode,
    String? isbn,
    String? subject,
    String? classroomId,
    String? grade,
    double? price,
    int? stockQuantity,
    String? author,
    String? publisher,
    String? edition,
    String? description,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      instituteId: instituteId ?? this.instituteId,
      title: title ?? this.title,
      bookCode: bookCode ?? this.bookCode,
      isbn: isbn ?? this.isbn,
      subject: subject ?? this.subject,
      classroomId: classroomId ?? this.classroomId,
      grade: grade ?? this.grade,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      edition: edition ?? this.edition,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
