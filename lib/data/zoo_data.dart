// lib/data/zoo_data.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

class Animal {
  final String id; // ID trùng với nhãn AI (vd: 'elephant')
  final String name; // Tên tiếng Việt
  final String scientificName; // Tên khoa học
  final String diet; // Chế độ ăn
  final String habitat; // Môi trường sống
  final String lifespan; // Tuổi thọ
  final String conservationStatus; // Tình trạng bảo tồn
  final String description; // Mô tả chi tiết
  final String imagePath; // Đường dẫn ảnh (local asset)
  final String modelPath; // Đường dẫn 3D (local asset)
  final String soundPath; // Đường dẫn âm thanh (local asset)
  final int favoriteCount;

  Animal({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.diet,
    required this.habitat,
    required this.lifespan,
    required this.conservationStatus,
    required this.description,
    required this.imagePath,
    required this.modelPath,
    required this.soundPath,
    this.favoriteCount = 0,
  });

  // Chuyển dữ liệu từ Firebase về Object
  factory Animal.fromMap(Map<String, dynamic> data) {
    return Animal(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      scientificName: data['scientificName'] ?? 'Chưa cập nhật',
      diet: data['diet'] ?? 'Chưa cập nhật',
      habitat: data['habitat'] ?? 'Chưa cập nhật',
      lifespan: data['lifespan'] ?? 'Chưa cập nhật',
      conservationStatus: data['conservationStatus'] ?? 'Không rõ',
      description: data['description'] ?? '',
      imagePath: data['imagePath'] ?? '',
      modelPath: data['modelPath'] ?? '',
      soundPath: data['soundPath'] ?? '',
      favoriteCount: data['favoriteCount'] ?? 0,
    );
  }

  // Chuyển Object thành JSON để đẩy lên Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'diet': diet,
      'habitat': habitat,
      'lifespan': lifespan,
      'conservationStatus': conservationStatus,
      'description': description,
      'imagePath': imagePath,
      'modelPath': modelPath,
      'soundPath': soundPath,
    };
  }
}

