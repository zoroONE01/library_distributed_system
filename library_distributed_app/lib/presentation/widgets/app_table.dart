import 'package:flutter/cupertino.dart';
import 'package:library_distributed_app/core/extensions/text_style_extension.dart';
import 'package:library_distributed_app/core/extensions/theme_extension.dart';

class AppTable {
  const AppTable._();

  static Table build(
    BuildContext context, {
    List<TableRow> rows = const [],
    List<String> titles = const [],
    List<double> columnWidths = const [],
  }) {
    return Table(
      border: TableBorder.all(
        color: context.colorScheme.outline.withValues(alpha: 0.4),
        width: 1,
        borderRadius: BorderRadius.circular(8),
      ),
      columnWidths: {
        for (int i = 0; i < columnWidths.length; i++)
          i: FlexColumnWidth(columnWidths[i].toDouble()),
      },
      children: [
        if (titles.isNotEmpty) buildHeader(context, titles: titles),
        if (rows.isNotEmpty) ...rows,
      ],
    );
  }

  static TableRow buildHeader(
    BuildContext context, {
    List<String> titles = const [],
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: context.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      children: titles.map((title) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: context.bodyLarge.bold,
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  static TableCell buildTextCell(BuildContext context, {required String text}) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          style: context.bodyLarge.bold,
          textAlign: TextAlign.start,
        ),
      ),
    );
  }

  static TableCell buildWidgetCell(
    BuildContext context, {
    required Widget child,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(padding: const EdgeInsets.all(8.0), child: child),
    );
  }
}
