import 'package:json_annotation/json_annotation.dart';
import 'package:library_distributed_app/core/constants/enums.dart';

part 'borrow_record_with_details.g.dart';

@JsonSerializable(includeIfNull: false)
class BorrowRecordWithDetailsModel {
  @JsonKey(name: 'maPM')
  final int borrowId;
  
  @JsonKey(name: 'bookIsbn')
  final String bookIsbn;
  
  @JsonKey(name: 'bookTitle')
  final String bookTitle;
  
  @JsonKey(name: 'bookAuthor')
  final String bookAuthor;
  
  @JsonKey(name: 'readerId')
  final String readerId;
  
  @JsonKey(name: 'readerName')
  final String readerName;
  
  @JsonKey(name: 'borrowDate')
  final String borrowDate;
  
  @JsonKey(name: 'dueDate')
  final String dueDate;
  
  @JsonKey(name: 'returnDate')
  final String? returnDate;
  
  final BorrowStatus status;
  
  @JsonKey(name: 'daysOverdue')
  final int daysOverdue;
  
  @JsonKey(name: 'bookCopyId')
  final String bookCopyId;
  
  final Site branch;

  const BorrowRecordWithDetailsModel({
    required this.borrowId,
    required this.bookIsbn,
    required this.bookTitle,
    required this.bookAuthor,
    required this.readerId,
    required this.readerName,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    this.daysOverdue = 0,
    required this.bookCopyId,
    required this.branch,
  });

  factory BorrowRecordWithDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$BorrowRecordWithDetailsModelFromJson(json);

  Map<String, dynamic> toJson() => _$BorrowRecordWithDetailsModelToJson(this);

  @override
  String toString() {
    return '$runtimeType: {borrowId: $borrowId, bookTitle: $bookTitle, readerName: $readerName, status: ${status.text}}';
  }
}