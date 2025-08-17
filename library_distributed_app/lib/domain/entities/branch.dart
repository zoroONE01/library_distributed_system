import 'package:library_distributed_app/core/constants/enums.dart';

class BranchEntity {
  final Site siteId;
  final String name;
  final String address;

  const BranchEntity({
    required this.siteId,
    required this.name,
    required this.address,
  });
}