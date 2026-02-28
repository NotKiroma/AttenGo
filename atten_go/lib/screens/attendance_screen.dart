import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final String jsonString = await rootBundle.loadString('assets/data/students.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    setState(() {
      _students = jsonList.map((e) => Map<String, dynamic>.from(e)).toList();
      _isLoading = false;
    });
  }

  List<int> get _sortedIndexes {
    final indexes = List<int>.generate(_students.length, (i) => i);

    final filtered = _searchQuery.isEmpty
        ? indexes
        : indexes.where((i) {
            final lastName = (_students[i]['lastName'] as String? ?? '').toLowerCase();
            final firstName = (_students[i]['firstName'] as String? ?? '').toLowerCase();
            return lastName.contains(_searchQuery) || firstName.contains(_searchQuery);
          }).toList();

    filtered.sort((a, b) {
      final lastA = (_students[a]['lastName'] as String? ?? '');
      final lastB = (_students[b]['lastName'] as String? ?? '');
      final lastCmp = lastA.compareTo(lastB);
      if (lastCmp != 0) return lastCmp;
      final firstA = (_students[a]['firstName'] as String? ?? '');
      final firstB = (_students[b]['firstName'] as String? ?? '');
      return firstA.compareTo(firstB);
    });

    return filtered;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      default:
        return Colors.transparent;
    }
  }

  void _showStatusSheet(BuildContext context, int originalIndex) {
    final student = _students[originalIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF152028),
            borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  '${student['lastName']} ${student['firstName']}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildStatusOption(
                label: 'ПРИСУТСТВУЕТ',
                color: Colors.green,
                onTap: () {
                  setState(() => _students[originalIndex]['status'] = 'present');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                label: 'ОТСУТСТВУЕТ',
                color: Colors.red,
                onTap: () {
                  setState(() => _students[originalIndex]['status'] = 'absent');
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
              _buildStatusOption(
                label: 'ПРИЧИНА',
                color: Colors.orange,
                onTap: () {
                  setState(() => _students[originalIndex]['status'] = 'late');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;
    final sortedIndexes = _sortedIndexes;

    return Scaffold(
      backgroundColor: const Color(0xFF101C22),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Посещаемость',
          style: TextStyle(color: Colors.white, fontSize: w * 0.06, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF101C22),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF455664), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D59F2)))
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.03).add(EdgeInsets.only(top: h * 0.02)),
              child: Column(
                children: [
                  _buildSearchField(w),
                  SizedBox(height: h * 0.018),
                  _buildFilterRow(w),
                  SizedBox(height: h * 0.018),
                  _buildStudentList(w, h, sortedIndexes),
                ],
              ),
            ),
    );
  }

  Widget _buildSearchField(double w) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E2D36), borderRadius: BorderRadius.circular(27)),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          setState(() => _searchQuery = value.trim().toLowerCase());
        },
        decoration: const InputDecoration(
          hintText: 'Поиск',
          hintStyle: TextStyle(color: Color(0xFF7A9BAF)),
          suffixIcon: Icon(Icons.search, color: Color(0xFF7A9BAF)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterRow(double w) {
    return Row(
      children: [
        Expanded(
          child: _buildFilterChip(label: 'ПРИСУТСТВУЕТ', color: Colors.green, w: w),
        ),
        SizedBox(width: w * 0.02),
        Expanded(
          child: _buildFilterChip(label: 'ОТСУТСТВУЕТ', color: Colors.red, w: w),
        ),
        SizedBox(width: w * 0.02),
        Expanded(
          child: _buildFilterChip(label: 'ПРИЧИНА', color: Colors.orange, w: w),
        ),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required Color color, required double w}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: w * 0.015),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: w * 0.028, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(double w, double h, List<int> sortedIndexes) {
    return Expanded(
      child: ListView.separated(
        itemCount: sortedIndexes.length,
        separatorBuilder: (_, __) => SizedBox(height: h * 0.012),
        itemBuilder: (context, i) {
          final originalIndex = sortedIndexes[i];
          final student = _students[originalIndex];
          final status = student['status'] as String?;
          final isMale = student['isMale'] as bool;
          final hasStatus = status != null;

          return Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.015),
            decoration: BoxDecoration(
              color: const Color(0xFF10232C),
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: const Color(0xFF455664), width: 1),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(radius: w * 0.07, backgroundImage: AssetImage(isMale ? 'assets/images/man_avatar.png' : 'assets/images/women_avatar.png'), backgroundColor: const Color(0xFF3A5FCD)),
                    if (hasStatus)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF10232C), width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: w * 0.04),
                Expanded(
                  child: Text(
                    '${student['lastName']}\n${student['firstName']}',
                    style: TextStyle(color: Colors.white, fontSize: w * 0.042, fontWeight: FontWeight.w600, height: 1.3),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showStatusSheet(context, originalIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D59F2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: h * 0.013),
                  ),
                  child: Text(
                    hasStatus ? 'Изменить' : 'Отметить',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: w * 0.038),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusOption({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
