import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../data/models/child_model.dart';

/// 儿童档案管理页
/// PRD 4.2: 创建/管理儿童档案，最多3个
class ChildrenPage extends StatefulWidget {
  const ChildrenPage({super.key});

  @override
  State<ChildrenPage> createState() => _ChildrenPageState();
}

class _ChildrenPageState extends State<ChildrenPage> {
  final List<ChildModel> _children = [];
  bool _isLoading = true;

  // 预设头像列表（12个）
  final List<Color> _avatarColors = [
    AppColors.primary, AppColors.secondary, AppColors.accent,
    const Color(0xFFB3E5FC), const Color(0xFFF8BBD0),
    const Color(0xFFD7CCC8), const Color(0xFFC8E6C9),
    const Color(0xFFE1BEE7), const Color(0xFFFFCC80),
    const Color(0xFF80DEEA), const Color(0xFFA5D6A7),
    const Color(0xFFEF9A9A),
  ];

  // 创建档案表单
  final _nameController = TextEditingController();
  String _selectedGender = 'male';
  String _selectedBirthDate = '';
  int _selectedGrade = 1;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    // TODO: 调用API GET /api/v1/children
    // Mock数据用于UI展示
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _children.clear();
        _isLoading = false;
      });
    }
  }

  void _showCreateDialog() {
    if (_children.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多支持3个儿童档案')),
      );
      return;
    }

    _nameController.clear();
    _selectedGender = 'male';
    _selectedBirthDate = '';
    _selectedGrade = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildCreateSheet(context),
    );
  }

  Future<void> _onCreateChild() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入昵称')),
      );
      return;
    }

    if (_selectedBirthDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择出生年月')),
      );
      return;
    }

    // TODO: 调用API POST /api/v1/children
    // body: { name, gender, birthDate, grade }
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('档案创建成功！'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildCreateSheet(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Text('添加宝贝', style: AppTypography.h2),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // 头像选择
          _buildAvatarPicker(),

          const SizedBox(height: AppSpacing.lg),

          // 昵称
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: '请输入昵称（2-8个字符）',
              prefixIcon: Icon(Icons.person_outline),
            ),
            maxLength: 8,
          ),

          const SizedBox(height: AppSpacing.md),

          // 性别选择
          _buildGenderPicker(),

          const SizedBox(height: AppSpacing.md),

          // 出生年月
          _buildBirthDateField(),

          const SizedBox(height: AppSpacing.md),

          // 年级（自动推荐，可调整）
          _buildGradePicker(),

          const SizedBox(height: AppSpacing.xl),

          // 确认按钮
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _onCreateChild,
              child: const Text('创建档案', style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择头像', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  debugPrint('选择头像: $index');
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _avatarColors[index % _avatarColors.length],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.child_care,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('性别', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _GenderOption(
                label: '男孩',
                icon: Icons.male,
                isSelected: _selectedGender == 'male',
                onTap: () => setState(() => _selectedGender = 'male'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _GenderOption(
                label: '女孩',
                icon: Icons.female,
                isSelected: _selectedGender == 'female',
                onTap: () => setState(() => _selectedGender = 'female'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _GenderOption(
                label: '保密',
                icon: Icons.help_outline,
                isSelected: _selectedGender == 'secret',
                onTap: () => setState(() => _selectedGender = 'secret'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('出生年月', style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: _selectedBirthDate.isEmpty ? '请选择出生年月' : _selectedBirthDate,
            prefixIcon: const Icon(Icons.cake_outlined),
            suffixIcon: const Icon(Icons.chevron_right),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime(2019, 6, 15),
              firstDate: DateTime(2014, 1, 1),
              lastDate: DateTime(2021, 12, 31),
              locale: const Locale('zh', 'CN'),
            );
            if (date != null) {
              setState(() {
                _selectedBirthDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                // 自动计算年级
                final age = DateTime.now().year - date.year;
                if (age <= 6) {
                  _selectedGrade = 1;
                } else if (age <= 7) {
                  _selectedGrade = 2;
                } else if (age <= 8) {
                  _selectedGrade = 3;
                } else if (age <= 10) {
                  _selectedGrade = 4;
                } else {
                  _selectedGrade = 5;
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildGradePicker() {
    final gradeNames = ['L1 启蒙级', 'L2 起步级', 'L3 发展级', 'L4 提升级', 'L5 进阶级'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('初始等级', style: AppTypography.bodySmall),
            const SizedBox(width: 8),
            Text('（根据年龄自动推荐）', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(5, (index) {
            final grade = index + 1;
            return ChoiceChip(
              label: Text(gradeNames[index], style: const TextStyle(fontSize: 12)),
              selected: _selectedGrade == grade,
              onSelected: (_) => setState(() => _selectedGrade = grade),
              selectedColor: AppColors.primaryLight.withOpacity(0.5),
              labelStyle: TextStyle(
                color: _selectedGrade == grade ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: _selectedGrade == grade ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.smallBorder,
                side: BorderSide(
                  color: _selectedGrade == grade ? AppColors.primary : AppColors.border,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('宝贝档案'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _children.isEmpty
              ? _buildEmptyState()
              : _buildChildrenList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('添加宝贝', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.child_care,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('还没有宝贝档案', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '点击下方按钮添加宝贝信息，\nAI将为ta推荐最适合的绘本',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _children.length + 1,
      itemBuilder: (context, index) {
        if (index == _children.length) {
          return const SizedBox(height: 80);
        }
        final child = _children[index];
        return _buildChildCard(child);
      },
    );
  }

  Widget _buildChildCard(ChildModel child) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            child.name.isNotEmpty ? child.name[0] : '?',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        title: Text(child.name, style: AppTypography.h3),
        subtitle: Text(
          '${child.levelName} · 已学${child.knownCharacterCount}字 · 连续${child.streakDays}天',
          style: AppTypography.caption,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          debugPrint('选择儿童: ${child.name}');
        },
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mediumBorder,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          color: isSelected ? AppColors.primaryLight.withOpacity(0.3) : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primaryDark : AppColors.textHint,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
