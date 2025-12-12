export interface Animal {
  id: string;
  name: string;           // Tên tiếng Việt
  englishName: string;    // Tên tiếng Anh (khớp với label YOLO)
  scientificName: string; // Tên khoa học
  category: string;       // Phân loại
  description: string;    // Mô tả chi tiết
  habitat: string;        // Môi trường sống
  image: any;             // Đường dẫn ảnh 2D
  model: any;             // Đường dẫn model 3D (.glb)
  soundFile: string;      // Tên file âm thanh (không đuôi .mp3)
  yoloClassId: number;    // ID trả về từ model AI (0, 1, 2...)
}

export const ZOO_DATA: Animal[] = [
  {
    id: 'bear',
    name: 'Gấu',
    englishName: 'Bear',
    scientificName: 'Ursidae',
    category: 'Thú',
    description: 'Gấu là loài động vật to lớn, có bộ lông dày. Chúng có thể đứng bằng hai chân sau và rất thích ăn mật ong, cá hoặc quả mọng.',
    habitat: 'Rừng & Núi tuyết',
    image: require('../assets/images/bear.jpg'), 
    model: require('../assets/models/bear.glb'),
    soundFile: 'bear_growl',
    yoloClassId: 0, // bear
  },
  {
    id: 'camel',
    name: 'Lạc Đà',
    englishName: 'Camel',
    scientificName: 'Camelus',
    category: 'Thú',
    description: 'Lạc đà được mệnh danh là "con tàu của sa mạc". Cái bướu trên lưng giúp chúng dự trữ mỡ để sống sót nhiều ngày không cần nước.',
    habitat: 'Sa mạc',
    image: require('../assets/images/camel.jpg'),
    model: require('../assets/models/camel.glb'),
    soundFile: 'camel_sound',
    yoloClassId: 1, // camel
  },
  {
    id: 'capybara',
    name: 'Chuột Lang Nước',
    englishName: 'Capybara',
    scientificName: 'Hydrochoerus hydrochaeris',
    category: 'Thú',
    description: 'Đây là loài gặm nhấm lớn nhất thế giới. Capybara rất thân thiện, bơi giỏi và thường để các loài vật khác ngồi lên lưng mình.',
    habitat: 'Đầm lầy & Ven sông',
    image: require('../assets/images/capybara.jpg'),
    model: require('../assets/models/capybara.glb'),
    soundFile: 'capybara_sound',
    yoloClassId: 2, // capybara
  },
  {
    id: 'elephant',
    name: 'Voi',
    englishName: 'Elephant',
    scientificName: 'Elephantidae',
    category: 'Thú',
    description: 'Voi là động vật trên cạn lớn nhất hành tinh. Chiếc vòi dài giúp chúng cầm nắm, uống nước và giao tiếp với đồng loại.',
    habitat: 'Rừng nhiệt đới & Thảo nguyên',
    image: require('../assets/images/elephant.jpg'),
    model: require('../assets/models/elephant.glb'),
    soundFile: 'elephant_trumpet',
    yoloClassId: 3, // elephant
  },
  {
    id: 'giraffe',
    name: 'Hươu Cao Cổ',
    englishName: 'Giraffe',
    scientificName: 'Giraffa',
    category: 'Thú',
    description: 'Hươu cao cổ là động vật cao nhất trên cạn. Cổ dài giúp chúng ăn lá cây trên ngọn cao mà các loài khác không với tới.',
    habitat: 'Thảo nguyên Savanna',
    image: require('../assets/images/giraffe.jpg'),
    model: require('../assets/models/giraffe.glb'),
    soundFile: 'giraffe_sound',
    yoloClassId: 4, // giraffe
  },
  {
    id: 'hyena',
    name: 'Linh Cẩu',
    englishName: 'Hyena',
    scientificName: 'Hyaenidae',
    category: 'Thú',
    description: 'Linh cẩu là loài săn mồi cơ hội, sống theo bầy đàn. Tiếng kêu của chúng đôi khi nghe giống như tiếng cười man dại.',
    habitat: 'Đồng cỏ Châu Phi',
    image: require('../assets/images/hyena.jpg'),
    model: require('../assets/models/hyena.glb'),
    soundFile: 'hyena_laugh',
    yoloClassId: 5, // hyena
  },
  {
    id: 'lemur',
    name: 'Vượn Cáo',
    englishName: 'Lemur',
    scientificName: 'Lemuroidea',
    category: 'Thú',
    description: 'Vượn cáo chỉ sống ở đảo Madagascar. Chúng có đôi mắt to tròn, đuôi dài sọc đen trắng và rất thích tắm nắng vào buổi sáng.',
    habitat: 'Rừng mưa nhiệt đới',
    image: require('../assets/images/lemur.jpg'),
    model: require('../assets/models/lemur.glb'),
    soundFile: 'lemur_sound',
    yoloClassId: 6, // lemur
  },
  {
    id: 'leopard',
    name: 'Báo Hoa Mai',
    englishName: 'Leopard',
    scientificName: 'Panthera pardus',
    category: 'Thú',
    description: 'Báo hoa mai là bậc thầy leo trèo. Chúng thường tha con mồi lên cây để tránh bị linh cẩu hoặc sư tử cướp mất.',
    habitat: 'Rừng & Đồng cỏ',
    image: require('../assets/images/leopard.jpg'),
    model: require('../assets/models/leopard.glb'),
    soundFile: 'leopard_growl',
    yoloClassId: 7, // leopard
  },
  {
    id: 'panda',
    name: 'Gấu Trúc',
    englishName: 'Panda',
    scientificName: 'Ailuropoda melanoleuca',
    category: 'Thú',
    description: 'Gấu trúc là biểu tượng của Trung Quốc. Dù thuộc họ gấu nhưng 99% thức ăn của chúng là tre và trúc.',
    habitat: 'Rừng tre núi cao',
    image: require('../assets/images/panda.jpg'),
    model: require('../assets/models/panda.glb'),
    soundFile: 'panda_sound',
    yoloClassId: 8, // panda
  },
  {
    id: 'rhino',
    name: 'Tê Giác',
    englishName: 'Rhino',
    scientificName: 'Rhinocerotidae',
    category: 'Thú',
    description: 'Tê giác có lớp da dày như áo giáp và chiếc sừng lớn trên mũi. Chúng trông dữ tợn nhưng thực ra lại ăn cỏ.',
    habitat: 'Đồng cỏ & Bụi rậm',
    image: require('../assets/images/rhino.jpg'),
    model: require('../assets/models/rhino.glb'),
    soundFile: 'rhino_sound',
    yoloClassId: 9, // rhino
  },
  {
    id: 'tiger',
    name: 'Hổ',
    englishName: 'Tiger',
    scientificName: 'Panthera tigris',
    category: 'Thú',
    description: 'Hổ là chúa tể sơn lâm. Bộ lông vằn giúp chúng ngụy trang trong cỏ cao để rình mồi. Hổ bơi rất giỏi.',
    habitat: 'Rừng rậm',
    image: require('../assets/images/tiger.jpg'),
    model: require('../assets/models/tiger.glb'),
    soundFile: 'tiger_roar',
    yoloClassId: 10, // tiger
  },
  {
    id: 'turtle',
    name: 'Rùa',
    englishName: 'Turtle',
    scientificName: 'Testudines',
    category: 'Bò sát',
    description: 'Rùa có cái mai cứng bảo vệ cơ thể. Chúng di chuyển chậm chạp nhưng sống rất thọ, có loài sống hơn 100 năm.',
    habitat: 'Đại dương hoặc Ao hồ',
    image: require('../assets/images/turtle.jpg'),
    model: require('../assets/models/turtle.glb'),
    soundFile: 'turtle_sound',
    yoloClassId: 11, // turtle
  },
  {
    id: 'warthog',
    name: 'Lợn Bướu',
    englishName: 'Warthog',
    scientificName: 'Phacochoerus',
    category: 'Thú',
    description: 'Lợn bướu có cặp răng nanh cong ngược lên trên. Nhân vật Pumbaa trong vua sư tử chính là một chú lợn bướu.',
    habitat: 'Đồng cỏ Savanna',
    image: require('../assets/images/warthog.jpg'),
    model: require('../assets/models/warthog.glb'),
    soundFile: 'warthog_sound',
    yoloClassId: 12, // warthog
  },
  {
    id: 'zebra',
    name: 'Ngựa Vằn',
    englishName: 'Zebra',
    scientificName: 'Equus quagga',
    category: 'Thú',
    description: 'Ngựa vằn nổi bật với bộ lông sọc đen trắng. Không có hai con ngựa vằn nào có sọc giống hệt nhau.',
    habitat: 'Đồng cỏ Châu Phi',
    image: require('../assets/images/zebra.jpg'),
    model: require('../assets/models/zebra.glb'),
    soundFile: 'zebra_sound',
    yoloClassId: 13, // zebra
  },
];