'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "37496e161a07dc1d551f798360831a29",
"assets/AssetManifest.bin.json": "a0a63bd018b8332e82807ff3273ff8c8",
"assets/assets/images/boxer.png": "17c80df349c1ba23ad0fbb50a3f53983",
"assets/assets/images/gloves.png": "ec9a71ad043e4f80e9c304611cee3fb3",
"assets/assets/images/logo.png": "9b85c811442ff59dc15869b8f0f628cd",
"assets/assets/images/ring.png": "d2bf03db79f9e845944bf06e9e90f651",
"assets/assets/sounds/bell.mp3": "71c5e6d71e18121f2a4bc359778d1324",
"assets/assets/sounds/breath.mp3": "4eb1fad2da12eb5e7599432f1ed63d3a",
"assets/assets/sounds/heartbeat.mp3": "3e19380b64c7c694e36a090acb8730f5",
"assets/assets/sounds/stadium_ambient.mp3": "afe7ab54589de6c69f05df354647141d",
"assets/FontManifest.json": "c75f7af11fb9919e042ad2ee704db319",
"assets/fonts/MaterialIcons-Regular.otf": "787241d666bf3a89440e022785ab71d0",
"assets/NOTICES": "a9debe5c4ef0bc866addc61191aade3f",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "4f36c6deccdae137be6a2d6c6881be3f",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "a6e284904fe0b3673fdd2818cf91e238",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "c70c72e03b892c19e5aed879f60c0d78",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"assets/packages/youtube_player_iframe/assets/player.html": "663ba81294a9f52b1afe96815bb6ecf9",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "e45c397890cff65b22cd5ac5f41f6e6b",
"guia_despliegue.txt": "023348df571e9f4e4da5e93fe8b74551",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "d7db262361e0eea93cbf2d2ab72fe0c6",
"/": "d7db262361e0eea93cbf2d2ab72fe0c6",
"main.dart.js": "f618302c654bde0546145a67e5912e68",
"manifest.json": "7a102ae8ca60e638c4a4688d5a277071",
"tierra-de-campeones-web/.git/COMMIT_EDITMSG": "b0d5b197c0f9a2b4af627d3c6fce9689",
"tierra-de-campeones-web/.git/config": "95f3179bfbfc7717d962c3468857bf3f",
"tierra-de-campeones-web/.git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
"tierra-de-campeones-web/.git/FETCH_HEAD": "167d66b300108f6bcf31ecaaa8c6541d",
"tierra-de-campeones-web/.git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
"tierra-de-campeones-web/.git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
"tierra-de-campeones-web/.git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
"tierra-de-campeones-web/.git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
"tierra-de-campeones-web/.git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
"tierra-de-campeones-web/.git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
"tierra-de-campeones-web/.git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
"tierra-de-campeones-web/.git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
"tierra-de-campeones-web/.git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
"tierra-de-campeones-web/.git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
"tierra-de-campeones-web/.git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
"tierra-de-campeones-web/.git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
"tierra-de-campeones-web/.git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
"tierra-de-campeones-web/.git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
"tierra-de-campeones-web/.git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
"tierra-de-campeones-web/.git/index": "13cd238bfc6bebc0e7d589d5d6b26f20",
"tierra-de-campeones-web/.git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
"tierra-de-campeones-web/.git/logs/HEAD": "c686965ba6f667f75723e362fb92ce1b",
"tierra-de-campeones-web/.git/logs/refs/heads/main": "c686965ba6f667f75723e362fb92ce1b",
"tierra-de-campeones-web/.git/logs/refs/remotes/origin/HEAD": "711e30f1e233d156fd258609d40c837b",
"tierra-de-campeones-web/.git/logs/refs/remotes/origin/main": "4f8a9d9b14fe197b37134e9485dc9389",
"tierra-de-campeones-web/.git/objects/00/22b51877f1066d78b896cb2765b7ddf417dfcf": "889f8430c417cc97e420cf8c98575ea0",
"tierra-de-campeones-web/.git/objects/05/8a5f9fb4002d7bfdc25044a962d06f19bf4c40": "edbe0910e28ba316eabc49f80b4aa2d2",
"tierra-de-campeones-web/.git/objects/08/27c17254fd3959af211aaf91a82d3b9a804c2f": "360dc8df65dabbf4e7f858711c46cc09",
"tierra-de-campeones-web/.git/objects/09/3c21a59af3293a0f8add48be2e6ba8bf56b02b": "bec738ccbb995c0fea9822b6c3907464",
"tierra-de-campeones-web/.git/objects/1b/e956f3cfd469c78b51b67f1cbfc62b43067c25": "b0ec4c7d98929efc598de50560c93792",
"tierra-de-campeones-web/.git/objects/23/092e3d4fa08b84da59ee0e3a1a5232299e4f7f": "48cdb7ec1aff68d62a36f4072a0963b0",
"tierra-de-campeones-web/.git/objects/23/e1ba9d2456567dc0d414f887d306d8aae869f0": "cc2e12e2444617ee01874f16a1c95ca1",
"tierra-de-campeones-web/.git/objects/2f/f27d223510f86b060e8df27835ce7a19a3de72": "e74b9b24a91b2119f8d2af4436e42dc7",
"tierra-de-campeones-web/.git/objects/37/653cf38071c61fa17074ab9e81881eb2827422": "b3c34005238f65dba3b7461e0c6216c5",
"tierra-de-campeones-web/.git/objects/38/d9436ee404cffeb64ebd82e1b724d45fd8ded6": "0e7febc22d09cdcf9b4dd801e1aa0ef2",
"tierra-de-campeones-web/.git/objects/3a/8cda5335b4b2a108123194b84df133bac91b23": "1636ee51263ed072c69e4e3b8d14f339",
"tierra-de-campeones-web/.git/objects/43/da73b7386e9b72073cbbba33408451ed514af0": "ecfd87098bd9bb3ab781b20d4fe3f4e0",
"tierra-de-campeones-web/.git/objects/47/6f179060eaa7e882d0e81457ee356dde762481": "de2325d1c1d96223b19c1d35c8405f1b",
"tierra-de-campeones-web/.git/objects/4c/7e825c3043d541ed93432d1383a65a56e29f9e": "912199f6cce27481c30a824e0db5156e",
"tierra-de-campeones-web/.git/objects/4d/bdc5ad7262f4eb9189394d2fe0b9cfde1884b1": "91b1a85c6634aa29128a5fe5e9939cb4",
"tierra-de-campeones-web/.git/objects/51/03e757c71f2abfd2269054a790f775ec61ffa4": "d437b77e41df8fcc0c0e99f143adc093",
"tierra-de-campeones-web/.git/objects/52/143f8f88ba8727a398f9144bb6329d43c487da": "a85a40b5b39d7912415de71de5c70d8b",
"tierra-de-campeones-web/.git/objects/52/79190d34d9905368fadfe00a1ff52d22be7a64": "63e9b1861443cb2faa23ae0a9d9bcc04",
"tierra-de-campeones-web/.git/objects/68/43fddc6aef172d5576ecce56160b1c73bc0f85": "2a91c358adf65703ab820ee54e7aff37",
"tierra-de-campeones-web/.git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
"tierra-de-campeones-web/.git/objects/6c/8712955da126c385c13065516f1c848c981658": "a45b6acd387e2a85a51cefd84c760e54",
"tierra-de-campeones-web/.git/objects/6c/cda438a42e94127532aa5bfb84fe4ccb440978": "606ce325d4dd84e02e61c5a4a1977fe6",
"tierra-de-campeones-web/.git/objects/6f/7661bc79baa113f478e9a717e0c4959a3f3d27": "985be3a6935e9d31febd5205a9e04c4e",
"tierra-de-campeones-web/.git/objects/6f/9509c88bed7080d496fc5e1d87a9315e30549d": "c02716d7aaed30ce1c5697a2fb40d317",
"tierra-de-campeones-web/.git/objects/70/bff2f8e24fb0f4c77ce53b4c3b31c67286b0de": "d74c6232c77a55f94f8a85a1e0c12682",
"tierra-de-campeones-web/.git/objects/76/d7d3f776d0b2f81241f09612a57f361a50d8b8": "9c5c874a2b8b7508f77f238b5f6874d0",
"tierra-de-campeones-web/.git/objects/7a/a13a7f2c0338e9dba83152c429e7a7825f6a84": "b0d2fe4c8eaa46cbfc7239d0beba3846",
"tierra-de-campeones-web/.git/objects/7b/bfb9874c4dab26e3296c42239776df486b4a4f": "88c31ec72ed931e12ee4e57c6c9fba0a",
"tierra-de-campeones-web/.git/objects/7c/2df4b8662185b148fc2836dfad1f91f2c8f076": "e243ac7647a4d96ce9fe1fe384a7049a",
"tierra-de-campeones-web/.git/objects/7c/3463b788d022128d17b29072564326f1fd8819": "37fee507a59e935fc85169a822943ba2",
"tierra-de-campeones-web/.git/objects/7e/58959d4cc41c639a4392181fb5fdb48f93dc71": "872f90660368cfe093d391d9769b4bcb",
"tierra-de-campeones-web/.git/objects/84/051bb10bcbb1b5a5652e3c78a28f52814c1535": "44e62c3960adbbb46fbfd459f97b8996",
"tierra-de-campeones-web/.git/objects/85/63aed2175379d2e75ec05ec0373a302730b6ad": "997f96db42b2dde7c208b10d023a5a8e",
"tierra-de-campeones-web/.git/objects/88/a3fc49e4dd70d0c58ef118821705f034d3a905": "f0754484ed9c16f64535bd26127edc99",
"tierra-de-campeones-web/.git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
"tierra-de-campeones-web/.git/objects/8a/919721908cc31f057035646fec5a305c1d73e3": "567a532cd21c0c095a6e438a781c47ec",
"tierra-de-campeones-web/.git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
"tierra-de-campeones-web/.git/objects/8a/b8a14cbeee11b3954a3402fe1e5ec471d3dff2": "1703eee3af083eab41324c07cb0b33ad",
"tierra-de-campeones-web/.git/objects/8e/21753cdb204192a414b235db41da6a8446c8b4": "1e467e19cabb5d3d38b8fe200c37479e",
"tierra-de-campeones-web/.git/objects/8e/9b605a5df86bfbb43a2966c5f20cebd221ab15": "d32c1727cad3cc16c12dfcf2d551cc9f",
"tierra-de-campeones-web/.git/objects/93/b363f37b4951e6c5b9e1932ed169c9928b1e90": "c8d74fb3083c0dc39be8cff78a1d4dd5",
"tierra-de-campeones-web/.git/objects/99/7bc759d9b5f84ff9b1577ed438c7bf65d2336e": "5baf18a4e831ef752466eac8d1e4df32",
"tierra-de-campeones-web/.git/objects/9d/54e7b0b8d5a2b9d1a38159308344581bf3ee9a": "0c2aff1981cdf07f830b229facb7973a",
"tierra-de-campeones-web/.git/objects/9f/fd4c6d4c8b8dcd7e1e95a7e24893669f9412b9": "cd9253c3d1318882b1c325d23594c19f",
"tierra-de-campeones-web/.git/objects/a0/4a193bb48856956ea534c0606418a451918f1b": "d09496dcab1e2a0343ca16b658e5adc5",
"tierra-de-campeones-web/.git/objects/a1/e16071c06b80217725da8a300b01a28e3f9c51": "2eec7f946131f85b27468ec2ac406f75",
"tierra-de-campeones-web/.git/objects/a4/ccb6665b311ea87a0f360195a3486f6d4e6192": "9bcab4be38acc5009a334b6d6d005491",
"tierra-de-campeones-web/.git/objects/a6/9302b58a0b5f448fb6bb99ed373f05288d2fe1": "82b4cfeb9e9cf9183424beaab51e3c38",
"tierra-de-campeones-web/.git/objects/a7/3f4b23dde68ce5a05ce4c658ccd690c7f707ec": "ee275830276a88bac752feff80ed6470",
"tierra-de-campeones-web/.git/objects/a7/a7db6096c03ee5506d9fe5db601d23fef75af8": "07f0c5074885953450cfbdb998401f6f",
"tierra-de-campeones-web/.git/objects/a9/ded535fef0ca5ac224d1f45c74ed9dd3b3e472": "f6e21bb5a2d0369d1aaac756dbdbaeec",
"tierra-de-campeones-web/.git/objects/ab/ef7f17bb070decb9d1a3e7fb1923beafe6496a": "e023cfc947a3b85bb65f26b3fb4784fc",
"tierra-de-campeones-web/.git/objects/ad/ced61befd6b9d30829511317b07b72e66918a1": "37e7fcca73f0b6930673b256fac467ae",
"tierra-de-campeones-web/.git/objects/b2/b7a67dd660d023413860de3cdc635b4fee6fb7": "ee2e5e0fcca00a7586cdd5a733e1e231",
"tierra-de-campeones-web/.git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
"tierra-de-campeones-web/.git/objects/b8/69e15ef1ace57e59e0e3987a778f0286caa952": "9dce20544de3c52d29be5555d9f3caf2",
"tierra-de-campeones-web/.git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
"tierra-de-campeones-web/.git/objects/b9/3cc4363b88699fd0454e6a515e24bad0413698": "c1144a17257d579584e1ef9fedb7a39d",
"tierra-de-campeones-web/.git/objects/b9/3e39bd49dfaf9e225bb598cd9644f833badd9a": "666b0d595ebbcc37f0c7b61220c18864",
"tierra-de-campeones-web/.git/objects/bf/4ec269063abaf3d2590b525e6a00b953cd087a": "773e5e47b146f780daf16c326aceaafc",
"tierra-de-campeones-web/.git/objects/c2/67ecd4855980e309520cb912b876f385de20e7": "48acd0fbfe6c5940ec46dec85092343d",
"tierra-de-campeones-web/.git/objects/c5/f04ac3ac89fa609916689178b6a42fc45fe19c": "8a4075ebe0e9f5ea59f0707af38b68b0",
"tierra-de-campeones-web/.git/objects/c6/c2d44d1be32b8abbdc42d8da85d80551870218": "3af89037f004688aba4ad3a6367bc38d",
"tierra-de-campeones-web/.git/objects/c8/3af99da428c63c1f82efdcd11c8d5297bddb04": "144ef6d9a8ff9a753d6e3b9573d5242f",
"tierra-de-campeones-web/.git/objects/cb/c65e25b42c7accb0a0e29eb294b7372f14619f": "5b56ed5ad4ef536a1edf255fefe043df",
"tierra-de-campeones-web/.git/objects/d3/4fa5bbb9640ecb1d95a1b3da475371d7e0abe1": "da2a9e81917c32cbf56843524136fa6e",
"tierra-de-campeones-web/.git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
"tierra-de-campeones-web/.git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
"tierra-de-campeones-web/.git/objects/d9/5b1d3499b3b3d3989fa2a461151ba2abd92a07": "a072a09ac2efe43c8d49b7356317e52e",
"tierra-de-campeones-web/.git/objects/d9/dc0146cdddb01b9097204945fce07c29a8ac98": "5b8383d7c7584bd77c422740b7cc503b",
"tierra-de-campeones-web/.git/objects/df/e0770424b2a19faf507a501ebfc23be8f54e7b": "76f8baefc49c326b504db7bf751c967d",
"tierra-de-campeones-web/.git/objects/e6/11b14463477302b4b684911e30d1f75c01000f": "a5da6dea70a1777cb69d9d9586ce7e44",
"tierra-de-campeones-web/.git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
"tierra-de-campeones-web/.git/objects/eb/6dd0214a982ef29c283697bbfd2912483ca9e3": "c3924c682335f7f646655d12032d47be",
"tierra-de-campeones-web/.git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
"tierra-de-campeones-web/.git/objects/ed/d990a6b4a972cc2a0a4df30efc171244d37fe2": "404db3c3f07afc16a33b1b586b253d95",
"tierra-de-campeones-web/.git/objects/ef/d2f8f5b346464ff7d350c5197c62128fd89ee4": "de91b1ae0562107afbc155b2b4ecf644",
"tierra-de-campeones-web/.git/objects/f3/3e0726c3581f96c51f862cf61120af36599a32": "afcaefd94c5f13d3da610e0defa27e50",
"tierra-de-campeones-web/.git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
"tierra-de-campeones-web/.git/objects/f6/e6c75d6f1151eeb165a90f04b4d99effa41e83": "95ea83d65d44e4c524c6d51286406ac8",
"tierra-de-campeones-web/.git/objects/fb/42722419b33a02c9308b7cb3a28e54f3ef849f": "9b5d6e3e703d7ca20ac5f0d16cc58e4f",
"tierra-de-campeones-web/.git/objects/fd/05cfbc927a4fedcbe4d6d4b62e2c1ed8918f26": "5675c69555d005a1a244cc8ba90a402c",
"tierra-de-campeones-web/.git/objects/pack/pack-7a2910026b1165a6ad1f8c7c70257aacadb589ef.idx": "b0c4612e2da33858e193d6a809cddc18",
"tierra-de-campeones-web/.git/objects/pack/pack-7a2910026b1165a6ad1f8c7c70257aacadb589ef.pack": "34cf4402cd11caa03a8ae6595d83606f",
"tierra-de-campeones-web/.git/objects/pack/pack-7a2910026b1165a6ad1f8c7c70257aacadb589ef.rev": "5e97fc445463e89574acb8335a2c9f9e",
"tierra-de-campeones-web/.git/refs/heads/main": "25567b3fcf5842c55fe646edfb7df226",
"tierra-de-campeones-web/.git/refs/remotes/origin/HEAD": "98b16e0b650190870f1b40bc8f4aec4e",
"tierra-de-campeones-web/.git/refs/remotes/origin/main": "62b18a9415dc12639d69fc5fb0941020",
"tierra-de-campeones-web/assets/AssetManifest.bin": "37496e161a07dc1d551f798360831a29",
"tierra-de-campeones-web/assets/AssetManifest.bin.json": "a0a63bd018b8332e82807ff3273ff8c8",
"tierra-de-campeones-web/assets/assets/images/boxer.png": "17c80df349c1ba23ad0fbb50a3f53983",
"tierra-de-campeones-web/assets/assets/images/gloves.png": "ec9a71ad043e4f80e9c304611cee3fb3",
"tierra-de-campeones-web/assets/assets/images/logo.png": "9b85c811442ff59dc15869b8f0f628cd",
"tierra-de-campeones-web/assets/assets/images/ring.png": "d2bf03db79f9e845944bf06e9e90f651",
"tierra-de-campeones-web/assets/assets/sounds/bell.mp3": "71c5e6d71e18121f2a4bc359778d1324",
"tierra-de-campeones-web/assets/assets/sounds/breath.mp3": "4eb1fad2da12eb5e7599432f1ed63d3a",
"tierra-de-campeones-web/assets/assets/sounds/heartbeat.mp3": "3e19380b64c7c694e36a090acb8730f5",
"tierra-de-campeones-web/assets/assets/sounds/stadium_ambient.mp3": "afe7ab54589de6c69f05df354647141d",
"tierra-de-campeones-web/assets/FontManifest.json": "c75f7af11fb9919e042ad2ee704db319",
"tierra-de-campeones-web/assets/fonts/MaterialIcons-Regular.otf": "787241d666bf3a89440e022785ab71d0",
"tierra-de-campeones-web/assets/NOTICES": "a9debe5c4ef0bc866addc61191aade3f",
"tierra-de-campeones-web/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"tierra-de-campeones-web/assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "4f36c6deccdae137be6a2d6c6881be3f",
"tierra-de-campeones-web/assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "a6e284904fe0b3673fdd2818cf91e238",
"tierra-de-campeones-web/assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "c70c72e03b892c19e5aed879f60c0d78",
"tierra-de-campeones-web/assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"tierra-de-campeones-web/assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"tierra-de-campeones-web/assets/packages/youtube_player_iframe/assets/player.html": "663ba81294a9f52b1afe96815bb6ecf9",
"tierra-de-campeones-web/assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"tierra-de-campeones-web/assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"tierra-de-campeones-web/canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"tierra-de-campeones-web/canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"tierra-de-campeones-web/canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"tierra-de-campeones-web/canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"tierra-de-campeones-web/canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"tierra-de-campeones-web/canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"tierra-de-campeones-web/canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"tierra-de-campeones-web/canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"tierra-de-campeones-web/canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"tierra-de-campeones-web/canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"tierra-de-campeones-web/canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"tierra-de-campeones-web/canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"tierra-de-campeones-web/favicon.png": "5dcef449791fa27946b3d35ad8803796",
"tierra-de-campeones-web/flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"tierra-de-campeones-web/flutter_bootstrap.js": "a04e62bdd2ae6b1d30cba2d2b2efecf9",
"tierra-de-campeones-web/guia_despliegue.txt": "023348df571e9f4e4da5e93fe8b74551",
"tierra-de-campeones-web/icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"tierra-de-campeones-web/icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"tierra-de-campeones-web/icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"tierra-de-campeones-web/icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"tierra-de-campeones-web/index.html": "69b8972fecc2822fbea7e1fa71ad5399",
"tierra-de-campeones-web/main.dart.js": "9a2cdc2b459c296730cd384b2012f9f3",
"tierra-de-campeones-web/manifest.json": "7a102ae8ca60e638c4a4688d5a277071",
"tierra-de-campeones-web/vercel.json": "16954adafdbea58b04cfe4e382f44d60",
"tierra-de-campeones-web/version.json": "07a3085287217fe2549dc9fa5764ab01",
"vercel.json": "16954adafdbea58b04cfe4e382f44d60",
"version.json": "07a3085287217fe2549dc9fa5764ab01"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
