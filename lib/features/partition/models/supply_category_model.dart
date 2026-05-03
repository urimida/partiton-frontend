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

/// GET /api/supplies/categories 실패 시 폴백. enum·한글명은 서버 household 시드와 동일하게 유지.
const List<SupplyCategoryGroup> kDefaultSupplyCategoryGroups = [
  SupplyCategoryGroup(
    category: 'KITCHEN',
    categoryName: '주방용품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'SCISSORS', subCategoryName: '주방가위'),
      SupplySubCategoryItem(subCategory: 'KNIFE', subCategoryName: '주방칼'),
      SupplySubCategoryItem(subCategory: 'SCRUBBER', subCategoryName: '수세미'),
      SupplySubCategoryItem(subCategory: 'DISH_SOAP', subCategoryName: '주방세제'),
      SupplySubCategoryItem(
        subCategory: 'KITCHEN_TOWEL',
        subCategoryName: '키친타올',
      ),
      SupplySubCategoryItem(subCategory: 'GARBAGE_BAG', subCategoryName: '비닐봉투'),
      SupplySubCategoryItem(
        subCategory: 'RUBBER_GLOVES',
        subCategoryName: '고무장갑',
      ),
      SupplySubCategoryItem(subCategory: 'KITCHEN_ETC', subCategoryName: '기타'),
    ],
  ),
  SupplyCategoryGroup(
    category: 'BATHROOM',
    categoryName: '욕실용품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'SHAMPOO', subCategoryName: '샴푸'),
      SupplySubCategoryItem(subCategory: 'CONDITIONER', subCategoryName: '린스'),
      SupplySubCategoryItem(subCategory: 'BODY_WASH', subCategoryName: '바디워시'),
      SupplySubCategoryItem(subCategory: 'TOOTHPASTE', subCategoryName: '치약'),
      SupplySubCategoryItem(
        subCategory: 'TOILET_PAPER_BATHROOM',
        subCategoryName: '휴지',
      ),
      SupplySubCategoryItem(subCategory: 'HAND_WASH', subCategoryName: '핸드워시'),
      SupplySubCategoryItem(subCategory: 'BATHROOM_ETC', subCategoryName: '기타'),
    ],
  ),
  SupplyCategoryGroup(
    category: 'CLEANING',
    categoryName: '청소용품',
    subCategories: [
      SupplySubCategoryItem(
        subCategory: 'CLEANING_SHEET',
        subCategoryName: '청소포',
      ),
      SupplySubCategoryItem(
        subCategory: 'CLEANING_BRUSH',
        subCategoryName: '청소솔',
      ),
      SupplySubCategoryItem(
        subCategory: 'LAUNDRY_DETERGENT',
        subCategoryName: '세탁세제',
      ),
      SupplySubCategoryItem(
        subCategory: 'FABRIC_SOFTENER',
        subCategoryName: '섬유유연제',
      ),
      SupplySubCategoryItem(
        subCategory: 'GLASS_CLEANER',
        subCategoryName: '유리세정제',
      ),
      SupplySubCategoryItem(
        subCategory: 'BATHROOM_CLEANER',
        subCategoryName: '욕실 세제',
      ),
      SupplySubCategoryItem(subCategory: 'CLEANING_ETC', subCategoryName: '기타'),
    ],
  ),
  SupplyCategoryGroup(
    category: 'HYGIENE',
    categoryName: '위생용품',
    subCategories: [
      SupplySubCategoryItem(
        subCategory: 'TOILET_PAPER_HYGIENE',
        subCategoryName: '휴지',
      ),
      SupplySubCategoryItem(subCategory: 'WET_WIPES', subCategoryName: '물티슈'),
      SupplySubCategoryItem(
        subCategory: 'AIR_FRESHENER_HYGIENE',
        subCategoryName: '방향제',
      ),
      SupplySubCategoryItem(subCategory: 'HYGIENE_ETC', subCategoryName: '기타'),
    ],
  ),
  SupplyCategoryGroup(
    category: 'GROCERY',
    categoryName: '식료품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'RICE', subCategoryName: '쌀'),
      SupplySubCategoryItem(subCategory: 'WATER', subCategoryName: '생수'),
      SupplySubCategoryItem(subCategory: 'OIL', subCategoryName: '식용유'),
      SupplySubCategoryItem(
        subCategory: 'BASIC_SEASONING',
        subCategoryName: '기본 조미료',
      ),
      SupplySubCategoryItem(
        subCategory: 'BASIC_SAUCE',
        subCategoryName: '기본 양념',
      ),
      SupplySubCategoryItem(subCategory: 'EGGS', subCategoryName: '계란'),
      SupplySubCategoryItem(subCategory: 'MILK', subCategoryName: '우유'),
      SupplySubCategoryItem(subCategory: 'BREAD', subCategoryName: '식빵'),
      SupplySubCategoryItem(subCategory: 'KIMCHI', subCategoryName: '김치'),
      SupplySubCategoryItem(subCategory: 'RAMEN', subCategoryName: '라면'),
      SupplySubCategoryItem(subCategory: 'VEGETABLES', subCategoryName: '야채'),
      SupplySubCategoryItem(subCategory: 'GROCERY_ETC', subCategoryName: '기타'),
    ],
  ),
  SupplyCategoryGroup(
    category: 'LIVING',
    categoryName: '생활용품',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'POWER_STRIP', subCategoryName: '멀티탭'),
      SupplySubCategoryItem(subCategory: 'TISSUE_BOX', subCategoryName: '각티슈'),
      SupplySubCategoryItem(
        subCategory: 'AIR_FRESHENER_ETC',
        subCategoryName: '방향제',
      ),
      SupplySubCategoryItem(
        subCategory: 'FLUORESCENT_LAMP',
        subCategoryName: '형광등',
      ),
      SupplySubCategoryItem(subCategory: 'BATTERY', subCategoryName: '건전지'),
      SupplySubCategoryItem(
        subCategory: 'MOSQUITO_REPELLENT',
        subCategoryName: '모기약',
      ),
      SupplySubCategoryItem(
        subCategory: 'ELECTRIC_FLY_SWATTER',
        subCategoryName: '전기파리채',
      ),
      SupplySubCategoryItem(subCategory: 'LIVING_ETC', subCategoryName: '기타'),
    ],
  ),
  SupplyCategoryGroup(
    category: 'ETC',
    categoryName: '기타',
    subCategories: [
      SupplySubCategoryItem(subCategory: 'ETC', subCategoryName: '기타'),
    ],
  ),
];
