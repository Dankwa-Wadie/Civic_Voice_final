import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../../data/models/incident_report.dart';
import '../../../../../domain/enums/incident_category.dart';
import '../../../../../domain/enums/incident_status.dart';

class ReportsTableTab extends StatefulWidget {
  const ReportsTableTab({super.key});

  @override
  State<ReportsTableTab> createState() => _ReportsTableTabState();
}

class _ReportsTableTabState extends State<ReportsTableTab> {
  static const int _rowsPerPage = 12;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardViewModel>(
      builder: (context, vm, _) {
        final reports = vm.filteredReports;
        final startIdx = _currentPage * _rowsPerPage;
        final endIdx = (startIdx + _rowsPerPage).clamp(0, reports.length);
        final pageReports = reports.sublist(
          startIdx.clamp(0, reports.length),
          endIdx,
        );
        final totalPages =
            (reports.length / _rowsPerPage).ceil().clamp(1, double.infinity).toInt();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Filter bar ───────────────────────────────────────────────
            _FilterBar(
              vm: vm,
              onFilterChanged: () => setState(() => _currentPage = 0),
            ),
            // ── Table header row ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.lg,
                vertical: AppTheme.sm,
              ),
              child: Row(
                children: [
                  Text(
                    '${reports.length} report${reports.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                    ),
                  ),
                  if (vm.hasActiveFilters) ...[
                    const SizedBox(width: AppTheme.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: AppTheme.radiusChip,
                      ),
                      child: Text(
                        'Filtered',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ── Data View (Responsive Layout) ────────────────────────────
            Expanded(
              child: reports.isEmpty
                  ? _EmptyTableState(hasFilters: vm.hasActiveFilters, onClear: vm.clearFilters)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 700) {
                          return _buildMobileList(context, vm, pageReports, startIdx);
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
                          child: DataTable2(
                            columnSpacing: AppTheme.md,
                            horizontalMargin: AppTheme.md,
                            headingRowHeight: 44,
                            dataRowHeight: 60,
                            dividerThickness: 0.5,
                            headingRowColor: WidgetStatePropertyAll(
                              AppTheme.surfaceVariant,
                            ),
                            dataRowColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return AppTheme.primary.withOpacity(0.05);
                              }
                              return Colors.transparent;
                            }),
                            border: TableBorder.all(
                              color: AppTheme.divider,
                              borderRadius: AppTheme.radiusCard,
                            ),
                            sortColumnIndex: vm.sortColumnIndex,
                            sortAscending: vm.sortAscending,
                            columns: [
                              _col('#', fixedWidth: 48),
                              _col('District', onSort: (i, a) => vm.setSort(1, a)),
                              _col('Category', onSort: (i, a) => vm.setSort(2, a)),
                              _col('Title', onSort: (i, a) => vm.setSort(3, a)),
                              _col('Status', onSort: (i, a) => vm.setSort(4, a)),
                              _col('Reporter', onSort: (i, a) => vm.setSort(5, a)),
                              _col('Date', onSort: (i, a) => vm.setSort(6, a)),
                              _col('Action', fixedWidth: 140),
                            ],
                            rows: pageReports.asMap().entries.map((entry) {
                              final idx = startIdx + entry.key + 1;
                              final report = entry.value;
                              return _buildRow(context, vm, idx, report);
                            }).toList(),
                          ),
                        );
                      },
                    ),
            ),
            // ── Pagination ───────────────────────────────────────────────
            if (reports.isNotEmpty)
              _PaginationBar(
                currentPage: _currentPage,
                totalPages: totalPages,
                totalItems: reports.length,
                rowsPerPage: _rowsPerPage,
                onPageChanged: (p) => setState(() => _currentPage = p),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMobileList(
    BuildContext context,
    DashboardViewModel vm,
    List<IncidentReport> pageReports,
    int startIdx,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
      itemCount: pageReports.length,
      itemBuilder: (context, index) {
        final report = pageReports[index];
        final isUpdating = vm.updatingId == report.id;
        final dateStr = DateFormat('MMM d, y · HH:mm').format(report.timestamp);
        final nextStatuses = report.status.nextStatuses;
        final globalIdx = startIdx + index + 1;

        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.md),
          color: AppTheme.surface,
          child: ExpansionTile(
            key: PageStorageKey<String>(report.id),
            leading: Container(
              padding: const EdgeInsets.all(AppTheme.sm),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: AppTheme.radiusButton,
              ),
              child: Text(
                '#$globalIdx',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ),
            title: Text(
              report.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppTheme.xs),
              child: Wrap(
                spacing: AppTheme.xs,
                runSpacing: AppTheme.xs,
                children: [
                  CategoryBadge(category: report.category),
                  StatusBadge(status: report.status),
                ],
              ),
            ),
            childrenPadding: const EdgeInsets.all(AppTheme.md),
            expandedAlignment: Alignment.topLeft,
            shape: Border.all(color: Colors.transparent),
            collapsedShape: Border.all(color: Colors.transparent),
            children: [
              Text(
                'DESCRIPTION',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurfaceDim,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppTheme.xs),
              Text(
                report.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.md),
              const Divider(height: 1),
              const SizedBox(height: AppTheme.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(context, 'District', report.district),
                        const SizedBox(height: AppTheme.xs),
                        _buildDetailRow(context, 'Reporter', report.reporterName.startsWith('anonymous:') ? 'Anonymous Citizen' : report.reporterName),
                        const SizedBox(height: AppTheme.xs),
                        _buildDetailRow(context, 'Date', dateStr),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.sm),
                  if (nextStatuses.isNotEmpty)
                    isUpdating
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          )
                        : Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: AppTheme.radiusButton,
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<IncidentStatus>(
                                value: null,
                                hint: const Text(
                                  'Advance',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                dropdownColor: AppTheme.surfaceElevated,
                                items: nextStatuses.map((s) {
                                  return DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      s.displayName,
                                      style: TextStyle(
                                        color: _statusColor(s),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (s) {
                                  if (s != null) vm.updateStatus(report.id, s);
                                },
                              ),
                            ),
                          )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.sm,
                        vertical: AppTheme.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.12),
                        borderRadius: AppTheme.radiusChip,
                        border: Border.all(
                          color: AppTheme.success.withOpacity(0.4),
                        ),
                      ),
                      child: const Text(
                        'Closed',
                        style: TextStyle(
                          color: AppTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  DataColumn2 _col(
    String label, {
    DataColumnSortCallback? onSort,
    double? fixedWidth,
  }) {
    return DataColumn2(
      fixedWidth: fixedWidth,
      onSort: onSort,
      label: Text(
        label,
        style: const TextStyle(
          color: AppTheme.onSurfaceMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  DataRow2 _buildRow(
    BuildContext context,
    DashboardViewModel vm,
    int idx,
    IncidentReport report,
  ) {
    final isUpdating = vm.updatingId == report.id;
    final dateStr =
        DateFormat('MMM d, y').format(report.timestamp);
    final nextStatuses = report.status.nextStatuses;

    return DataRow2(
      cells: [
        DataCell(Text(
          '$idx',
          style: Theme.of(context).textTheme.bodySmall,
        )),
        DataCell(Text(
          report.district,
          style: Theme.of(context).textTheme.bodyMedium,
        )),
        DataCell(
          CategoryBadge(category: report.category),
        ),
        DataCell(
          Tooltip(
            message: report.description,
            child: Text(
              report.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        DataCell(StatusBadge(status: report.status)),
        DataCell(Text(
          report.reporterName.startsWith('anonymous:') ? 'Anonymous Citizen' : report.reporterName,
          style: Theme.of(context).textTheme.bodyMedium,
        )),
        DataCell(Text(
          dateStr,
          style: Theme.of(context).textTheme.bodySmall,
        )),
        DataCell(
          isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                )
              : nextStatuses.isEmpty
                  ? Chip(
                      label: const Text('Closed',
                          style: TextStyle(fontSize: 11)),
                      backgroundColor: AppTheme.success.withOpacity(0.1),
                      side: BorderSide(
                        color: AppTheme.success.withOpacity(0.3),
                      ),
                    )
                  : DropdownButton<IncidentStatus>(
                      value: null,
                      hint: Text(
                        'Advance →',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppTheme.surfaceElevated,
                      items: nextStatuses.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(
                            s.displayName,
                            style: TextStyle(
                              color: _statusColor(s),
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (s) {
                        if (s != null) vm.updateStatus(report.id, s);
                      },
                    ),
        ),
      ],
    );
  }

  Color _statusColor(IncidentStatus s) => switch (s) {
    IncidentStatus.submitted => AppTheme.statusSubmitted,
    IncidentStatus.reviewed => AppTheme.statusReviewed,
    IncidentStatus.dispatched => AppTheme.statusDispatched,
    IncidentStatus.resolved => AppTheme.statusResolved,
  };
}

class _FilterBar extends StatefulWidget {
  const _FilterBar({required this.vm, required this.onFilterChanged});
  final DashboardViewModel vm;
  final VoidCallback onFilterChanged;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Wrap(
        spacing: AppTheme.sm,
        runSpacing: AppTheme.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Search
          SizedBox(
            width: isMobile ? double.infinity : 240,
            height: 48,
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search reports…',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                contentPadding: EdgeInsets.zero,
                isDense: true,
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          vm.setSearchQuery('');
                          widget.onFilterChanged();
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                vm.setSearchQuery(v);
                widget.onFilterChanged();
              },
            ),
          ),
          // Status filter
          _DropdownFilter<IncidentStatus>(
            label: 'Status',
            value: vm.statusFilter,
            items: IncidentStatus.values,
            itemLabel: (s) => s.displayName,
            onChanged: (s) {
              vm.setStatusFilter(s);
              widget.onFilterChanged();
            },
          ),
          // Category filter
          _DropdownFilter<IncidentCategory>(
            label: 'Category',
            value: vm.categoryFilter,
            items: IncidentCategory.values,
            itemLabel: (c) => c.displayName,
            onChanged: (c) {
              vm.setCategoryFilter(c);
              widget.onFilterChanged();
            },
          ),
          // District filter
          _DropdownFilter<String>(
            label: 'District',
            value: vm.districtFilter,
            items: vm.availableDistricts,
            itemLabel: (d) => d,
            onChanged: (d) {
              vm.setDistrictFilter(d);
              widget.onFilterChanged();
            },
          ),
          // Clear
          if (vm.hasActiveFilters)
            TextButton.icon(
              onPressed: () {
                _searchCtrl.clear();
                vm.clearFilters();
                widget.onFilterChanged();
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm),
      decoration: BoxDecoration(
        color: value != null
            ? AppTheme.primary.withOpacity(0.1)
            : AppTheme.surfaceVariant,
        borderRadius: AppTheme.radiusButton,
        border: Border.all(
          color: value != null ? AppTheme.primary : AppTheme.divider,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          hint: Text(
            label,
            style: const TextStyle(
              color: AppTheme.onSurfaceMuted,
              fontSize: 13,
            ),
          ),
          dropdownColor: AppTheme.surfaceElevated,
          style: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.onSurfaceDim,
            size: 18,
          ),
          items: [
            DropdownMenuItem<T?>(
              value: null,
              child: Text('All $label', style: const TextStyle(fontSize: 13)),
            ),
            ...items.map((item) => DropdownMenuItem<T?>(
                  value: item,
                  child: Text(itemLabel(item), style: const TextStyle(fontSize: 13)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.rowsPerPage,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int rowsPerPage;
  final void Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = currentPage * rowsPerPage + 1;
    final end = ((currentPage + 1) * rowsPerPage).clamp(0, totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.lg,
        vertical: AppTheme.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $start–$end of $totalItems',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: currentPage > 0
                    ? () => onPageChanged(currentPage - 1)
                    : null,
                iconSize: 20,
                color: AppTheme.onSurfaceMuted,
                disabledColor: AppTheme.onSurfaceDim,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm),
                child: Text(
                  '${currentPage + 1} of $totalPages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChanged(currentPage + 1)
                    : null,
                iconSize: 20,
                color: AppTheme.onSurfaceMuted,
                disabledColor: AppTheme.onSurfaceDim,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState({
    required this.hasFilters,
    required this.onClear,
  });
  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters
                ? Icons.filter_alt_off_outlined
                : Icons.inbox_outlined,
            size: 48,
            color: AppTheme.onSurfaceDim,
          ),
          const SizedBox(height: AppTheme.md),
          Text(
            hasFilters ? 'No reports match filters' : 'No reports yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (hasFilters) ...[
            const SizedBox(height: AppTheme.sm),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear all filters'),
            ),
          ],
        ],
      ),
    );
  }
}