// --- DỮ LIỆU GỐC (Dùng để Upload lên Firebase 1 lần) ---
List<Animal> zooAnimals = [
  Animal(
    id: "elephant",
    name: "Voi Châu Phi",
    scientificName: "Loxodonta africana",
    diet: "Thực vật (Cỏ, lá, cành cây)",
    habitat: "Savan, Rừng thưa, Sa mạc",
    lifespan: "60 - 70 năm",
    conservationStatus: "Nguy cấp (EN)",
    description:
        "Voi là động vật có vú lớn nhất trên cạn. Chúng có đôi tai lớn hình quạt giúp tỏa nhiệt và chiếc vòi đa năng.",
    imagePath: "assets/images/elephant.jpg",
    modelPath: "assets/models/elephant.glb",
    soundPath: "assets/audio/elephant_trumpet.mp3",
  ),
  Animal(
    id: "tiger",
    name: "Hổ Bengal",
    scientificName: "Panthera tigris tigris",
    diet: "Động vật ăn thịt (Hươu, lợn rừng...)",
    habitat: "Rừng nhiệt đới, Rừng ngập mặn",
    lifespan: "15 - 20 năm",
    conservationStatus: "Nguy cấp (EN)",
    description:
        "Hổ là loài lớn nhất trong họ Mèo. Với bộ lông màu cam rực rỡ và những sọc đen đặc trưng, chúng là những kẻ săn mồi dũng mãnh.",
    imagePath: "assets/images/tiger.jpg",
    modelPath: "assets/models/tiger.glb",
    soundPath: "assets/audio/tiger_roar.mp3",
  ),
  Animal(
    id: "bear",
    name: "Gấu Nâu",
    scientificName: "Ursus arctos",
    diet: "Ăn tạp (Cá, quả mọng, mật ong, thú nhỏ)",
    habitat: "Rừng núi, Thung lũng",
    lifespan: "20 - 30 năm",
    conservationStatus: "Ít quan tâm (LC)",
    description:
        "Gấu nâu có khứu giác cực kỳ nhạy bén. Dù to lớn, chúng có thể chạy với tốc độ lên tới 48 km/h.",
    imagePath: "assets/images/bear.jpg",
    modelPath: "assets/models/bear.glb",
    soundPath: "assets/audio/bear_growl.mp3",
  ),
  Animal(
    id: "zebra",
    name: "Ngựa Vằn",
    scientificName: "Equus quagga",
    diet: "Thực vật (Cỏ bụi)",
    habitat: "Đồng cỏ Savan",
    lifespan: "20 - 25 năm",
    conservationStatus: "Sắp bị đe dọa (NT)",
    description:
        "Mỗi con ngựa vằn có hoa văn sọc độc nhất vô nhị. Chúng thường đi theo đàn lớn để tránh kẻ thù.",
    imagePath: "assets/images/zebra.jpg",
    modelPath: "assets/models/zebra.glb",
    soundPath: "assets/audio/zebra_sound.mp3",
  ),
  Animal(
    id: "giraffe",
    name: "Hươu Cao Cổ",
    scientificName: "Giraffa camelopardalis",
    diet: "Thực vật (Lá cây keo)",
    habitat: "Savan, Rừng thưa",
    lifespan: "25 năm",
    conservationStatus: "Dễ bị tổn thương (VU)",
    description:
        "Là động vật cao nhất thế giới. Lưỡi của chúng dài tới 45cm và có màu xanh tím để tránh bị cháy nắng.",
    imagePath: "assets/images/giraffe.jpg",
    modelPath: "assets/models/giraffe.glb",
    soundPath: "assets/audio/giraffe_sound.mp3",
  ),
  Animal(
    id: "leopard",
    name: "Báo Đốm",
    scientificName: "Panthera pardus",
    diet: "Động vật ăn thịt",
    habitat: "Rừng mưa, Savan",
    lifespan: "12 - 17 năm",
    conservationStatus: "Dễ bị tổn thương (VU)",
    description:
        "Báo đốm leo trèo rất giỏi. Chúng thường tha con mồi lên cây để ăn nhằm tránh bị sư tử hay linh cẩu cướp mất.",
    imagePath: "assets/images/leopard.jpg",
    modelPath: "assets/models/leopard.glb",
    soundPath: "assets/audio/leopard_growl.mp3",
  ),
  Animal(
    id: "rhino",
    name: "Tê Giác Trắng",
    scientificName: "Ceratotherium simum",
    diet: "Thực vật (Cỏ)",
    habitat: "Đồng cỏ, Savan",
    lifespan: "40 - 50 năm",
    conservationStatus: "Sắp bị đe dọa (NT)",
    description:
        "Tê giác có lớp da dày như áo giáp. Sừng của chúng được cấu tạo từ keratin, giống như tóc và móng tay người.",
    imagePath: "assets/images/rhino.jpg",
    modelPath: "assets/models/rhino.glb",
    soundPath: "assets/audio/rhino_sound.mp3",
  ),
  Animal(
    id: "panda",
    name: "Gấu Trúc Lớn",
    scientificName: "Ailuropoda melanoleuca",
    diet: "Thực vật (Tre, trúc)",
    habitat: "Rừng trúc núi cao (Trung Quốc)",
    lifespan: "20 năm (hoang dã)",
    conservationStatus: "Dễ bị tổn thương (VU)",
    description:
        "Gấu trúc dành 14 tiếng mỗi ngày chỉ để ăn. Chúng có một 'ngón tay cái giả' giúp cầm nắm thân tre dễ dàng.",
    imagePath: "assets/images/panda.JPG",
    modelPath: "assets/models/panda.glb",
    soundPath: "assets/audio/panda_sound.mp3",
  ),
  Animal(
    id: "camel",
    name: "Lạc Đà Một Bướu",
    scientificName: "Camelus dromedarius",
    diet: "Thực vật (Cây bụi, xương rồng)",
    habitat: "Sa mạc",
    lifespan: "40 năm",
    conservationStatus: "Đã được thuần hóa",
    description:
        "Lạc đà có thể uống 100 lít nước trong 10 phút. Bướu của chúng chứa mỡ để chuyển hóa thành năng lượng và nước.",
    imagePath: "assets/images/camel.jpg",
    modelPath: "assets/models/camel.glb",
    soundPath: "assets/audio/camel_sound.mp3",
  ),
  Animal(
    id: "capybara",
    name: "Chuột Lang Nước",
    scientificName: "Hydrochoerus hydrochaeris",
    diet: "Thực vật (Cỏ, thực vật thủy sinh)",
    habitat: "Đầm lầy, ven sông (Nam Mỹ)",
    lifespan: "8 - 10 năm",
    conservationStatus: "Ít quan tâm (LC)",
    description:
        "Là loài gặm nhấm lớn nhất thế giới. Chúng rất hiền lành và thường để các loài chim đậu trên lưng.",
    imagePath: "assets/images/capybara.jpg",
    modelPath: "assets/models/capybara.glb",
    soundPath: "assets/audio/capybara_sound.mp3",
  ),
  Animal(
    id: "hyena",
    name: "Linh Cẩu Đốm",
    scientificName: "Crocuta crocuta",
    diet: "Động vật ăn thịt",
    habitat: "Savan, Bán hoang mạc",
    lifespan: "12 năm",
    conservationStatus: "Ít quan tâm (LC)",
    description:
        "Linh cẩu có lực cắn cực mạnh, có thể nghiền nát xương. Chúng sống theo chế độ mẫu hệ (con cái đầu đàn).",
    imagePath: "assets/images/hyena.jpg",
    modelPath: "assets/models/hyena.glb",
    soundPath: "assets/audio/hyena_laugh.mp3",
  ),
  Animal(
    id: "lemur",
    name: "Vượn Cáo Đuôi Vòng",
    scientificName: "Lemur catta",
    diet: "Ăn tạp (Quả, lá, côn trùng)",
    habitat: "Rừng Madagascar",
    lifespan: "16 - 19 năm",
    conservationStatus: "Nguy cấp (EN)",
    description:
        "Vượn cáo dùng chiếc đuôi dài có khoang đen trắng để giao tiếp và giữ thăng bằng. Chúng thích tắm nắng vào buổi sáng.",
    imagePath: "assets/images/lemur.jpg",
    modelPath: "assets/models/lemur.glb",
    soundPath: "assets/audio/lemur_sound.mp3",
  ),
  Animal(
    id: "turtle",
    name: "Rùa Biển",
    scientificName: "Chelonioidea",
    diet: "Sứa, rong biển, cua",
    habitat: "Đại dương",
    lifespan: "50 - 100 năm",
    conservationStatus: "Nguy cấp",
    description:
        "Rùa biển bơi lội rất giỏi nhưng phải lên mặt nước để thở. Rùa cái quay lại đúng bãi biển nơi mình sinh ra để đẻ trứng.",
    imagePath: "assets/images/turtle.jpg",
    modelPath: "assets/models/turtle.glb",
    soundPath: "assets/audio/turtle_sound.mp3",
  ),
  Animal(
    id: "warthog",
    name: "Lợn Bướu",
    scientificName: "Phacochoerus africanus",
    diet: "Ăn tạp (Cỏ, rễ cây, xác thối)",
    habitat: "Savan, Đồng cỏ",
    lifespan: "15 năm",
    conservationStatus: "Ít quan tâm (LC)",
    description:
        "Lợn bướu thường chạy với cái đuôi dựng đứng lên trời. Chúng sống trong các hang do loài khác đào bỏ lại.",
    imagePath: "assets/images/warthog.jpg",
    modelPath: "assets/models/warthog.glb",
    soundPath: "assets/audio/warthog_sound.mp3",
  ),
];
