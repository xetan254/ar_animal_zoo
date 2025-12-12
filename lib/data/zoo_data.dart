// lib/data/zoo_data.dart

class Animal {
  final String id;
  final String name; // Tên tiếng Việt
  final String englishName; // Tên tiếng Anh (khớp với label YOLO)
  final String scientificName; // Tên khoa học
  final String category; // Phân loại
  final String description; // Mô tả chi tiết
  final String habitat; // Môi trường sống
  final String imagePath; // Đường dẫn ảnh 2D
  final String modelPath; // Đường dẫn model 3D (.glb)
  final String soundPath; // Đường dẫn file âm thanh
  final int yoloClassId; // ID class của YOLO

  const Animal({
    required this.id,
    required this.name,
    required this.englishName,
    required this.scientificName,
    required this.category,
    required this.description,
    required this.habitat,
    required this.imagePath,
    required this.modelPath,
    required this.soundPath,
    required this.yoloClassId,
  });
}

class ZooData {
  static const List<Animal> animals = [
    Animal(
      id: 'bear',
      name: 'Gấu',
      englishName: 'Bear',
      scientificName: 'Ursidae',
      category: 'Thú',
      description:
          'Gấu là loài động vật to lớn, có bộ lông dày. Chúng có thể đứng bằng hai chân sau và rất thích ăn mật ong, cá hoặc quả mọng.',
      habitat: 'Rừng & Núi tuyết',
      imagePath: 'assets/images/bear.jpg',
      modelPath: 'assets/models/bear.glb',
      soundPath: 'assets/audio/bear_growl.mp3',
      yoloClassId: 0,
    ),
    Animal(
      id: 'camel',
      name: 'Lạc Đà',
      englishName: 'Camel',
      scientificName: 'Camelus',
      category: 'Thú',
      description:
          'Lạc đà được mệnh danh là "con tàu của sa mạc". Cái bướu trên lưng giúp chúng dự trữ mỡ để sống sót nhiều ngày không cần nước.',
      habitat: 'Sa mạc',
      imagePath: 'assets/images/camel.jpg',
      modelPath: 'assets/models/camel.glb',
      soundPath: 'assets/audio/camel_sound.mp3',
      yoloClassId: 1,
    ),
    Animal(
      id: 'capybara',
      name: 'Chuột Lang Nước',
      englishName: 'Capybara',
      scientificName: 'Hydrochoerus hydrochaeris',
      category: 'Thú',
      description:
          'Đây là loài gặm nhấm lớn nhất thế giới. Capybara rất thân thiện, bơi giỏi và thường để các loài vật khác ngồi lên lưng mình.',
      habitat: 'Đầm lầy & Ven sông',
      imagePath: 'assets/images/capybara.jpg',
      modelPath: 'assets/models/capybara.glb',
      soundPath: 'assets/audio/capybara_sound.mp3',
      yoloClassId: 2,
    ),
    Animal(
      id: 'elephant',
      name: 'Voi',
      englishName: 'Elephant',
      scientificName: 'Elephantidae',
      category: 'Thú',
      description:
          'Voi là động vật trên cạn lớn nhất hành tinh. Chiếc vòi dài giúp chúng cầm nắm, uống nước và giao tiếp với đồng loại.',
      habitat: 'Rừng nhiệt đới & Thảo nguyên',
      imagePath: 'assets/images/elephant.jpg',
      modelPath: 'assets/models/elephant.glb',
      soundPath: 'assets/audio/elephant_trumpet.mp3',
      yoloClassId: 3,
    ),
    Animal(
      id: 'giraffe',
      name: 'Hươu Cao Cổ',
      englishName: 'Giraffe',
      scientificName: 'Giraffa',
      category: 'Thú',
      description:
          'Hươu cao cổ là động vật cao nhất trên cạn. Cổ dài giúp chúng ăn lá cây trên ngọn cao mà các loài khác không với tới.',
      habitat: 'Thảo nguyên Savanna',
      imagePath: 'assets/images/giraffe.jpg',
      modelPath: 'assets/models/giraffe.glb',
      soundPath: 'assets/audio/giraffe_sound.mp3',
      yoloClassId: 4,
    ),
    Animal(
      id: 'hyena',
      name: 'Linh Cẩu',
      englishName: 'Hyena',
      scientificName: 'Hyaenidae',
      category: 'Thú',
      description:
          'Linh cẩu là loài săn mồi cơ hội, sống theo bầy đàn. Tiếng kêu của chúng đôi khi nghe giống như tiếng cười man dại.',
      habitat: 'Đồng cỏ Châu Phi',
      imagePath: 'assets/images/hyena.jpg',
      modelPath: 'assets/models/hyena.glb',
      soundPath: 'assets/audio/hyena_laugh.mp3',
      yoloClassId: 5,
    ),
    Animal(
      id: 'lemur',
      name: 'Vượn Cáo',
      englishName: 'Lemur',
      scientificName: 'Lemuroidea',
      category: 'Thú',
      description:
          'Vượn cáo chỉ sống ở đảo Madagascar. Chúng có đôi mắt to tròn, đuôi dài sọc đen trắng và rất thích tắm nắng vào buổi sáng.',
      habitat: 'Rừng mưa nhiệt đới',
      imagePath: 'assets/images/lemur.jpg',
      modelPath: 'assets/models/lemur.glb',
      soundPath: 'assets/audio/lemur_sound.mp3',
      yoloClassId: 6,
    ),
    Animal(
      id: 'leopard',
      name: 'Báo Hoa Mai',
      englishName: 'Leopard',
      scientificName: 'Panthera pardus',
      category: 'Thú',
      description:
          'Báo hoa mai là bậc thầy leo trèo. Chúng thường tha con mồi lên cây để tránh bị linh cẩu hoặc sư tử cướp mất.',
      habitat: 'Rừng & Đồng cỏ',
      imagePath: 'assets/images/leopard.jpg',
      modelPath: 'assets/models/leopard.glb',
      soundPath: 'assets/audio/leopard_growl.mp3',
      yoloClassId: 7,
    ),
    Animal(
      id: 'panda',
      name: 'Gấu Trúc',
      englishName: 'Panda',
      scientificName: 'Ailuropoda melanoleuca',
      category: 'Thú',
      description:
          'Gấu trúc là biểu tượng của Trung Quốc. Dù thuộc họ gấu nhưng 99% thức ăn của chúng là tre và trúc.',
      habitat: 'Rừng tre núi cao',
      imagePath: 'assets/images/panda.jpg',
      modelPath: 'assets/models/panda.glb',
      soundPath: 'assets/audio/panda_sound.mp3',
      yoloClassId: 8,
    ),
    Animal(
      id: 'rhino',
      name: 'Tê Giác',
      englishName: 'Rhino',
      scientificName: 'Rhinocerotidae',
      category: 'Thú',
      description:
          'Tê giác có lớp da dày như áo giáp và chiếc sừng lớn trên mũi. Chúng trông dữ tợn nhưng thực ra lại ăn cỏ.',
      habitat: 'Đồng cỏ & Bụi rậm',
      imagePath: 'assets/images/rhino.jpg',
      modelPath: 'assets/models/rhino.glb',
      soundPath: 'assets/audio/rhino_sound.mp3',
      yoloClassId: 9,
    ),
    Animal(
      id: 'tiger',
      name: 'Hổ',
      englishName: 'Tiger',
      scientificName: 'Panthera tigris',
      category: 'Thú',
      description:
          'Hổ là chúa tể sơn lâm. Bộ lông vằn giúp chúng ngụy trang trong cỏ cao để rình mồi. Hổ bơi rất giỏi.',
      habitat: 'Rừng rậm',
      imagePath: 'assets/images/tiger.jpg',
      modelPath: 'assets/models/tiger.glb',
      soundPath: 'assets/audio/tiger_roar.mp3',
      yoloClassId: 10,
    ),
    Animal(
      id: 'turtle',
      name: 'Rùa',
      englishName: 'Turtle',
      scientificName: 'Testudines',
      category: 'Bò sát',
      description:
          'Rùa có cái mai cứng bảo vệ cơ thể. Chúng di chuyển chậm chạp nhưng sống rất thọ, có loài sống hơn 100 năm.',
      habitat: 'Đại dương hoặc Ao hồ',
      imagePath: 'assets/images/turtle.jpg',
      modelPath: 'assets/models/turtle.glb',
      soundPath: 'assets/audio/turtle_sound.mp3',
      yoloClassId: 11,
    ),
    Animal(
      id: 'warthog',
      name: 'Lợn Bướu',
      englishName: 'Warthog',
      scientificName: 'Phacochoerus',
      category: 'Thú',
      description:
          'Lợn bướu có cặp răng nanh cong ngược lên trên. Nhân vật Pumbaa trong vua sư tử chính là một chú lợn bướu.',
      habitat: 'Đồng cỏ Savanna',
      imagePath: 'assets/images/warthog.jpg',
      modelPath: 'assets/models/warthog.glb',
      soundPath: 'assets/audio/warthog_sound.mp3',
      yoloClassId: 12,
    ),
    Animal(
      id: 'zebra',
      name: 'Ngựa Vằn',
      englishName: 'Zebra',
      scientificName: 'Equus quagga',
      category: 'Thú',
      description:
          'Ngựa vằn nổi bật với bộ lông sọc đen trắng. Không có hai con ngựa vằn nào có sọc giống hệt nhau.',
      habitat: 'Đồng cỏ Châu Phi',
      imagePath: 'assets/images/zebra.jpg',
      modelPath: 'assets/models/zebra.glb',
      soundPath: 'assets/audio/zebra_sound.mp3',
      yoloClassId: 13,
    ),
  ];

  /// Tìm con vật dựa trên Label trả về từ YOLO (so sánh với englishName)
  static Animal? getAnimalByLabel(String label) {
    try {
      return animals.firstWhere(
        (animal) => animal.englishName.toLowerCase() == label.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
