// All text in the game, Dutch and English, plus the cutscene scripts.

HashMap<String, HashMap<String, String>> TEXT = new HashMap<String, HashMap<String, String>>();
HashMap<String, CutStep[]> CUTS = new HashMap<String, CutStep[]>();

class CutActor {
  String kind;
  int x;
  String pose;
  boolean flip;
  String look;

  CutActor(String kind, int x, String pose, int flip) {
    this(kind, x, pose, flip, "");
  }

  CutActor(String kind, int x, String pose, int flip, String look) {
    this.kind = kind;
    this.x = x;
    this.pose = pose;
    this.flip = flip != 0;
    this.look = look != null ? look : "";
  }
}

class CutStep {
  String bg;
  CutActor[] a;
  String who;
  String k;
  int card;
  String fx;
  boolean shake;
  int len;

  CutStep(int card) {
    this.card = card;
    this.a = new CutActor[0];
  }

  CutStep(String bg, CutActor[] a, String who, String k) {
    this(bg, a, who, k, null, false);
  }

  CutStep(String bg, CutActor[] a, String who, String k, String fx, boolean shake) {
    this.bg = bg;
    this.a = a != null ? a : new CutActor[0];
    this.who = who;
    this.k = k;
    this.fx = fx;
    this.shake = shake;
    this.card = 0;
  }
}

CutActor act(String kind, int x, String pose, int flip) {
  return new CutActor(kind, x, pose, flip);
}

CutActor act(String kind, int x, String pose, int flip, String look) {
  return new CutActor(kind, x, pose, flip, look);
}

CutStep cardStep(int c) {
  return new CutStep(c);
}

CutStep cutStep(String bg, CutActor[] a, String who, String k) {
  return new CutStep(bg, a, who, k, null, false);
}

CutStep cutStep(String bg, CutActor[] a, String who, String k, String fx, boolean shake) {
  return new CutStep(bg, a, who, k, fx, shake);
}

