/// GET /api/supplies/categories 응답의 `result` 항목 (JSON 파싱용)
class SupplyCategoryGroup {
  final String category;
  final String categoryName;
  final List<SupplySubCategoryItem> subCategories;

  const SupplyCategoryGroup({
    required this.category,
    required this.categoryName,
    required this.subCategories,
  });

  factory SupplyCategoryGroup.fromJson(Map<String, dynamic> json) {
    final raw = json['subCategories'];
    final subs = <SupplySubCategoryItem>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          subs.add(SupplySubCategoryItem.fromJson(e));
        }
      }
    }
    return SupplyCategoryGroup(
      category: json['category'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      subCategories: subs,
    );
  }
}

class SupplySubCategoryItem {
  final String subCategory;
  final String subCategoryName;

  const SupplySubCategoryItem({
    required this.subCategory,
    required this.subCategoryName,
  });

  factory SupplySubCategoryItem.fromJson(Map<String, dynamic> json) {
    return SupplySubCategoryItem(
      subCategory: json['subCategory'] as String? ?? '',
      subCategoryName: json['subCategoryName'] as String? ?? '',
    );
  }
}

/// 앱 고정 공용 소비 분류 (백엔드 미사용). 수동 추가 모달 대·소분류 선택에 사용합니다.
const List<SupplyCategoryGroup> kDefaultSupplyCategoryGroups = [
  SupplyCategoryGroup(
    category: 'KITCHEN',
    categoryName: '주방용품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'kitchen_scissors', subCategoryName: '가위'),
      SupplySubCategoryItem(subCategory: 'kitchen_knife', subCategoryName: '칼'),
      SupplySubCategoryItem(subCategory: 'kitchen_board', subCategoryName: '도마'),
      SupplySubCategoryItem(subCategory: 'kitchen_sponge', subCategoryName: '수세미'),
      SupplySubCategoryItem(
        subCategory: 'kitchen_detergent',
        subCategoryName: '주방세제',
      ),
      SupplySubCategoryItem(
        subCategory: 'kitchen_towel',
        subCategoryName: '키친타올',
      ),
      SupplySubCategoryItem(
        subCategory: 'kitchen_trash_bag',
        subCategoryName: '쓰레기봉투',
      ),
      SupplySubCategoryItem(
        subCategory: 'kitchen_gloves',
        subCategoryName: '고무장갑',
      ),
    ],
  ),
  SupplyCategoryGroup(
    category: 'BATH',
    categoryName: '욕실용품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'bath_shampoo', subCategoryName: '샴푸'),
      SupplySubCategoryItem(subCategory: 'bath_rinse', subCategoryName: '린스'),
      SupplySubCategoryItem(subCategory: 'bath_body_wash', subCategoryName: '바디워시'),
      SupplySubCategoryItem(subCategory: 'bath_toothpaste', subCategoryName: '치약'),
      SupplySubCategoryItem(subCategory: 'bath_tissue', subCategoryName: '휴지'),
      SupplySubCategoryItem(subCategory: 'bath_hand_wash', subCategoryName: '핸드워시'),
    ],
  ),
  SupplyCategoryGroup(
    category: 'CLEANING',
    categoryName: '청소용품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'clean_wipe', subCategoryName: '청소포'),
      SupplySubCategoryItem(subCategory: 'clean_brush', subCategoryName: '청소솔'),
      SupplySubCategoryItem(
        subCategory: 'clean_laundry',
        subCategoryName: '세탁세제',
      ),
      SupplySubCategoryItem(
        subCategory: 'clean_softener',
        subCategoryName: '섬유유연제',
      ),
      SupplySubCategoryItem(
        subCategory: 'clean_glass',
        subCategoryName: '유리세정제',
      ),
      SupplySubCategoryItem(
        subCategory: 'clean_bathroom',
        subCategoryName: '욕실 세제',
      ),
    ],
  ),
  SupplyCategoryGroup(
    category: 'HYGIENE',
    categoryName: '위생용품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'hyg_tissue', subCategoryName: '휴지'),
      SupplySubCategoryItem(subCategory: 'hyg_wet_wipe', subCategoryName: '물티슈'),
      SupplySubCategoryItem(
        subCategory: 'hyg_air_freshener',
        subCategoryName: '방향제',
      ),
    ],
  ),
  SupplyCategoryGroup(
    category: 'GROCERY',
    categoryName: '식료품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'groc_rice', subCategoryName: '쌀'),
      SupplySubCategoryItem(subCategory: 'groc_water', subCategoryName: '생수'),
      SupplySubCategoryItem(subCategory: 'groc_oil', subCategoryName: '기름'),
      SupplySubCategoryItem(
        subCategory: 'groc_basic_seasoning',
        subCategoryName: '기본 조미료',
      ),
      SupplySubCategoryItem(
        subCategory: 'groc_basic_sauce',
        subCategoryName: '기본 양념',
      ),
      SupplySubCategoryItem(subCategory: 'groc_eggs', subCategoryName: '계란'),
      SupplySubCategoryItem(subCategory: 'groc_milk', subCategoryName: '우유'),
      SupplySubCategoryItem(subCategory: 'groc_bread', subCategoryName: '식빵'),
      SupplySubCategoryItem(subCategory: 'groc_kimchi', subCategoryName: '김치'),
      SupplySubCategoryItem(subCategory: 'groc_ramen', subCategoryName: '라면'),
      SupplySubCategoryItem(
        subCategory: 'groc_vegetables',
        subCategoryName: '야채',
      ),
    ],
  ),
  SupplyCategoryGroup(
    category: 'OTHER',
    categoryName: '기타',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'oth_power_strip', subCategoryName: '멀티탭'),
      SupplySubCategoryItem(subCategory: 'oth_tissue_box', subCategoryName: '각티슈'),
      SupplySubCategoryItem(
        subCategory: 'oth_air_freshener',
        subCategoryName: '방향제',
      ),
      SupplySubCategoryItem(
        subCategory: 'oth_fluorescent',
        subCategoryName: '형광등',
      ),
      SupplySubCategoryItem(subCategory: 'oth_battery', subCategoryName: '건전지'),
      SupplySubCategoryItem(
        subCategory: 'oth_mosquito',
        subCategoryName: '모기약',
      ),
      SupplySubCategoryItem(
        subCategory: 'oth_fly_swatter',
        subCategoryName: '전기파리채',
      ),
    ],
  ),
];