void initText() {
  if (!TEXT.isEmpty()) return;

  HashMap<String, String> nl = new HashMap<String, String>();
  nl.put("title", "DE DONKERE NACHT");
  nl.put("sub", "een eerbetoon aan het spel uit 2016");
  nl.put("credit", "gemaakt door AIK EN JOB de donkere nacht!");
  nl.put("m_solo", "Alleen spelen");
  nl.put("m_local", "Samen op 1 computer");
  nl.put("m_host", "Online: spel hosten");
  nl.put("m_join", "Online: meedoen");
  nl.put("m_chapter", "Hoofdstuk");
  nl.put("m_lang", "Taal: Nederlands");
  nl.put("m_controls", "Besturing");
  nl.put("m_music", "Muziek");
  nl.put("on", "aan");
  nl.put("off", "uit");
  nl.put("nav", "Kies met pijltjes of stick - Enter / X = ok");
  nl.put("back", "Esc / O = terug");
  nl.put("p1dev", "Speler 1");
  nl.put("p2dev", "Speler 2");
  nl.put("d_kb1", "Toetsenbord A/D W F");
  nl.put("d_kb2", "Toetsenbord pijltjes Enter");
  nl.put("d_mouse", "Muis (zoals in 2016)");
  nl.put("d_pad0", "Controller 1");
  nl.put("d_pad1", "Controller 2");
  nl.put("d_all", "Alles");
  nl.put("c_head", "BESTURING");
  nl.put("c_move", "Lopen");
  nl.put("c_jump", "Springen");
  nl.put("c_bite", "Bijten");
  nl.put("c_pause", "Pauze");
  nl.put("t_kb1", "Toetsen 1");
  nl.put("t_kb2", "Toetsen 2");
  nl.put("t_mouse", "Muis");
  nl.put("t_pad", "Controller");
  nl.put("c_kb1", "A / D|W of spatie|F|Esc");
  nl.put("c_kb2", "pijltjes|pijl omhoog|Enter|Esc");
  nl.put("c_mouse", "knop L / R|wiel omhoog|wielklik|");
  nl.put("c_pad", "stick / d-pad|kruisje|vierkantje|Options");
  nl.put("c_note", "Alleen: alle apparaten besturen jouw zombie.");
  nl.put("host_head", "ONLINE SPEL HOSTEN");
  nl.put("host_code", "Geef deze code aan speler 2:");
  nl.put("host_wait", "Wachten op speler 2...");
  nl.put("host_ready", "Speler 2 is er! Druk op ok om te beginnen.");
  nl.put("join_head", "ONLINE MEEDOEN");
  nl.put("join_code", "Typ de code van de host:");
  nl.put("join_go", "Verbinden...");
  nl.put("join_ok", "Verbonden! Wachten tot de host begint...");
  nl.put("net_err", "Verbinden is mislukt. Controleer de code.");
  nl.put("net_lost", "De verbinding is verbroken.");
  nl.put("paused", "PAUZE");
  nl.put("resume", "Verder spelen");
  nl.put("tomenu", "Terug naar menu");
  nl.put("over", "OEPS...");
  nl.put("over_sun", "DE ZON IS OP!");
  nl.put("over_hint", "Druk op bijten om het opnieuw te proberen");
  nl.put("chapter", "HOOFDSTUK");
  nl.put("ch1", "Het Ontwaken");
  nl.put("ch2", "Het Huis");
  nl.put("ch3", "De Lachende WC");
  nl.put("ch4", "HELP ZOMBIES");
  nl.put("ch5", "De Arena");
  nl.put("next", "verder");
  nl.put("who_n", "");
  nl.put("who_z1", "Schutter");
  nl.put("who_z2", "Schutter");
  nl.put("who_t", "De dief");
  nl.put("who_wc", "De Lachende WC");
  nl.put("who_g", "De reus");

  nl.put("g_field", "Bijt het hek van het kerkhof open");
  nl.put("g_forest", "Zoek de oranje draadjes");
  nl.put("g_house", "Pak de sleutel van de kraai");
  nl.put("g_house2", "Open de voordeur");
  nl.put("g_hall", "Steek de kaarsen aan");
  nl.put("g_bath", "Bijt de WC als het deksel open is");
  nl.put("g_bed", "Sluip naar het bed. Loop alleen als hij snurkt");
  nl.put("g_chase", "Blijf de dief bij!");
  nl.put("g_arena", "Pak het doek terug voor de zon opkomt");
  nl.put("g_giant", "Trap een badeend onder zijn voet!");
  nl.put("g_giant2", "Bijt zijn hoofd!");
  nl.put("g_go", "Loop naar rechts");
  nl.put("h_move", "Lopen: A / D, pijltjes, muisknoppen of stick");
  nl.put("h_jump", "Springen: W, spatie, pijl omhoog of kruisje");
  nl.put("h_bite", "Bijten: F, Enter of vierkantje");
  nl.put("h_flame", "Pak het vuur bij een brandende kaars (bijten)");
  nl.put("h_flame2", "Breng het vuur snel naar een kaars");
  nl.put("h_still", "STIL STAAN!");
  nl.put("h_walk", "Hij snurkt. Lopen maar");
  nl.put("h_kick", "Bijt een badeend om hem weg te trappen");
  nl.put("h_wait", "Wacht op een badeend van de WC");
  nl.put("h_stomp", "Hij stampt! Spring over de schokgolf");
  nl.put("h_fist", "Loop weg uit de schaduw!");
  nl.put("h_head", "Hij ligt op zijn rug! Bijt zijn hoofd");
  nl.put("roar", "GROOAAAR!");
  nl.put("w_duck", "Kwak! Een badeend!");
  nl.put("w_slip", "HAHAHA! Uitgegleden!");
  nl.put("w_up", "Oei! Hij staat weer op!");
  nl.put("w_h1", "Hé reus! Wat een stinkvoeten!");
  nl.put("w_h2", "Groot, groen en sloom! HAHAHA!");
  nl.put("w_h3", "Mijn eendjes zijn sneller!");
  nl.put("w_h4", "Kijk uit, zombies! HAHAHA!");
  nl.put("w_miss", "Die moet je trappen, zombies!");
  nl.put("w_brain", "Hier, hersens! Voor later!");
  nl.put("z_tomb", "Sorry, buurman. Slaap lekker.");
  nl.put("z_bat", "Vleermuis. Smaakt naar stof.");
  nl.put("z_key", "Sleutel! Hersens komen later.");
  nl.put("z_dark", "Wie heeft het licht uitgedaan?");
  nl.put("z_candle", "Hè hè. Gezellig.");
  nl.put("z_gnome", "Sorry, kabouter!");
  nl.put("z_wc", "Een pratende wc. Ook dat nog.");
  nl.put("z_roll", "Oeps. Dat rolt nog lang door.");
  nl.put("z_duck", "Sssst, eendje!");
  nl.put("z_hurt1", "Au! Gelukkig ben ik al dood.");
  nl.put("z_hurt2", "Au! Mijn mooie hoed!");
  nl.put("z_brain", "Hersens! Die bewaar ik voor later.");
  nl.put("z_gold", "Ik glim als een schilderij!");
  nl.put("z_chick", "Een kip! Daar bijt ik verder mee.");
  nl.put("z_chase", "Rennen! Hersens komen later!");
  nl.put("z_slip", "Hij ligt! Bijten maar!");
  nl.put("z_giant", "Hij is groot. Wij zijn snel.");
  nl.put("z_head", "Oeps. Even mijn hoofd erbij houden.");
  nl.put("s_0", "Mmm... rijk... ik ben rijk...");
  nl.put("s_1", "Hihi... niemand merkt het...");
  nl.put("s_2", "Nog vijf minuutjes, mama...");
  nl.put("s_3", "Mijn schilderij... van mij...");
  nl.put("wanted", "GEZOCHT");
  nl.put("t_go", "Ga weg!");
  nl.put("t_help", "Help!");
  nl.put("t_mama", "Mama!");
  nl.put("cheer", "JOEPIE!");
  nl.put("boo", "BOE!");
  nl.put("m_locked", "Op slot. De kraai heeft de sleutel.");
  nl.put("m_key", "De sleutel!");
  nl.put("m_caught", "Hij hoorde iets! Terug naar de deur...");
  nl.put("m_out", "Het vuur is uit.");
  nl.put("noise", "LAWAAI");
  nl.put("leven", "LEVEN");
  nl.put("sun", "ZONSOPGANG");
  nl.put("dist", "ARENA");
  nl.put("end1", "THE END GAME");
  nl.put("end2", "Een eerbetoon aan De Donkere Nacht (2016)");
  nl.put("end3", "gemaakt door AIK EN JOB");
  nl.put("end4", "De Jonge Onderzoekers, Groningen");
  nl.put("end5", "Druk op ok voor het menu");

  nl.put("c_i1", "De donkerste nacht van het jaar. In het museum hangt De Nachtwacht, al bijna vierhonderd jaar.");
  nl.put("c_i2", "Vannacht sluipt er een man in een oranje pak naar binnen.");
  nl.put("c_i3", "De twee mooiste mannetjes snij ik er gewoon uit. Niemand die het merkt!");
  nl.put("c_i4", "Maar iemand merkte het wel.");
  nl.put("c_i5", "Diep onder de grond werden twee schutters van de Nachtwacht wakker.");
  nl.put("c_i6", "Uuurgh... ons schilderij...");
  nl.put("c_i7", "...is stuk. Hersens komen later. Eerst die dief.");
  nl.put("c_h1", "Oranje draadjes. Het spoor loopt naar dat huis.");
  nl.put("c_h2", "Hij heeft een voordeur. Wij hebben tanden.");
  nl.put("c_p1", "In het kaarslicht hangt hun schilderij. Met een gat in het midden.");
  nl.put("c_p2", "Hij heeft precies ons eruit gesneden!");
  nl.put("c_p3", "Dan heeft hij ons nog bij zich. Verder zoeken.");
  nl.put("c_w1", "HAHAHA! Zombies! In MIJN badkamer!");
  nl.put("c_w2", "Opzij, pot.");
  nl.put("c_w3", "Niemand komt langs de Lachende WC! HAHAHA!");
  nl.put("c_w4", "Au! Au! Genoeg! Hij slaapt hiernaast, achter die deur!");
  nl.put("c_w5", "Wel zachtjes doen. Hij wordt altijd chagrijnig wakker. Hihi.");
  nl.put("c_b1", "De dief slaapt. Onder zijn kussen ligt een opgerold stuk doek.");
  nl.put("c_b2", "Sssst. Alleen lopen als hij snurkt.");
  nl.put("c_b3", "Hè? Wat... groen... tanden...");
  nl.put("c_b4", "HELP! ZOMBIES!");
  nl.put("c_b5", "Hij plakt snel een pleister op zijn bil. Dan grist hij het doek mee en rent de nacht in.");
  nl.put("c_b6", "AU! Mijn bil!");
  nl.put("c_b7", "Oeps. Dat was per ongeluk.");
  nl.put("c_a1", "De oude arena. Geen uitgang. En aan de horizon wordt het al licht.");
  nl.put("c_a2", "Blijf uit mijn buurt! Ik heb... stenen!");
  nl.put("c_a3", "Voor de zon op is.");
  nl.put("c_t1", "Oké, oké! Hier is jullie stomme doek! Ik stop ermee!");
  nl.put("c_t2", "Maar... waarom jeukt mijn bil zo? Het jeukt en jeukt en jeukt...");
  nl.put("c_t3", "Eh... dat komt door die beet. Je wordt helemaal groen.");
  nl.put("c_t4", "Hij krabt en krabt. En hij groeit. En groeit. En GROEIT.");
  nl.put("c_t5", "GROOOAAAR! Nu ben IK de baas! Ik stamp jullie plat!");
  nl.put("c_t6", "HAHAHA! Ik kwam even kijken! Een reus op blote voeten? Ik heb badeendjes. Daar glijdt hij vast over uit!");
  nl.put("c_t7", "En als hij op de grond ligt, bijten we in zijn hoofd. Snel, voor de zon op is!");
  nl.put("c_e1", "BOEM! De reus valt op zijn rug en blijft liggen.");
  nl.put("c_e2", "Daar komt de eerste zonnestraal. Precies op zijn neus.");
  nl.put("c_e3", "En pfff... de reus valt uit elkaar tot een hoopje stof. Alleen de pleister blijft over.");
  nl.put("c_e4", "Pak het doek! Snel, voor de zon ons ook vindt!");
  nl.put("c_e5", "Net op tijd hingen ze het doek terug. Toen stapten ze weer in de verf.");
  nl.put("c_e6", "Slapen. Eindelijk. Wie goed kijkt, ziet ze in een donkere nacht nog weleens knipogen.");
  nl.put("c_e7", "HAHAHA! En die pleister hang ik in mijn badkamer. Als aandenken! HAHAHA!");

  HashMap<String, String> en = new HashMap<String, String>();
  en.put("title", "DE DONKERE NACHT");
  en.put("sub", "a tribute to the 2016 game");
  en.put("credit", "gemaakt door AIK EN JOB de donkere nacht!");
  en.put("m_solo", "Play alone");
  en.put("m_local", "Together on 1 computer");
  en.put("m_host", "Online: host a game");
  en.put("m_join", "Online: join a game");
  en.put("m_chapter", "Chapter");
  en.put("m_lang", "Language: English");
  en.put("m_controls", "Controls");
  en.put("m_music", "Music");
  en.put("on", "on");
  en.put("off", "off");
  en.put("nav", "Choose with arrows or stick - Enter / X = ok");
  en.put("back", "Esc / O = back");
  en.put("p1dev", "Player 1");
  en.put("p2dev", "Player 2");
  en.put("d_kb1", "Keyboard A/D W F");
  en.put("d_kb2", "Keyboard arrows Enter");
  en.put("d_mouse", "Mouse (like in 2016)");
  en.put("d_pad0", "Controller 1");
  en.put("d_pad1", "Controller 2");
  en.put("d_all", "Everything");
  en.put("c_head", "CONTROLS");
  en.put("c_move", "Walk");
  en.put("c_jump", "Jump");
  en.put("c_bite", "Bite");
  en.put("c_pause", "Pause");
  en.put("t_kb1", "Keys 1");
  en.put("t_kb2", "Keys 2");
  en.put("t_mouse", "Mouse");
  en.put("t_pad", "Controller");
  en.put("c_kb1", "A / D|W or space|F|Esc");
  en.put("c_kb2", "arrows|up arrow|Enter|Esc");
  en.put("c_mouse", "button L / R|wheel up|wheel click|");
  en.put("c_pad", "stick / d-pad|cross|square|Options");
  en.put("c_note", "Alone: every device controls your zombie.");
  en.put("host_head", "HOST AN ONLINE GAME");
  en.put("host_code", "Give this code to player 2:");
  en.put("host_wait", "Waiting for player 2...");
  en.put("host_ready", "Player 2 is here! Press ok to start.");
  en.put("join_head", "JOIN AN ONLINE GAME");
  en.put("join_code", "Type the code from the host:");
  en.put("join_go", "Connecting...");
  en.put("join_ok", "Connected! Waiting for the host to start...");
  en.put("net_err", "Could not connect. Check the code.");
  en.put("net_lost", "The connection was lost.");
  en.put("paused", "PAUSED");
  en.put("resume", "Keep playing");
  en.put("tomenu", "Back to menu");
  en.put("over", "OOPS...");
  en.put("over_sun", "THE SUN IS UP!");
  en.put("over_hint", "Press bite to try again");
  en.put("chapter", "CHAPTER");
  en.put("ch1", "The Awakening");
  en.put("ch2", "The House");
  en.put("ch3", "The Laughing Toilet");
  en.put("ch4", "HELP ZOMBIES");
  en.put("ch5", "The Arena");
  en.put("next", "next");
  en.put("who_n", "");
  en.put("who_z1", "Guard");
  en.put("who_z2", "Guard");
  en.put("who_t", "The thief");
  en.put("who_wc", "The Laughing Toilet");
  en.put("who_g", "The giant");

  en.put("g_field", "Bite the graveyard gate open");
  en.put("g_forest", "Find the orange threads");
  en.put("g_house", "Get the key from the crow");
  en.put("g_house2", "Open the front door");
  en.put("g_hall", "Light the candles");
  en.put("g_bath", "Bite the toilet when the lid is open");
  en.put("g_bed", "Sneak to the bed. Only walk while he snores");
  en.put("g_chase", "Keep up with the thief!");
  en.put("g_arena", "Get the canvas back before sunrise");
  en.put("g_giant", "Kick a rubber duck under his foot!");
  en.put("g_giant2", "Bite his head!");
  en.put("g_go", "Walk to the right");
  en.put("h_move", "Walk: A / D, arrows, mouse buttons or stick");
  en.put("h_jump", "Jump: W, space, up arrow or cross");
  en.put("h_bite", "Bite: F, Enter or square");
  en.put("h_flame", "Take the fire from a burning candle (bite)");
  en.put("h_flame2", "Carry the fire to a candle, quickly");
  en.put("h_still", "STAND STILL!");
  en.put("h_walk", "He is snoring. Go");
  en.put("h_kick", "Bite a rubber duck to kick it");
  en.put("h_wait", "Wait for a rubber duck from the toilet");
  en.put("h_stomp", "He stomps! Jump over the shock wave");
  en.put("h_fist", "Get out of the shadow!");
  en.put("h_head", "He is on his back! Bite his head");
  en.put("roar", "ROOAAAR!");
  en.put("w_duck", "Quack! A rubber duck!");
  en.put("w_slip", "HAHAHA! He slipped!");
  en.put("w_up", "Uh-oh! He is getting up!");
  en.put("w_h1", "Hey giant! Smelly feet!");
  en.put("w_h2", "Big, green and slow! HAHAHA!");
  en.put("w_h3", "My ducks are faster!");
  en.put("w_h4", "Look out, zombies! HAHAHA!");
  en.put("w_miss", "You have to kick it, zombies!");
  en.put("w_brain", "Here, brains! For later!");
  en.put("z_tomb", "Sorry, neighbour. Sleep well.");
  en.put("z_bat", "Bat. Tastes like dust.");
  en.put("z_key", "A key! Brains can wait.");
  en.put("z_dark", "Who turned the lights off?");
  en.put("z_candle", "There. Cosy.");
  en.put("z_gnome", "Sorry, gnome!");
  en.put("z_wc", "A talking toilet. Of course.");
  en.put("z_roll", "Oops. That will roll for ages.");
  en.put("z_duck", "Shhh, duckie!");
  en.put("z_hurt1", "Ow! Lucky I am already dead.");
  en.put("z_hurt2", "Ow! My nice hat!");
  en.put("z_brain", "Brains! Saving those for later.");
  en.put("z_gold", "I shine like a painting!");
  en.put("z_chick", "A chicken! Now I bite further.");
  en.put("z_chase", "Run! Brains can wait!");
  en.put("z_slip", "He is down! Bite!");
  en.put("z_giant", "He is big. We are quick.");
  en.put("z_head", "Oops. Must keep my head on.");
  en.put("s_0", "Mmm... rich... I am rich...");
  en.put("s_1", "Heehee... nobody will notice...");
  en.put("s_2", "Five more minutes, mum...");
  en.put("s_3", "My painting... all mine...");
  en.put("wanted", "WANTED");
  en.put("t_go", "Go away!");
  en.put("t_help", "Help!");
  en.put("t_mama", "Mummy!");
  en.put("cheer", "HOORAY!");
  en.put("boo", "BOO!");
  en.put("m_locked", "Locked. The crow has the key.");
  en.put("m_key", "The key!");
  en.put("m_caught", "He heard something! Back to the door...");
  en.put("m_out", "The fire went out.");
  en.put("noise", "NOISE");
  en.put("leven", "LEVEN");
  en.put("sun", "SUNRISE");
  en.put("dist", "ARENA");
  en.put("end1", "THE END GAME");
  en.put("end2", "A tribute to De Donkere Nacht (2016)");
  en.put("end3", "gemaakt door AIK EN JOB");
  en.put("end4", "De Jonge Onderzoekers, Groningen");
  en.put("end5", "Press ok for the menu");

  en.put("c_i1", "The darkest night of the year. In the museum hangs The Night Watch, as it has for almost four hundred years.");
  en.put("c_i2", "Tonight a man in an orange suit sneaks inside.");
  en.put("c_i3", "I will just cut out the two best little men. Nobody will notice!");
  en.put("c_i4", "But somebody did notice.");
  en.put("c_i5", "Deep under the ground, two guards of the Night Watch woke up.");
  en.put("c_i6", "Uuurgh... our painting...");
  en.put("c_i7", "...is broken. Brains can wait. First that thief.");
  en.put("c_h1", "Orange threads. The trail leads to that house.");
  en.put("c_h2", "He has a front door. We have teeth.");
  en.put("c_p1", "In the candlelight hangs their painting. With a hole in the middle.");
  en.put("c_p2", "He cut out exactly the two of us!");
  en.put("c_p3", "Then he still has us with him. Keep looking.");
  en.put("c_w1", "HAHAHA! Zombies! In MY bathroom!");
  en.put("c_w2", "Move over, pot.");
  en.put("c_w3", "Nobody gets past the Laughing Toilet! HAHAHA!");
  en.put("c_w4", "Ow! Ow! Enough! He sleeps next door, behind that door!");
  en.put("c_w5", "Do be quiet. He always wakes up grumpy. Heehee.");
  en.put("c_b1", "The thief is asleep. Under his pillow lies a rolled-up piece of canvas.");
  en.put("c_b2", "Shhh. Only walk while he snores.");
  en.put("c_b3", "Huh? What... green... teeth...");
  en.put("c_b4", "HELP! ZOMBIES!");
  en.put("c_b5", "He quickly sticks a plaster on his behind. Then he grabs the canvas and runs out into the night.");
  en.put("c_b6", "OW! My behind!");
  en.put("c_b7", "Oops. That was an accident.");
  en.put("c_a1", "The old arena. No way out. And on the horizon it is already getting light.");
  en.put("c_a2", "Stay away from me! I have... rocks!");
  en.put("c_a3", "Before the sun is up.");
  en.put("c_t1", "Okay, okay! Here is your stupid canvas! I give up!");
  en.put("c_t2", "But... why is my behind so itchy? It itches and itches and itches...");
  en.put("c_t3", "Er... that is from the bite. You are turning all green.");
  en.put("c_t4", "He scratches and scratches. And he grows. And grows. And GROWS.");
  en.put("c_t5", "GROOOAAAR! Now I am the boss! I will stomp you flat!");
  en.put("c_t6", "HAHAHA! I came to watch! A giant in bare feet? I have rubber ducks. He is sure to slip on those!");
  en.put("c_t7", "And when he is on the ground, we bite his head. Quick, before the sun is up!");
  en.put("c_e1", "BOOM! The giant falls on his back and stays down.");
  en.put("c_e2", "Here comes the first sunbeam. Right on his nose.");
  en.put("c_e3", "And poof... the giant crumbles into a little pile of dust. Only the plaster is left.");
  en.put("c_e4", "Grab the canvas! Quick, before the sun finds us too!");
  en.put("c_e5", "Just in time they hung the canvas back. Then they stepped into the paint again.");
  en.put("c_e6", "Sleep. At last. Look closely on a dark night and you may still catch them winking.");
  en.put("c_e7", "HAHAHA! And I am hanging that plaster in my bathroom. As a souvenir! HAHAHA!");

  TEXT.put("nl", nl);
  TEXT.put("en", en);

  CUTS.put("intro", new CutStep[] {
    cutStep("museum", new CutActor[] {}, "n", "c_i1"),
    cutStep("museum", new CutActor[] { act("thief", 150, "stand", 0) }, "n", "c_i2"),
    cutStep("museum2", new CutActor[] { act("thief", 215, "throw", 0) }, "t", "c_i3", "hit", false),
    cutStep("field", new CutActor[] {}, "n", "c_i4", "flush", true),
    cutStep("field", new CutActor[] { act("z0", 40, "rise", 0), act("z1", 62, "rise", 0) }, "n", "c_i5", null, true),
    cutStep("field", new CutActor[] { act("z0", 40, "idle", 0), act("z1", 62, "idle", 0) }, "z1", "c_i6"),
    cutStep("field", new CutActor[] { act("z0", 40, "idle", 0), act("z1", 62, "idle", 0) }, "z2", "c_i7"),
    cardStep(1)
  });

  CUTS.put("house", new CutStep[] {
    cutStep("house", new CutActor[] { act("z0", 60, "idle", 0), act("z1", 84, "idle", 0) }, "z1", "c_h1"),
    cutStep("house", new CutActor[] { act("z0", 60, "idle", 0), act("z1", 84, "bite", 0) }, "z2", "c_h2"),
    cardStep(2)
  });

  CUTS.put("hall", new CutStep[] {
    cutStep("hall_lit", new CutActor[] { act("z0", 200, "idle", 0), act("z1", 300, "idle", 1) }, "n", "c_p1"),
    cutStep("hall_lit", new CutActor[] { act("z0", 200, "bite", 0), act("z1", 300, "idle", 1) }, "z1", "c_p2"),
    cutStep("hall_lit", new CutActor[] { act("z0", 200, "idle", 0), act("z1", 300, "idle", 1) }, "z2", "c_p3")
  });

  CUTS.put("bath", new CutStep[] {
    cardStep(3),
    cutStep("bath", new CutActor[] { act("z0", 120, "idle", 0), act("z1", 144, "idle", 0), act("wc", 380, "laugh", 0) }, "wc", "c_w1", "laugh", false),
    cutStep("bath", new CutActor[] { act("z0", 120, "idle", 0), act("z1", 144, "idle", 0), act("wc", 380, "closed", 0) }, "z1", "c_w2"),
    cutStep("bath", new CutActor[] { act("z0", 120, "idle", 0), act("z1", 144, "idle", 0), act("wc", 380, "laugh", 0) }, "wc", "c_w3", "laugh", false)
  });

  CUTS.put("bathout", new CutStep[] {
    cutStep("bath", new CutActor[] { act("z0", 300, "idle", 0), act("z1", 324, "idle", 0), act("wc", 380, "hurt", 0) }, "wc", "c_w4"),
    cutStep("bath", new CutActor[] { act("z0", 300, "idle", 0), act("z1", 324, "idle", 0), act("wc", 380, "open", 0) }, "wc", "c_w5")
  });

  CUTS.put("bed", new CutStep[] {
    cardStep(4),
    cutStep("bed", new CutActor[] { act("z0", 40, "idle", 0), act("z1", 62, "idle", 0), act("bed", 380, "sleep", 0) }, "n", "c_b1"),
    cutStep("bed", new CutActor[] { act("z0", 40, "idle", 0), act("z1", 62, "idle", 0), act("bed", 380, "sleep", 0) }, "z2", "c_b2")
  });

  CUTS.put("bedout", new CutStep[] {
    cutStep("bed", new CutActor[] { act("z0", 318, "idle", 0), act("z1", 296, "idle", 0), act("bed", 380, "awake", 0) }, "t", "c_b3"),
    cutStep("bed", new CutActor[] { act("z0", 318, "bite", 0), act("z1", 296, "idle", 0), act("bed", 380, "empty", 0), act("thief", 420, "scared", 0) }, "t", "c_b4", "alarm", true),
    cutStep("bed", new CutActor[] { act("bed", 380, "empty", 0), act("z0", 386, "bite", 0), act("z1", 296, "idle", 0), act("thief", 404, "ouch", 0) }, "t", "c_b6", "bite", true),
    cutStep("bed", new CutActor[] { act("bed", 380, "empty", 0), act("z0", 386, "idle", 0), act("z1", 296, "idle", 0), act("thief", 440, "ouch", 0) }, "z1", "c_b7"),
    cutStep("bed", new CutActor[] { act("bed", 380, "empty", 0), act("z0", 386, "idle", 0), act("z1", 296, "idle", 0), act("thief", 440, "run", 0, "p") }, "n", "c_b5")
  });

  CUTS.put("arena", new CutStep[] {
    cardStep(5),
    cutStep("arena", new CutActor[] { act("z0", 50, "idle", 0), act("z1", 74, "idle", 0), act("thief", 400, "pant", 1, "p") }, "n", "c_a1"),
    cutStep("arena", new CutActor[] { act("z0", 50, "idle", 0), act("z1", 74, "idle", 0), act("thief", 400, "throw", 1, "p") }, "t", "c_a2"),
    cutStep("arena", new CutActor[] { act("z0", 50, "bite", 0), act("z1", 74, "idle", 0), act("thief", 400, "scared", 1, "p") }, "z1", "c_a3")
  });

  CUTS.put("turn", new CutStep[] {
    cutStep("arena", new CutActor[] { act("z0", 150, "idle", 0), act("z1", 126, "idle", 0), act("thief", 320, "throw", 1, "p2"), act("roll", 280, "", 0) }, "t", "c_t1", "throw", false),
    cutStep("arena", new CutActor[] { act("z0", 150, "idle", 0), act("z1", 126, "idle", 0), act("thief", 320, "itch", 1, "p2"), act("roll", 280, "", 0) }, "t", "c_t2"),
    cutStep("arena", new CutActor[] { act("z0", 150, "idle", 0), act("z1", 126, "idle", 0), act("thief", 320, "itch", 1, "p2"), act("roll", 280, "", 0) }, "z1", "c_t3"),
    cutStep("arena", new CutActor[] { act("z0", 150, "idle", 0), act("z1", 126, "idle", 0), act("grow", 320, "", 1), act("roll", 280, "", 0) }, "n", "c_t4", "grow", true),
    cutStep("arena", new CutActor[] { act("z0", 150, "idle", 0), act("z1", 126, "idle", 0), act("giant", 320, "roar", 1), act("roll", 280, "", 0) }, "g", "c_t5", "roar", true),
    cutStep("arena", new CutActor[] { act("z0", 150, "idle", 0), act("z1", 126, "idle", 0), act("giant", 320, "w0", 1), act("wcs", 446, "laugh", 0), act("roll", 280, "", 0) }, "wc", "c_t6", "laugh", false),
    cutStep("arena", new CutActor[] { act("z0", 150, "bite", 0), act("z1", 126, "idle", 0), act("giant", 320, "w0", 1), act("wcs", 446, "open", 0), act("roll", 280, "", 0) }, "z2", "c_t7")
  });

  CUTS.put("ending", new CutStep[] {
    cutStep("arena_dawn", new CutActor[] { act("z0", 90, "idle", 0), act("z1", 66, "idle", 0), act("giant", 250, "lie", 0) }, "n", "c_e1", "thud", true),
    cutStep("arena_dawn", new CutActor[] { act("z0", 90, "idle", 0), act("z1", 66, "idle", 0), act("giant", 250, "lie", 0), act("beam", 202, "", 0) }, "n", "c_e2", "shine", false),
    cutStep("arena_dawn", new CutActor[] { act("z0", 90, "idle", 0), act("z1", 66, "idle", 0), act("giant", 250, "dust", 0), act("beam", 250, "", 0) }, "n", "c_e3", "crumble", false),
    cutStep("arena_dawn", new CutActor[] { act("z0", 150, "bite", 0), act("z1", 126, "idle", 0), act("roll", 172, "", 0), act("giant", 250, "dust", 0) }, "z2", "c_e4"),
    cutStep("museum2", new CutActor[] { act("z0", 200, "idle", 0), act("z1", 280, "idle", 1), act("roll", 240, "", 0) }, "n", "c_e5", "win", false),
    cutStep("museum", new CutActor[] {}, "n", "c_e6"),
    cutStep("bath", new CutActor[] { act("wc", 380, "plaster", 0) }, "wc", "c_e7", "laugh", false)
  });

  for (String id : CUTS.keySet()) {
    for (CutStep st : CUTS.get(id)) {
      st.len = st.k != null ? Math.max(nl.get(st.k).length(), en.get(st.k).length()) : 0;
    }
  }
}

String tr(String lang, String key) {
  HashMap<String, String> m = TEXT.get(lang);
  if (m == null) m = TEXT.get("nl");
  return m != null ? m.get(key) : null;
}
